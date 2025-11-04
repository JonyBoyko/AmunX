ALTER TABLE live_sessions
    ADD COLUMN title TEXT,
    ADD COLUMN recording_key TEXT,
    ADD COLUMN duration_sec INT;

ALTER TABLE episodes
    ADD COLUMN live_session_id UUID REFERENCES live_sessions(id);

CREATE UNIQUE INDEX IF NOT EXISTS episodes_live_session_unique
    ON episodes(live_session_id)
    WHERE live_session_id IS NOT NULL;
