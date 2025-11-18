package smartinbox

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestStoreLoadLatest(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	store := NewStore(db)
	now := time.Now()
	payload, _ := json.Marshal(Response{
		Digests: []Digest{{Date: "2024-01-01"}},
	})

	mock.ExpectQuery(`SELECT id, payload, generated_at, valid_until, source_count`).
		WithArgs(now).
		WillReturnRows(sqlmock.NewRows([]string{"id", "payload", "generated_at", "valid_until", "source_count"}).
			AddRow(10, payload, now.Add(-time.Minute), now.Add(time.Minute), 5))

	snapshot, err := store.LoadLatest(context.Background(), now)
	if err != nil {
		t.Fatalf("load latest: %v", err)
	}
	if snapshot.ID != 10 || snapshot.SourceCount != 5 {
		t.Fatalf("unexpected snapshot %+v", snapshot)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}

func TestStoreLoadLatestNone(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	store := NewStore(db)
	now := time.Now()

	mock.ExpectQuery(`SELECT id, payload, generated_at, valid_until, source_count`).
		WithArgs(now).
		WillReturnError(sql.ErrNoRows)

	_, err = store.LoadLatest(context.Background(), now)
	if !errors.Is(err, ErrNoSnapshot) {
		t.Fatalf("expected ErrNoSnapshot, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}

func TestStoreSave(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	store := NewStore(db)
	now := time.Now()
	resp := Response{GeneratedAt: now.Format(time.RFC3339)}

	mock.ExpectExec(`INSERT INTO smart_inbox_snapshots`).
		WithArgs(sqlmock.AnyArg(), now, sqlmock.AnyArg(), 2).
		WillReturnResult(sqlmock.NewResult(1, 1))

	if err := store.Save(context.Background(), resp, now, time.Minute, 2); err != nil {
		t.Fatalf("save: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}

func TestStorePrune(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	store := NewStore(db)
	before := time.Now().Add(-24 * time.Hour)

	mock.ExpectExec(`DELETE FROM smart_inbox_snapshots`).
		WithArgs(before).
		WillReturnResult(sqlmock.NewResult(0, 1))

	if err := store.Prune(context.Background(), before); err != nil {
		t.Fatalf("prune: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations: %v", err)
	}
}
