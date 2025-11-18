package smartinboxworker

import (
	"context"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/smartinbox"
)

func TestGeneratorGenerate(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	store := smartinbox.NewStore(db)
	gen := Generator{
		DB:          db,
		Store:       store,
		Logger:      zerolog.Nop(),
		SnapshotTTL: time.Minute,
		Limit:       2,
	}

	mock.ExpectQuery(`SELECT e\.id`).
		WithArgs(2).
		WillReturnRows(sqlmock.NewRows([]string{"id", "title", "author_id", "summary", "keywords", "created_at"}).
			AddRow("ep-1", "One", "author-1", "Summary", "{ai}", time.Now()).
			AddRow("ep-2", "Two", "author-2", "More", "{founders}", time.Now().Add(-time.Hour)))

	mock.ExpectExec(`INSERT INTO smart_inbox_snapshots`).
		WithArgs(sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), 2).
		WillReturnResult(sqlmock.NewResult(1, 1))

	mock.ExpectExec(`DELETE FROM smart_inbox_snapshots`).
		WithArgs(sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(0, 1))

	if err := gen.Generate(context.Background()); err != nil {
		t.Fatalf("generate: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}
