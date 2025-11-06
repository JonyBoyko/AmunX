# Database Migrations Guide

This document describes the database schema, migrations, and how to manage them.

## Overview

AmunX uses PostgreSQL with the following extensions:
- `pgcrypto` - UUID generation
- `vector` - pgvector for embeddings (AI-powered search)

## Running Migrations

### Using Makefile (Recommended)

```bash
# Run all pending migrations
make migrate-up

# Rollback last migration
make migrate-down

# Create new migration
make migrate-create name=add_new_feature
```

### Manual (PowerShell)

```powershell
# Run all migrations
cd backend
go run cmd/migrate/main.go up

# Rollback
go run cmd/migrate/main.go down

# Create new migration
go run cmd/migrate/main.go create my_migration_name
```

## Schema Overview

### Core Tables

#### `users`
User accounts and authentication.
- Fields: `id`, `email`, `handle`, `display_name`, `avatar`, `is_anon`, `plan`, `settings_json`
- Auth: Magic link or OAuth (handled by external service)

#### `profiles`
Extended user profile data.
- Fields: `user_id`, `avatar_url`, `bio`, `settings`
- One-to-one with `users`

#### `audio_items`
**Unified audio content table** (replaces old `episodes`).
- **Types**: `micro` (30-120s) or `podcast_episode` (any length)
- **Visibility**: `private` (default), `circles` (shared to specific circles), `public` (appears in Explore)
- **Threading**: Can have `parent_audio_id` for voice replies in circles
- Fields: `id`, `owner_id`, `visibility`, `title`, `description`, `kind`, `duration_sec`, `s3_key`, `audio_url`, `waveform`, `tags`, `share_to_circle_ids`, `parent_audio_id`

### AI & Processing

#### `transcripts`
Full-text transcription from Whisper.
- Fields: `audio_id`, `text`, `lang`, `words` (word-level timestamps)
- Indexed with PostgreSQL full-text search (GIN index)

#### `summaries`
AI-generated summaries and chapters.
- Fields: `audio_id`, `preview_sentence` (≤140 chars for cards), `tldr`, `chapters` (array of `{start, end, title}`), `keywords`, `mood`

#### `clips`
Auto-generated smart clips for Explore feed.
- Fields: `id`, `audio_id`, `start_sec`, `end_sec`, `title`, `quote`
- Created by worker pipeline (silence detection + high-salience transcript spans)

#### `embeddings`
Vector embeddings for semantic search.
- Fields: `id`, `audio_id`, `chunk_index`, `vector` (VECTOR(1536)), `text_chunk`
- Uses pgvector extension for fast ANN search (cosine similarity)
- Index: IVFFlat (created after initial data population)

### Social Features

#### `likes`
User likes on audio items.
- Primary key: `(user_id, audio_id)`

#### `saves`
User bookmarks.
- Primary key: `(user_id, audio_id)`

#### `user_follows`
User-to-user follows.
- Primary key: `(follower_id, followee_id)`
- Note: Separate from `follows` table which is for topic follows

#### `comments`
Text comments on audio items.
- Fields: `id`, `audio_id`, `author_id`, `text`

#### `reactions`
Emoji reactions on audio items.
- Primary key: `(audio_id, user_id, type)`

### Smart Circles

#### `circles`
Voice-only communities for async voice threads.
- Fields: `id`, `owner_id`, `name`, `description`, `is_local`, `city`, `country`
- **Local circles**: Community-based (e.g., "Warsaw Voice Community")
- **Global circles**: Topic-based (e.g., "Startup Founders")

#### `circle_members`
Membership in circles.
- Fields: `circle_id`, `user_id`, `role` (`owner`, `moderator`, `member`)
- Primary key: `(circle_id, user_id)`

### Explore Feed & Ranking

#### `feed_events`
User engagement events for ranking algorithm.
- **Events**: `impression`, `preview_finished`, `play`, `complete`, `save`, `share`, `quote`, `follow_author`
- Fields: `id`, `user_id`, `audio_id`, `event`, `meta`, `created_at`
- Used for calculating engagement scores in Explore feed

### Podcasts (RSS Export)

#### `podcast_shows`
Podcast shows for RSS export.
- Fields: `id`, `owner_id`, `title`, `description`, `cover_url`, `rss_slug`
- Each show generates RSS feed at `/podcasts/rss/{slug}.xml`

#### `podcast_show_episodes`
Links audio items to podcast shows.
- Primary key: `(show_id, audio_id)`
- Fields: `published_at`

## Migration History

### 0001_init.up.sql
Initial schema:
- Users, topics, episodes (old model)
- Comments, reactions, follows
- Live sessions, moderation flags, reports

### 0002_reports_add_reporter.up.sql
Added reporter tracking to reports table.

### 0003_users_shadowban.up.sql
Added shadowban support for moderation.

### 0004_live_sessions_recording.up.sql
Added recording support for live sessions.

### 0005_live_sessions_mask.up.sql
Added voice mask support for live sessions.

### 0006_major_refactor_audio_items_circles.up.sql ⭐ **MAJOR REFACTOR**

**Breaking changes:**
- `episodes` → `audio_items` (unified model)
- Added Smart Circles feature
- Added AI pipeline tables (transcripts, summaries, clips, embeddings)
- Added privacy model (private by default)
- Added feed events for ranking
- Added podcast RSS export

**New tables:**
- `profiles`
- `audio_items` (replaces `episodes`)
- `circles`, `circle_members`
- `transcripts`, `summaries`, `clips`, `embeddings`
- `likes`, `saves`, `user_follows`
- `feed_events`
- `podcast_shows`, `podcast_show_episodes`

**Data migration:**
- Existing `episodes` → `audio_items` (all as `podcast_episode` type, visibility based on old visibility enum)
- Existing `summaries` → new summaries table (tldr → preview_sentence)
- Existing `reactions` with type='like' → `likes` table
- Comments and reactions updated to reference `audio_items`

**Indexes added:**
- Full-text search on transcripts
- GIN indexes on arrays (tags, share_to_circle_ids)
- Composite indexes for common queries
- Vector index preparation for embeddings (IVFFlat)

## Privacy Model

### Default Behavior
**All new audio is PRIVATE by default.** Users must explicitly choose to share.

### Visibility Options
1. **`private`** (default)
   - Only owner can see
   - Not in Explore
   - Not in any feeds

2. **`circles`**
   - Shared to specific circles (listed in `share_to_circle_ids`)
   - Visible in circle feeds
   - Not in public Explore

3. **`public`**
   - Visible in Explore feed
   - Can generate smart clips for Explore
   - Searchable

### Enforcement
Privacy is enforced at the database query level (via sqlc queries) and API permission checks.

## Working with sqlc

### Generate Go Code from Queries

```bash
make sqlc-generate
```

This reads:
- Schema: `backend/db/migrations/*.sql`
- Queries: `backend/db/queries/*.sql`
- Generates: `backend/internal/db/*.go` (type-safe Go functions)

### Query Files

- `users.sql` - User CRUD, profiles, follows
- `audio_items.sql` - Audio CRUD, likes, saves
- `circles.sql` - Circle CRUD, membership
- `transcripts.sql` - Transcript CRUD, search
- `summaries.sql` - Summary CRUD
- `clips.sql` - Clip CRUD
- `embeddings.sql` - Embedding CRUD (vector search done via raw SQL)
- `feed_events.sql` - Event recording, stats
- `podcasts.sql` - Podcast show CRUD, episodes

## Indexes

### Performance-Critical Indexes

1. **Full-text search**: `transcripts` (GIN on to_tsvector)
2. **Vector search**: `embeddings` (IVFFlat on vector column) - **Created after initial data load**
3. **Array search**: `audio_items` (GIN on tags, share_to_circle_ids)
4. **Sorting**: Composite indexes on `(owner_id, created_at)`, `(visibility, created_at)`
5. **Joins**: Foreign key columns (user_id, audio_id, circle_id)

### Creating Vector Index (After Data Load)

```sql
-- Only create after ~1000+ embeddings exist
CREATE INDEX embeddings_vector_idx 
ON embeddings 
USING ivfflat (vector vector_cosine_ops) 
WITH (lists = 100);
```

## Backup & Restore

### Backup
```bash
docker-compose exec postgres pg_dump -U amunx -F c -b -v -f /backup/amunx_$(date +%Y%m%d).dump amunx
```

### Restore
```bash
docker-compose exec postgres pg_restore -U amunx -d amunx -v /backup/amunx_20250106.dump
```

## Troubleshooting

### Migration Failed
```bash
# Check current migration version
docker-compose exec postgres psql -U amunx -d amunx -c "SELECT version FROM schema_migrations;"

# Force reset (DEV ONLY!)
make migrate-down  # Roll back
make migrate-up    # Try again
```

### sqlc Generation Errors
```bash
# Make sure migrations are applied first
make migrate-up

# Then generate
make sqlc-generate
```

### Vector Extension Not Found
```bash
# Install pgvector in Docker container
docker-compose exec postgres psql -U amunx -d amunx -c "CREATE EXTENSION vector;"
```

## Best Practices

1. **Always test migrations in dev first**
2. **Create down migrations** (rollback) for all up migrations
3. **Don't modify old migrations** - create new ones
4. **Use transactions** in migrations when possible
5. **Test data migration scripts** with production-like data volumes
6. **Backup before running migrations** in production
7. **Monitor query performance** after adding indexes (use `EXPLAIN ANALYZE`)

## Next Steps

After migrations:
1. Run `make sqlc-generate` to generate Go code
2. Update backend handlers to use new schema
3. Update mobile API client to use new endpoints
4. Run tests: `make test`

