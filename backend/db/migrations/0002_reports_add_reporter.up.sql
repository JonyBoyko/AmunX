ALTER TABLE reports
    ADD COLUMN reporter_id UUID REFERENCES users(id);

CREATE INDEX IF NOT EXISTS reports_status_created_idx
    ON reports(status, created_at DESC);
