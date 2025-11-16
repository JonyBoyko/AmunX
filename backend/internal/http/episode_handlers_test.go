package http

import (
	"context"
	"database/sql"
	"errors"
	"regexp"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/httpctx"
)

func TestUndoEpisodeWithinWindow(t *testing.T) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	episodeID := uuid.New()
	authorID := uuid.New()
	stmt := `
UPDATE episodes
SET status = 'deleted',
    status_changed_at = now(),
    updated_at = now()
WHERE id = $1
  AND author_id = $3
  AND status = 'pending_public'
  AND now() - status_changed_at <= ($2::int || ' seconds')::interval
RETURNING id;
`
	mock.ExpectQuery(regexp.QuoteMeta(stmt)).WithArgs(episodeID, 10, authorID).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(episodeID))

	ok, err := undoEpisode(context.Background(), db, episodeID, authorID, 10)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !ok {
		t.Fatalf("expected undo to succeed")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations were not met: %v", err)
	}
}

func TestUndoEpisodeExpiredWindow(t *testing.T) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	episodeID := uuid.New()
	authorID := uuid.New()
	stmt := `
UPDATE episodes
SET status = 'deleted',
    status_changed_at = now(),
    updated_at = now()
WHERE id = $1
  AND author_id = $3
  AND status = 'pending_public'
  AND now() - status_changed_at <= ($2::int || ' seconds')::interval
RETURNING id;
`
	mock.ExpectQuery(regexp.QuoteMeta(stmt)).WithArgs(episodeID, 10, authorID).
		WillReturnError(sql.ErrNoRows)

	ok, err := undoEpisode(context.Background(), db, episodeID, authorID, 10)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ok {
		t.Fatalf("expected undo to fail due to window expiry")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations were not met: %v", err)
	}
}

func TestSetEpisodeStatus(t *testing.T) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	episodeID := uuid.New()
	authorID := uuid.New()
	stmt := `
UPDATE episodes
SET status = $2,
    status_changed_at = now(),
    updated_at = now(),
    published_at = CASE WHEN $2 = 'public' THEN now() ELSE published_at END
WHERE id = $1
  AND author_id = $3
RETURNING id;
`
	mock.ExpectQuery(regexp.QuoteMeta(stmt)).WithArgs(episodeID, "pending_public", authorID).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(episodeID))

	if err := setEpisodeStatus(context.Background(), db, episodeID, authorID, "pending_public"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations were not met: %v", err)
	}
}

func TestApplyFeedFiltersFormat(t *testing.T) {
	shortDur := 60
	longDur := 360
	episodes := []episodeSummary{
		{ID: "short", AuthorID: uuid.New().String(), DurationSec: &shortDur},
		{ID: "long", AuthorID: uuid.New().String(), DurationSec: &longDur},
	}

	filters := feedFilterParams{
		Format: "podcasts",
		Region: "global",
		Tags:   map[string]struct{}{},
		Tab:    "all",
	}

	result := applyFeedFilters(episodes, filters)
	if len(result) != 1 || result[0].ID != "long" {
		t.Fatalf("expected only long episode, got %#v", result)
	}
}

func TestApplyFeedFiltersTags(t *testing.T) {
	episodes := []episodeSummary{
		{
			ID:        "ai",
			AuthorID:  uuid.New().String(),
			Keywords:  []string{"#AI"},
			CreatedAt: time.Now(),
		},
		{
			ID:        "wellness",
			AuthorID:  uuid.New().String(),
			Keywords:  []string{"#Wellness"},
			CreatedAt: time.Now(),
		},
	}

	filters := feedFilterParams{
		Region: "global",
		Tags: map[string]struct{}{
			"#ai": {},
		},
		Tab: "all",
	}

	result := applyFeedFilters(episodes, filters)
	if len(result) != 1 || result[0].ID != "ai" {
		t.Fatalf("expected AI episode only, got %#v", result)
	}
}

func TestApplyFeedFiltersRecommendedSort(t *testing.T) {
	shortDur := 45
	longDur := 200
	episodes := []episodeSummary{
		{
			ID:          "short",
			AuthorID:    uuid.New().String(),
			DurationSec: &shortDur,
			Keywords:    []string{"#ai"},
		},
		{
			ID:          "long",
			AuthorID:    uuid.New().String(),
			DurationSec: &longDur,
			Keywords:    []string{"#ai", "#news"},
		},
	}

	filters := feedFilterParams{
		Region: "global",
		Tab:    "recommended",
		Tags:   map[string]struct{}{},
	}

	result := applyFeedFilters(episodes, filters)
	if len(result) == 0 || result[0].ID != "long" {
		t.Fatalf("expected long episode to rank first, got %#v", result)
	}
}

func TestRequiresPodcastQuota(t *testing.T) {
	var (
		short = 60
		long  = 300
	)
	if requiresPodcastQuota(&short) {
		t.Fatalf("short duration should not require quota")
	}
	if !requiresPodcastQuota(&long) {
		t.Fatalf("long duration should require quota")
	}
	if requiresPodcastQuota(nil) {
		t.Fatalf("nil duration should not require quota")
	}
}

func TestEnforcePodcastQuotaFreeExceeded(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock setup failed: %v", err)
	}
	defer db.Close()

	user := httpctx.User{
		ID:   uuid.New(),
		Plan: "free",
	}

	mock.ExpectQuery(regexp.QuoteMeta(`
SELECT COUNT(*) FROM episodes
WHERE author_id = $1
  AND COALESCE(duration_sec, 0) >= $2
  AND created_at >= NOW() - INTERVAL '7 days'
  AND status != 'deleted'`)).
		WithArgs(user.ID, podcastDurationThreshold).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(freeWeeklyPodcastLimit))

	err = enforcePodcastQuota(context.Background(), db, user)
	if !errors.Is(err, errPodcastLimit) {
		t.Fatalf("expected podcast limit error, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("sql expectations not met: %v", err)
	}
}

func TestEnforcePodcastQuotaProAllowed(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock setup failed: %v", err)
	}
	defer db.Close()

	user := httpctx.User{
		ID:   uuid.New(),
		Plan: "pro",
	}

	mock.ExpectQuery(regexp.QuoteMeta(`
SELECT COUNT(*) FROM episodes
WHERE author_id = $1
  AND COALESCE(duration_sec, 0) >= $2
  AND created_at >= NOW() - INTERVAL '7 days'
  AND status != 'deleted'`)).
		WithArgs(user.ID, podcastDurationThreshold).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	if err := enforcePodcastQuota(context.Background(), db, user); err != nil {
		t.Fatalf("expected quota check to pass: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("sql expectations not met: %v", err)
	}
}

func TestIsStoryExpired(t *testing.T) {
	short := 60
	long := 400
	oldTime := time.Now().Add(-25 * time.Hour)
	recent := time.Now().Add(-2 * time.Hour)

	if !isStoryExpired("free", &short, oldTime) {
		t.Fatalf("expected free short audio older than TTL to expire")
	}
	if isStoryExpired("free", &short, recent) {
		t.Fatalf("recent short audio should remain")
	}
	if isStoryExpired("pro", &short, oldTime) {
		t.Fatalf("pro stories should not expire")
	}
	if isStoryExpired("free", &long, oldTime) {
		t.Fatalf("long format should not expire even for free")
	}
}
