package http

import (
	"context"
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
)

func TestFollowUserPreventsSelf(t *testing.T) {
	id := uuid.New()
	if err := followUser(context.Background(), nil, id, id); err != errFollowSelf {
		t.Fatalf("expected errFollowSelf, got %v", err)
	}
}

func TestListUserProfiles(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock setup failed: %v", err)
	}
	defer db.Close()

	authors := []uuid.UUID{uuid.New(), uuid.New()}
	follower := uuid.New()

	rows := sqlmock.NewRows([]string{"id", "display_name", "handle", "bio", "avatar", "followers", "following"}).
		AddRow(authors[0], "Alice", "@alice", "bio", "🌀", 10, 2).
		AddRow(authors[1], "Bob", "@bob", nil, nil, 4, 1)

	mock.ExpectQuery(regexp.QuoteMeta(`
SELECT u.id,
       COALESCE(NULLIF(u.display_name, ''), split_part(u.email, '@', 1)) AS display_name,
	   COALESCE(NULLIF(u.handle, ''), '@moweton') AS handle,
	   p.bio,
	   COALESCE(NULLIF(p.avatar_url, ''), NULLIF(u.avatar, '')) AS avatar,
	   (SELECT COUNT(*) FROM user_follows WHERE followee_id = u.id) AS followers,
	   (SELECT COUNT(*) FROM user_follows WHERE follower_id = u.id) AS following
FROM users u
LEFT JOIN profiles p ON p.user_id = u.id
WHERE u.id = ANY($1)
`)).WithArgs(sqlmock.AnyArg()).WillReturnRows(rows)

	followRows := sqlmock.NewRows([]string{"followee_id"}).
		AddRow(authors[1])
	mock.ExpectQuery(`SELECT followee_id FROM user_follows`).WithArgs(follower, sqlmock.AnyArg()).WillReturnRows(followRows)

	profiles, err := listUserProfiles(context.Background(), db, authors, &follower)
	if err != nil {
		t.Fatalf("listUserProfiles: %v", err)
	}
	if len(profiles) != 2 {
		t.Fatalf("expected 2 profiles, got %d", len(profiles))
	}
	if profiles[0].ID != authors[0].String() {
		t.Fatalf("profiles not ordered, got %+v", profiles)
	}
	if profiles[0].IsFollowing {
		t.Fatalf("author 0 should not be following")
	}
	if !profiles[1].IsFollowing {
		t.Fatalf("author 1 should be following")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}
