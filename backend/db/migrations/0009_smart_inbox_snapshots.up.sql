CREATE TABLE smart_inbox_snapshots (
    id BIGSERIAL PRIMARY KEY,
    payload JSONB NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ NOT NULL,
    source_count INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_smart_inbox_snapshots_valid
    ON smart_inbox_snapshots (valid_until DESC, generated_at DESC);
