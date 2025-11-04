CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  handle TEXT UNIQUE,
  email TEXT UNIQUE,
  display_name TEXT,
  avatar TEXT,
  is_anon BOOLEAN DEFAULT FALSE,
  plan TEXT DEFAULT 'free',
  settings_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE topics(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES users(id),
  is_public BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE follows(
  user_id UUID REFERENCES users(id),
  topic_id UUID REFERENCES topics(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, topic_id)
);

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
CREATE INDEX episodes_topic_published_idx ON episodes(topic_id, published_at DESC);
CREATE INDEX episodes_author_published_idx ON episodes(author_id, published_at DESC);

CREATE TABLE summaries(
  episode_id UUID PRIMARY KEY REFERENCES episodes(id),
  tldr TEXT,
  keywords TEXT[],
  mood JSONB,
  chapters JSONB
);

CREATE TABLE comments(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_id UUID REFERENCES episodes(id),
  author_id UUID REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX comments_episode_created_idx ON comments(episode_id, created_at);

CREATE TABLE reactions(
  episode_id UUID REFERENCES episodes(id),
  user_id UUID REFERENCES users(id),
  type TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (episode_id, user_id, type)
);

CREATE TABLE live_sessions(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID REFERENCES users(id),
  topic_id UUID REFERENCES topics(id),
  sfu_room TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ
);

CREATE TABLE moderation_flags(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  object_ref TEXT NOT NULL,
  severity INT,
  reason TEXT,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE reports(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  object_ref TEXT NOT NULL,
  reason TEXT,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT now()
);
