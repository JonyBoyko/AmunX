package http

import (
	"context"
	"database/sql"
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
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

