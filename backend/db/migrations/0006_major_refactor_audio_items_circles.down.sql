-- Rollback major refactor
-- WARNING: This will lose data for new features (circles, clips, embeddings, etc.)

-- Drop new tables (in reverse order of creation)
DROP TABLE IF EXISTS podcast_show_episodes CASCADE;
DROP TABLE IF EXISTS feed_events CASCADE;
DROP TABLE IF EXISTS user_follows CASCADE;
DROP TABLE IF EXISTS saves CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS embeddings CASCADE;
DROP TABLE IF EXISTS clips CASCADE;
DROP TABLE IF EXISTS transcripts CASCADE;
DROP TABLE IF EXISTS summaries CASCADE;
DROP TABLE IF EXISTS circle_members CASCADE;
DROP TABLE IF EXISTS podcast_shows CASCADE;
DROP TABLE IF EXISTS circles CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Recreate episodes table with original schema
CREATE TYPE visibility AS ENUM('public','private','anon');
CREATE TYPE episode_status AS ENUM('pending_upload','pending_public','public','private','deleted');
CREATE TYPE episode_mask AS ENUM('none','basic','studio');
CREATE TYPE episode_quality AS ENUM('raw','clean','studio');

CREATE TABLE episodes(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES users(id),
  topic_id UUID REFERENCES topics(id),
  visibility visibility NOT NULL DEFAULT 'public',
  status episode_status NOT NULL DEFAULT 'pending_upload',
  title TEXT,
  duration_sec INT,
  storage_key TEXT,
  audio_url TEXT,
  size_bytes BIGINT,
  waveform_json JSONB,
  quality episode_quality NOT NULL DEFAULT 'clean',
  mask episode_mask NOT NULL DEFAULT 'none',
  is_live BOOLEAN DEFAULT FALSE,
  published_at TIMESTAMPTZ,
  status_changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Migrate audio_items back to episodes (best effort)
INSERT INTO episodes (
  id,
  author_id,
  visibility,
  title,
  duration_sec,
  storage_key,
  audio_url,
  waveform_json,
  created_at,
  updated_at
)
SELECT 
  id,
  owner_id,
  CASE visibility
    WHEN 'public' THEN 'public'::visibility
    WHEN 'private' THEN 'private'::visibility
    ELSE 'private'::visibility
  END,
  title,
  duration_sec,
  s3_key,
  audio_url,
  waveform,
  created_at,
  updated_at
FROM audio_items
WHERE kind = 'podcast_episode';

-- Recreate old summaries table
CREATE TABLE summaries_old(
  episode_id UUID PRIMARY KEY REFERENCES episodes(id),
  tldr TEXT,
  keywords TEXT[],
  mood JSONB,
  chapters JSONB
);

-- Update comments back to episode_id
ALTER TABLE comments RENAME COLUMN audio_id TO episode_id;
ALTER TABLE comments DROP CONSTRAINT comments_audio_id_fkey;
ALTER TABLE comments ADD CONSTRAINT comments_episode_id_fkey FOREIGN KEY (episode_id) REFERENCES episodes(id);

-- Update reactions back to episode_id
ALTER TABLE reactions RENAME COLUMN audio_id TO episode_id;
ALTER TABLE reactions DROP CONSTRAINT reactions_audio_id_fkey;
ALTER TABLE reactions ADD CONSTRAINT reactions_episode_id_fkey FOREIGN KEY (episode_id) REFERENCES episodes(id);

-- Recreate indexes
CREATE INDEX episodes_topic_published_idx ON episodes(topic_id, published_at DESC);
CREATE INDEX episodes_author_published_idx ON episodes(author_id, published_at DESC);
CREATE INDEX comments_episode_created_idx ON comments(episode_id, created_at);

-- Drop audio_items
DROP TABLE IF EXISTS audio_items CASCADE;

-- Drop audio_item_kind enum
DROP TYPE IF EXISTS audio_item_kind CASCADE;

-- Drop pgvector extension if not used elsewhere
DROP EXTENSION IF EXISTS vector;

