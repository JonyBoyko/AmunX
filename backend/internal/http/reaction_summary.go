package http

import (
	"context"
	"database/sql"
	"sort"
	"strings"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type reactionCount struct {
	Type  string `json:"type"`
	Count int    `json:"count"`
}

type reactionBadge struct {
	Type  string `json:"type"`
	Label string `json:"label"`
	Emoji string `json:"emoji"`
	Level int    `json:"level"`
}

type reactionDefinition struct {
	Emoji       string
	SortOrder   int
	BadgeLabels [3]string
}

var reactionCatalog = map[string]reactionDefinition{
	"like": {
		Emoji:     "👍",
		SortOrder: 0,
		BadgeLabels: [3]string{
			"Улюблене спільноти",
			"Фан-фаворит",
			"Легенда тижня",
		},
	},
	"fire": {
		Emoji:     "🔥",
		SortOrder: 1,
		BadgeLabels: [3]string{
			"Розігрівається",
			"На вогні",
			"Справжнє полум'я",
		},
	},
	"idea": {
		Emoji:     "💡",
		SortOrder: 2,
		BadgeLabels: [3]string{
			"Ідея дня",
			"Прозріння тижня",
			"Геніальний інсайт",
		},
	},
	"heart": {
		Emoji:     "❤️",
		SortOrder: 3,
		BadgeLabels: [3]string{
			"Щиро підтримано",
			"Насправді люблять",
			"Серце спільноти",
		},
	},
	"clap": {
		Emoji:     "👏",
		SortOrder: 4,
		BadgeLabels: [3]string{
			"Оплески",
			"Стендінг овація",
			"Тріумф дня",
		},
	},
}

var reactionAliases = map[string]string{
	"thumbs_up": "like",
	"thumbsup":  "like",
	"plus_one":  "like",
	"fire":      "fire",
	"lit":       "fire",
	"idea":      "idea",
	"light":     "idea",
	"lightbulb": "idea",
	"heart":     "heart",
	"love":      "heart",
	"clap":      "clap",
	"clapping":  "clap",
}

func appendReactionMetadata(ctx context.Context, db *sql.DB, episodes []episodeSummary) error {
	if len(episodes) == 0 {
		return nil
	}

	ids := collectEpisodeUUIDs(episodes)
	if len(ids) == 0 {
		return nil
	}

	counts, err := fetchReactionCounts(ctx, db, ids)
	if err != nil {
		return err
	}

	for i := range episodes {
		if totals, ok := counts[episodes[i].ID]; ok {
			episodes[i].Reactions = totals
			episodes[i].ReactionBadge = deriveReactionBadge(totals)
		} else {
			episodes[i].Reactions = nil
			episodes[i].ReactionBadge = nil
		}
	}
	return nil
}

func appendSelfReactions(ctx context.Context, db *sql.DB, userID uuid.UUID, episodes []episodeSummary) error {
	if len(episodes) == 0 {
		return nil
	}

	ids := collectEpisodeUUIDs(episodes)
	if len(ids) == 0 {
		return nil
	}

	rows, err := db.QueryContext(ctx, `
SELECT audio_id, type
FROM reactions
WHERE audio_id = ANY($1) AND user_id = $2
`, pq.Array(ids), userID)
	if err != nil {
		return err
	}
	defer rows.Close()

	perEpisode := make(map[string][]string)
	for rows.Next() {
		var (
			episodeID uuid.UUID
			t         string
		)
		if err := rows.Scan(&episodeID, &t); err != nil {
			return err
		}
		if canonical := canonicalReactionType(t); canonical != "" {
			perEpisode[episodeID.String()] = append(perEpisode[episodeID.String()], canonical)
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}

	for i := range episodes {
		if reactions, ok := perEpisode[episodes[i].ID]; ok {
			episodes[i].SelfReactions = reactions
		} else {
			episodes[i].SelfReactions = nil
		}
	}
	return nil
}

func fetchReactionCounts(ctx context.Context, db *sql.DB, ids []uuid.UUID) (map[string][]reactionCount, error) {
	rows, err := db.QueryContext(ctx, `
SELECT audio_id, type, COUNT(*)
FROM reactions
WHERE audio_id = ANY($1)
GROUP BY audio_id, type
`, pq.Array(ids))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make(map[string][]reactionCount)
	for rows.Next() {
		var (
			episodeID uuid.UUID
			rt        string
			count     int
		)
		if err := rows.Scan(&episodeID, &rt, &count); err != nil {
			return nil, err
		}
		canonical := canonicalReactionType(rt)
		if canonical == "" {
			continue
		}
		result[episodeID.String()] = append(result[episodeID.String()], reactionCount{
			Type:  canonical,
			Count: count,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	for episodeID, totals := range result {
		sort.Slice(totals, func(i, j int) bool {
			if totals[i].Count == totals[j].Count {
				return reactionCatalog[totals[i].Type].SortOrder < reactionCatalog[totals[j].Type].SortOrder
			}
			return totals[i].Count > totals[j].Count
		})
		result[episodeID] = totals
	}
	return result, nil
}

func loadReactionSnapshot(ctx context.Context, db *sql.DB, episodeID uuid.UUID) ([]reactionCount, *reactionBadge, error) {
	counts, err := fetchReactionCounts(ctx, db, []uuid.UUID{episodeID})
	if err != nil {
		return nil, nil, err
	}
	totals := counts[episodeID.String()]
	return totals, deriveReactionBadge(totals), nil
}

func deriveReactionBadge(totals []reactionCount) *reactionBadge {
	if len(totals) == 0 {
		return nil
	}
	top := totals[0]
	level := badgeLevel(top.Count)
	if level == 0 {
		return nil
	}
	def := reactionCatalog[top.Type]
	return &reactionBadge{
		Type:  top.Type,
		Label: def.BadgeLabels[level-1],
		Emoji: def.Emoji,
		Level: level,
	}
}

func badgeLevel(count int) int {
	switch {
	case count >= 60:
		return 3
	case count >= 30:
		return 2
	case count >= 12:
		return 1
	default:
		return 0
	}
}

func canonicalReactionType(value string) string {
	key := strings.TrimSpace(strings.ToLower(value))
	if key == "" {
		return ""
	}
	if canonical, ok := reactionAliases[key]; ok {
		return canonical
	}
	if _, ok := reactionCatalog[key]; ok {
		return key
	}
	return ""
}

func collectEpisodeUUIDs(episodes []episodeSummary) []uuid.UUID {
	ids := make([]uuid.UUID, 0, len(episodes))
	for _, episode := range episodes {
		id, err := uuid.Parse(episode.ID)
		if err != nil {
			continue
		}
		ids = append(ids, id)
	}
	return ids
}
