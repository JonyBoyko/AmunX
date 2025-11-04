DROP INDEX IF EXISTS reports_status_created_idx;
ALTER TABLE reports
    DROP COLUMN IF EXISTS reporter_id;
