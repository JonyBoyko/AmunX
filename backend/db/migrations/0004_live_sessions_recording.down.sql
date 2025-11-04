DROP INDEX IF EXISTS episodes_live_session_unique;

ALTER TABLE episodes
    DROP COLUMN IF EXISTS live_session_id;

ALTER TABLE live_sessions
    DROP COLUMN IF EXISTS duration_sec;

ALTER TABLE live_sessions
    DROP COLUMN IF EXISTS recording_key;

ALTER TABLE live_sessions
    DROP COLUMN IF EXISTS title;
