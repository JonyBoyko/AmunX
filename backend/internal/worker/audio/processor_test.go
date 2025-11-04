package audio

import (
	"context"
	"io"
	"regexp"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/queue"
)

type stubStream struct {
	lastStream  string
	lastPayload map[string]any
}

func (s *stubStream) Enqueue(_ context.Context, stream string, payload map[string]any) error {
	s.lastStream = stream
	s.lastPayload = payload
	return nil
}

func (s *stubStream) Claim(_ context.Context, _ string, _ string, _ string, _ int64) ([]queue.Message, error) {
	return nil, nil
}

func (s *stubStream) Ack(_ context.Context, _ string, _ string, _ ...string) error {
	return nil
}

func testLogger() zerolog.Logger {
	return zerolog.New(io.Discard)
}

func TestHandleFinalizeLiveCreatesEpisodeWithMask(t *testing.T) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	queueStub := &stubStream{}
	logger := testLogger()

	p := &Processor{
		DB:      db,
		Queue:   queueStub,
		Logger:  logger,
		Storage: nil,
	}

	sessionID := uuid.New()
	hostID := uuid.New()

	selectSession := `
SELECT ls.host_id, ls.topic_id, ls.recording_key, ls.duration_sec, ls.ended_at, ls.title, ls.mask, e.id
FROM live_sessions ls
LEFT JOIN episodes e ON e.live_session_id = ls.id
WHERE ls.id = $1;
`
	endedAt := time.Now().UTC()
	mock.ExpectQuery(regexp.QuoteMeta(selectSession)).
		WithArgs(sessionID).
		WillReturnRows(sqlmock.NewRows([]string{
			"host_id",
			"topic_id",
			"recording_key",
			"duration_sec",
			"ended_at",
			"title",
			"mask",
			"id",
		}).AddRow(
			hostID,
			nil,
			"original/live/source.opus",
			int64(240),
			endedAt,
			"Afterparty",
			"basic",
			nil,
		))

	updateMeta := `
UPDATE live_sessions
SET recording_key = COALESCE(NULLIF($2, ''), recording_key),
    duration_sec = COALESCE($3, duration_sec)
WHERE id = $1;
`
	mock.ExpectExec(regexp.QuoteMeta(updateMeta)).
		WithArgs(sessionID, "recordings/live.opus", 240).
		WillReturnResult(sqlmock.NewResult(0, 1))

	insertEpisode := `
INSERT INTO episodes (id, author_id, topic_id, visibility, status, title, duration_sec, storage_key, mask, is_live, live_session_id)
VALUES ($1, $2, $3, 'public', 'pending_public', $4, $5, $6, $7, true, $8);
`
	mock.ExpectExec(regexp.QuoteMeta(insertEpisode)).
		WithArgs(sqlmock.AnyArg(), hostID, nil, "Afterparty", 240, "recordings/live.opus", "basic", sessionID).
		WillReturnResult(sqlmock.NewResult(0, 1))

	duration := 240
	if err := p.handleFinalizeLive(context.Background(), sessionID, "recordings/live.opus", &duration); err != nil {
		t.Fatalf("handleFinalizeLive: %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("sql expectations: %v", err)
	}

	if queueStub.lastStream != queue.TopicProcessAudio {
		t.Fatalf("expected queue stream %q, got %q", queue.TopicProcessAudio, queueStub.lastStream)
	}
	if queueStub.lastPayload == nil {
		t.Fatal("expected payload to be enqueued")
	}
	if queueStub.lastPayload["episode_id"] == "" {
		t.Fatalf("expected episode_id in payload, got %#v", queueStub.lastPayload)
	}
	if attempt, ok := queueStub.lastPayload["attempt"].(int); !ok || attempt != 0 {
		t.Fatalf("expected attempt 0 in payload, got %#v", queueStub.lastPayload["attempt"])
	}
}

func TestHandleFinalizeLiveRequiresRecordingKey(t *testing.T) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	if err != nil {
		t.Fatalf("sqlmock: %v", err)
	}
	defer db.Close()

	p := &Processor{
		DB:     db,
		Queue:  &stubStream{},
		Logger: testLogger(),
	}

	sessionID := uuid.New()
	hostID := uuid.New()

	selectSession := `
SELECT ls.host_id, ls.topic_id, ls.recording_key, ls.duration_sec, ls.ended_at, ls.title, ls.mask, e.id
FROM live_sessions ls
LEFT JOIN episodes e ON e.live_session_id = ls.id
WHERE ls.id = $1;
`
	mock.ExpectQuery(regexp.QuoteMeta(selectSession)).
		WithArgs(sessionID).
		WillReturnRows(sqlmock.NewRows([]string{
			"host_id",
			"topic_id",
			"recording_key",
			"duration_sec",
			"ended_at",
			"title",
			"mask",
			"id",
		}).AddRow(
			hostID,
			nil,
			"",
			nil,
			time.Now().UTC(),
			"",
			"none",
			nil,
		))

	if err := p.handleFinalizeLive(context.Background(), sessionID, "", nil); err == nil {
		t.Fatal("expected error when recording key missing")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("sql expectations: %v", err)
	}
}
