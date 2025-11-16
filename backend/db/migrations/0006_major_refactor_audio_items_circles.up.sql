-- Major refactor: episodes → audio_items, add Smart Circles, Clips, Embeddings, Feed Events
-- This migration implements the new Moweton architecture from the specification

-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- STEP 1: Create new tables that don't depend on episodes
-- ============================================================================

-- Profiles (extend user data)
CREATE TABLE profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  avatar_url TEXT,
  bio TEXT,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Smart Circles (voice-only communities)
CREATE TABLE circles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_local BOOLEAN NOT NULL DEFAULT FALSE,
  city TEXT,
  country TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX circles_owner_idx ON circles(owner_id);
CREATE INDEX circles_city_idx ON circles(city) WHERE city IS NOT NULL;

-- Circle membership
CREATE TABLE circle_members (
  circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner','moderator','member')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (circle_id, user_id)
);
CREATE INDEX circle_members_user_idx ON circle_members(user_id);

-- Podcast shows (RSS export)
CREATE TABLE podcast_shows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  rss_slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX podcast_shows_owner_idx ON podcast_shows(owner_id);

-- ============================================================================
-- STEP 2: Create audio_items (unified episodes + micro posts)
-- ============================================================================

CREATE TYPE audio_item_kind AS ENUM('micro','podcast_episode');

CREATE TABLE audio_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  visibility TEXT NOT NULL CHECK (visibility IN ('private','circles','public')) DEFAULT 'private',
  title TEXT,
  description TEXT,
  kind TEXT NOT NULL CHECK (kind IN ('micro','podcast_episode')),
  duration_sec INT NOT NULL,
  s3_key TEXT NOT NULL,
  audio_url TEXT, -- optional CDN URL
  waveform JSONB, -- precomputed peaks for UI
  tags TEXT[] DEFAULT '{}',
  share_to_circle_ids UUID[] DEFAULT '{}',
  parent_audio_id UUID REFERENCES audio_items(id) ON DELETE CASCADE, -- for threaded replies in circles
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audio_items_owner_idx ON audio_items(owner_id, created_at DESC);
CREATE INDEX audio_items_visibility_idx ON audio_items(visibility, created_at DESC) WHERE visibility = 'public';
CREATE INDEX audio_items_kind_idx ON audio_items(kind, created_at DESC);
CREATE INDEX audio_items_tags_idx ON audio_items USING GIN(tags);
CREATE INDEX audio_items_parent_idx ON audio_items(parent_audio_id) WHERE parent_audio_id IS NOT NULL;

-- ============================================================================
-- STEP 3: Migrate existing episodes → audio_items
-- ============================================================================

INSERT INTO audio_items (
  id,
  owner_id,
  visibility,
  title,
  description,
  kind,
  duration_sec,
  s3_key,
  audio_url,
  waveform,
  tags,
  created_at,
  updated_at
)
SELECT 
  e.id,
  e.author_id,
  CASE 
    WHEN e.visibility::text = 'public' THEN 'public'
    WHEN e.visibility::text = 'private' THEN 'private'
    ELSE 'private'
  END,
  e.title,
  NULL, -- no description in old schema
  'podcast_episode', -- all existing episodes are podcast_episode
  COALESCE(e.duration_sec, 0),
  COALESCE(e.storage_key, ''), -- fallback to empty string if null
  e.audio_url,
  e.waveform_json,
  ARRAY[]::TEXT[], -- no tags in old schema
  e.created_at,
  e.updated_at
FROM episodes e;

-- ============================================================================
-- STEP 4: Create tables that depend on audio_items
-- ============================================================================

-- Transcripts (full text from Whisper)
CREATE TABLE transcripts (
  audio_id UUID PRIMARY KEY REFERENCES audio_items(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  lang TEXT,
  words JSONB, -- word-level timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX transcripts_text_idx ON transcripts USING GIN(to_tsvector('english', text));

-- Update summaries to reference audio_items and add new fields
ALTER TABLE summaries RENAME TO summaries_old;

CREATE TABLE summaries (
  audio_id UUID PRIMARY KEY REFERENCES audio_items(id) ON DELETE CASCADE,
  preview_sentence TEXT NOT NULL, -- ≤140 chars for Explore cards
  tldr TEXT,
  chapters JSONB, -- [{start:sec,end:sec,title}]
  keywords TEXT[],
  mood JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Migrate old summaries
INSERT INTO summaries (audio_id, preview_sentence, tldr, chapters, keywords, mood, created_at)
SELECT 
  episode_id,
  COALESCE(SUBSTRING(tldr, 1, 140), 'No summary available'), -- use tldr as preview
  tldr,
  chapters,
  keywords,
  mood,
  now()
FROM summaries_old;

DROP TABLE summaries_old;

-- Clips (smart clips for Explore)
CREATE TABLE clips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audio_id UUID NOT NULL REFERENCES audio_items(id) ON DELETE CASCADE,
  start_sec INT NOT NULL,
  end_sec INT NOT NULL,
  title TEXT,
  quote TEXT, -- quoted line from transcript
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX clips_audio_idx ON clips(audio_id);
CREATE INDEX clips_created_idx ON clips(created_at DESC);

-- Embeddings (for vector search)
CREATE TABLE embeddings (
  id BIGSERIAL PRIMARY KEY,
  audio_id UUID NOT NULL REFERENCES audio_items(id) ON DELETE CASCADE,
  chunk_index INT NOT NULL,
  vector VECTOR(1536) NOT NULL,
  text_chunk TEXT NOT NULL
);
CREATE INDEX embeddings_audio_idx ON embeddings(audio_id);
-- IVFFlat index for fast ANN search (will be created after data is populated)
-- CREATE INDEX embeddings_vector_idx ON embeddings USING ivfflat (vector vector_cosine_ops) WITH (lists = 100);

-- Likes (replace/extend reactions)
CREATE TABLE likes (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  audio_id UUID REFERENCES audio_items(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, audio_id)
);

-- Migrate reactions to likes (assuming 'like' type exists)
INSERT INTO likes (user_id, audio_id, created_at)
SELECT user_id, episode_id, created_at
FROM reactions
WHERE type = 'like'
ON CONFLICT DO NOTHING;

-- Saves (bookmarks)
CREATE TABLE saves (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  audio_id UUID REFERENCES audio_items(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, audio_id)
);

-- Update follows to use user-to-user (in addition to topic follows)
-- Keep existing follows table for topics, add new one for users
CREATE TABLE user_follows (
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  followee_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id != followee_id)
);
CREATE INDEX user_follows_follower_idx ON user_follows(follower_id);
CREATE INDEX user_follows_followee_idx ON user_follows(followee_id);

-- Feed events (engagement signals for ranking)
CREATE TABLE feed_events (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  audio_id UUID REFERENCES audio_items(id) ON DELETE CASCADE,
  event TEXT NOT NULL CHECK (event IN ('impression','preview_finished','play','complete','save','share','quote','follow_author')),
  meta JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX feed_events_audio_idx ON feed_events(audio_id, event);
CREATE INDEX feed_events_user_idx ON feed_events(user_id);
CREATE INDEX feed_events_created_idx ON feed_events(created_at DESC);

-- Podcast show episodes (links audio_items to shows)
CREATE TABLE podcast_show_episodes (
  show_id UUID REFERENCES podcast_shows(id) ON DELETE CASCADE,
  audio_id UUID REFERENCES audio_items(id) ON DELETE CASCADE,
  published_at TIMESTAMPTZ,
  PRIMARY KEY (show_id, audio_id)
);
CREATE INDEX podcast_show_episodes_show_idx ON podcast_show_episodes(show_id, published_at DESC);

-- ============================================================================
-- STEP 5: Update comments to reference audio_items
-- ============================================================================

ALTER TABLE comments RENAME COLUMN episode_id TO audio_id;
ALTER TABLE comments DROP CONSTRAINT comments_episode_id_fkey;
ALTER TABLE comments ADD CONSTRAINT comments_audio_id_fkey FOREIGN KEY (audio_id) REFERENCES audio_items(id) ON DELETE CASCADE;

-- ============================================================================
-- STEP 6: Keep reactions but update to audio_items
-- ============================================================================

ALTER TABLE reactions RENAME COLUMN episode_id TO audio_id;
ALTER TABLE reactions DROP CONSTRAINT reactions_episode_id_fkey;
ALTER TABLE reactions ADD CONSTRAINT reactions_audio_id_fkey FOREIGN KEY (audio_id) REFERENCES audio_items(id) ON DELETE CASCADE;

-- ============================================================================
-- STEP 7: Drop old episodes table (data already migrated)
-- ============================================================================

-- First drop constraints referencing episodes
DROP INDEX IF EXISTS episodes_topic_published_idx;
DROP INDEX IF EXISTS episodes_author_published_idx;

-- Keep topics for now (they're still useful for categorization)
-- But episodes table can be dropped
DROP TABLE episodes CASCADE;

-- ============================================================================
-- STEP 8: Add indexes for performance
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX audio_items_owner_visibility_idx ON audio_items(owner_id, visibility, created_at DESC);
CREATE INDEX feed_events_audio_event_created_idx ON feed_events(audio_id, event, created_at DESC);

-- GIN index for array contains queries on share_to_circle_ids
CREATE INDEX audio_items_share_circles_idx ON audio_items USING GIN(share_to_circle_ids);

-- ============================================================================
-- DONE
-- ============================================================================

-- Summary of changes:
-- ✅ episodes → audio_items (unified model for micro + podcast)
-- ✅ Added profiles
-- ✅ Added circles + circle_members (Smart Circles)
-- ✅ Added clips (smart clips for Explore)
-- ✅ Added transcripts
-- ✅ Updated summaries with preview_sentence
-- ✅ Added embeddings with pgvector
-- ✅ Added likes, saves
-- ✅ Added user_follows
-- ✅ Added feed_events (engagement tracking)
-- ✅ Added podcast_shows + podcast_show_episodes
-- ✅ Migrated existing data
-- ✅ Updated comments and reactions to reference audio_items
-- ✅ Added all necessary indexes

