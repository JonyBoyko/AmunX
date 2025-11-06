# AmunX API Documentation

**Base URL**: `/api/v1`  
**Auth**: JWT Bearer token in `Authorization: Bearer <token>` header  
**Content-Type**: `application/json`

## Authentication

### Sign Up
```http
POST /api/v1/auth/signup
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "display_name": "John Doe"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "John Doe",
    "handle": "johndoe",
    "created_at": "2025-01-06T12:00:00Z"
  },
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

### Login
```http
POST /api/v1/auth/login
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

### Refresh Token
```http
POST /api/v1/auth/refresh
```

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

---

## Upload (Presigned URLs)

### Request Presigned Upload URL
```http
POST /api/v1/uploads/presign
Authorization: Bearer <token>
```

**Request:**
```json
{
  "mime": "audio/mpeg",
  "filename": "my-recording.mp3"
}
```

**Response:** `200 OK`
```json
{
  "url": "https://s3.example.com/bucket/uploads/...",
  "fields": {
    "key": "uploads/user-id/uuid.mp3",
    "policy": "...",
    "signature": "..."
  },
  "s3_key": "uploads/user-id/uuid.mp3",
  "expires_at": "2025-01-06T13:00:00Z"
}
```

**Usage:**
1. Client uploads file to `url` using presigned POST
2. After successful upload, client calls `POST /audio` with `s3_key`

---

## Audio Items

### Create Audio Item
```http
POST /api/v1/audio
Authorization: Bearer <token>
```

**Request:**
```json
{
  "s3_key": "uploads/user-id/uuid.mp3",
  "duration_sec": 45,
  "kind": "micro",
  "title": "My First Audio Post",
  "description": "Testing the new audio feature",
  "tags": ["technology", "startup"],
  "visibility": "private",
  "share_to_circle_ids": []
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "owner_id": "uuid",
  "visibility": "private",
  "title": "My First Audio Post",
  "description": "Testing the new audio feature",
  "kind": "micro",
  "duration_sec": 45,
  "s3_key": "uploads/user-id/uuid.mp3",
  "audio_url": "https://cdn.example.com/...",
  "tags": ["technology", "startup"],
  "share_to_circle_ids": [],
  "created_at": "2025-01-06T12:00:00Z"
}
```

**Privacy:** Defaults to `private`. User must explicitly set `visibility` to share.

### Get Audio Item
```http
GET /api/v1/audio/:id
Authorization: Bearer <token> (required if private)
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "owner": {
    "id": "uuid",
    "display_name": "John Doe",
    "avatar_url": "..."
  },
  "visibility": "public",
  "title": "My Public Audio",
  "description": "...",
  "kind": "micro",
  "duration_sec": 45,
  "audio_url": "https://cdn.example.com/...",
  "waveform": [0.1, 0.3, 0.5, ...],
  "tags": ["technology"],
  "stats": {
    "likes": 42,
    "saves": 15,
    "plays": 120
  },
  "user_state": {
    "liked": true,
    "saved": false
  },
  "created_at": "2025-01-06T12:00:00Z"
}
```

### List My Audio Items
```http
GET /api/v1/me/audio?kind=&visibility=&cursor=
Authorization: Bearer <token>
```

**Query Parameters:**
- `kind` (optional): `micro` or `podcast_episode`
- `visibility` (optional): `private`, `circles`, `public`
- `cursor` (optional): Pagination cursor
- `limit` (optional): Max 100, default 20

**Response:** `200 OK`
```json
{
  "items": [...],
  "next_cursor": "uuid",
  "has_more": true
}
```

### Update Audio Item
```http
PATCH /api/v1/audio/:id
Authorization: Bearer <token>
```

**Request:** (all fields optional)
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "tags": ["new", "tags"],
  "visibility": "public",
  "share_to_circle_ids": ["circle-uuid-1"]
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  ...updated fields
}
```

### Delete Audio Item
```http
DELETE /api/v1/audio/:id
Authorization: Bearer <token>
```

**Response:** `204 No Content`

---

## Transcripts & Summaries

### Get Transcript
```http
GET /api/v1/audio/:id/transcript
Authorization: Bearer <token> (if private)
```

**Response:** `200 OK`
```json
{
  "audio_id": "uuid",
  "text": "Full transcript text here...",
  "lang": "en",
  "words": [
    {"word": "Hello", "start": 0.0, "end": 0.5},
    {"word": "world", "start": 0.6, "end": 1.0}
  ]
}
```

### Get Summary
```http
GET /api/v1/audio/:id/summary
Authorization: Bearer <token> (if private)
```

**Response:** `200 OK`
```json
{
  "audio_id": "uuid",
  "preview_sentence": "A quick discussion about startup growth strategies",
  "tldr": "In this episode, we explore three key strategies...",
  "chapters": [
    {"start": 0, "end": 120, "title": "Introduction"},
    {"start": 120, "end": 300, "title": "Growth Strategies"},
    {"start": 300, "end": 450, "title": "Conclusion"}
  ],
  "keywords": ["startup", "growth", "strategy"]
}
```

### Get Clips
```http
GET /api/v1/audio/:id/clips
Authorization: Bearer <token> (if private)
```

**Response:** `200 OK`
```json
{
  "clips": [
    {
      "id": "uuid",
      "audio_id": "uuid",
      "start_sec": 45,
      "end_sec": 60,
      "title": "Key Quote",
      "quote": "The most important thing is to ship fast"
    }
  ]
}
```

---

## Explore Feed

### Get Explore Feed
```http
GET /api/v1/explore?cursor=&topics=&city=&len=30..120
```

**Query Parameters:**
- `cursor` (optional): Pagination cursor
- `topics` (optional): Comma-separated tags
- `city` (optional): Filter by city (for local circles)
- `len` (optional): Duration range in seconds (e.g., `30..120`)
- `limit` (optional): Max 50, default 20

**Response:** `200 OK`
```json
{
  "cards": [
    {
      "id": "uuid",
      "kind": "audio_item",
      "owner": {
        "id": "uuid",
        "display_name": "Jane Smith",
        "avatar_url": "..."
      },
      "duration_sec": 45,
      "preview_sentence": "A quick tip about React hooks",
      "tags": ["react", "javascript"],
      "waveform_peaks": [0.1, 0.3, ...],
      "audio_url": "https://cdn.example.com/...",
      "created_at": "2025-01-06T12:00:00Z",
      "stats": {
        "likes": 15,
        "plays": 200
      }
    },
    {
      "id": "uuid",
      "kind": "clip",
      "parent_audio_id": "uuid",
      "owner": {...},
      "duration_sec": 15,
      "title": "Best Quote",
      "quote": "Ship it!",
      "audio_url": "...",
      "created_at": "2025-01-06T11:00:00Z"
    }
  ],
  "next_cursor": "uuid",
  "has_more": true
}
```

**Ranking:** Cards are ranked by:
- Recency: `exp(-age_hours/72)`
- Engagement: preview completion rate, save rate, follow rate
- Diversity: Max 2 items per author in top 20

---

## Feed Events

### Submit Event
```http
POST /api/v1/events
Authorization: Bearer <token>
```

**Request:**
```json
{
  "audio_id": "uuid",
  "event": "preview_finished",
  "meta": {
    "playback_position": 45,
    "source": "explore"
  }
}
```

**Event Types:**
- `impression` - Card visible ≥1.5s
- `preview_finished` - User listened to preview fully
- `play` - User started playback
- `complete` - User listened to 95%+
- `save` - User saved/bookmarked
- `share` - User shared
- `quote` - User created quote/clip
- `follow_author` - User followed author after listening

**Response:** `204 No Content`

---

## Search

### Search Audio
```http
GET /api/v1/search?q=startup+growth&limit=20&offset=0
Authorization: Bearer <token> (optional, affects results)
```

**Response:** `200 OK`
```json
{
  "results": [
    {
      "audio_id": "uuid",
      "owner": {...},
      "title": "Startup Growth Strategies",
      "duration_sec": 180,
      "snippet": "...discussing <b>startup</b> <b>growth</b> tactics...",
      "match_score": 0.85,
      "tags": ["startup", "business"],
      "created_at": "2025-01-06T10:00:00Z"
    }
  ],
  "total": 42,
  "search_type": "hybrid"
}
```

**Search combines:**
- Full-text search (PostgreSQL tsvector)
- Vector similarity search (pgvector cosine)
- Tag matching

---

## Smart Circles

### Create Circle
```http
POST /api/v1/circles
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Warsaw Tech Community",
  "description": "Voice discussions for Warsaw tech folks",
  "is_local": true,
  "city": "Warsaw",
  "country": "Poland"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "owner_id": "uuid",
  "name": "Warsaw Tech Community",
  "description": "...",
  "is_local": true,
  "city": "Warsaw",
  "country": "Poland",
  "member_count": 1,
  "created_at": "2025-01-06T12:00:00Z"
}
```

### Get Circle
```http
GET /api/v1/circles/:id
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "owner": {...},
  "name": "Warsaw Tech Community",
  "description": "...",
  "is_local": true,
  "city": "Warsaw",
  "member_count": 42,
  "user_role": "member",
  "created_at": "2025-01-06T12:00:00Z"
}
```

### Join Circle
```http
POST /api/v1/circles/:id/join
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "circle_id": "uuid",
  "user_id": "uuid",
  "role": "member",
  "joined_at": "2025-01-06T12:00:00Z"
}
```

### Leave Circle
```http
POST /api/v1/circles/:id/leave
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Get Circle Feed
```http
GET /api/v1/circles/:id/feed?cursor=&limit=20
Authorization: Bearer <token> (must be member)
```

**Response:** `200 OK`
```json
{
  "posts": [
    {
      "id": "uuid",
      "owner": {...},
      "title": "My thoughts on AI",
      "duration_sec": 90,
      "audio_url": "...",
      "reply_count": 3,
      "created_at": "2025-01-06T12:00:00Z"
    }
  ],
  "next_cursor": "uuid"
}
```

### Post to Circle
```http
POST /api/v1/circles/:id/posts
Authorization: Bearer <token>
```

**Request:**
```json
{
  "audio_id": "uuid",
  "title": "My Voice Post",
  "description": "Optional description"
}
```

**Response:** `201 Created`

### Reply to Post (Threaded)
```http
POST /api/v1/circles/:id/replies
Authorization: Bearer <token>
```

**Request:**
```json
{
  "parent_audio_id": "uuid",
  "s3_key": "uploads/...",
  "duration_sec": 30,
  "title": "Re: AI Discussion"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "parent_audio_id": "uuid",
  "owner_id": "uuid",
  "duration_sec": 30,
  "audio_url": "...",
  "created_at": "2025-01-06T12:10:00Z"
}
```

### Moderate Circle
```http
POST /api/v1/circles/:id/moderate
Authorization: Bearer <token> (must be owner/moderator)
```

**Request:**
```json
{
  "target_user_id": "uuid",
  "action": "remove_member"
}
```

**Actions:**
- `remove_member` - Kick user from circle
- `delete_post` - Delete a post (requires `target_audio_id`)
- `promote_moderator` - Make user a moderator
- `demote_moderator` - Remove moderator role

**Response:** `200 OK`

---

## Podcasts (RSS Export)

### Create Podcast Show
```http
POST /api/v1/podcasts/shows
Authorization: Bearer <token>
```

**Request:**
```json
{
  "title": "My Awesome Podcast",
  "description": "Weekly discussions about tech",
  "cover_url": "https://cdn.example.com/cover.jpg"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "owner_id": "uuid",
  "title": "My Awesome Podcast",
  "description": "...",
  "cover_url": "...",
  "rss_slug": "my-awesome-podcast-abc123",
  "rss_url": "https://api.amunx.com/podcasts/rss/my-awesome-podcast-abc123.xml",
  "created_at": "2025-01-06T12:00:00Z"
}
```

### Add Episode to Show
```http
POST /api/v1/podcasts/shows/:id/episodes
Authorization: Bearer <token>
```

**Request:**
```json
{
  "audio_id": "uuid",
  "published_at": "2025-01-06T12:00:00Z"
}
```

**Response:** `201 Created`

### Get RSS Feed (Public)
```http
GET /api/v1/podcasts/rss/:slug.xml
```

**Response:** `200 OK` (XML)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="...">
  <channel>
    <title>My Awesome Podcast</title>
    <description>...</description>
    <item>
      <title>Episode 1</title>
      <enclosure url="..." type="audio/mpeg" length="..."/>
      <pubDate>...</pubDate>
    </item>
  </channel>
</rss>
```

---

## Social Interactions

### Like Audio Item
```http
POST /api/v1/audio/:id/like
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Unlike
```http
DELETE /api/v1/audio/:id/like
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Save (Bookmark)
```http
POST /api/v1/audio/:id/save
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Unsave
```http
DELETE /api/v1/audio/:id/save
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Follow User
```http
POST /api/v1/users/:id/follow
Authorization: Bearer <token>
```

**Response:** `204 No Content`

### Unfollow
```http
DELETE /api/v1/users/:id/follow
Authorization: Bearer <token>
```

**Response:** `204 No Content`

---

## Internal (Worker Triggers)

### Queue Processing Job
```http
POST /api/v1/internal/processing/queue
Authorization: Admin-Token
```

**Request:**
```json
{
  "audio_id": "uuid"
}
```

**Response:** `202 Accepted`

**Pipeline:**
1. Transcribe (Whisper)
2. Summarize (GPT-4)
3. Auto-chapters
4. Auto-clips (5-10 clips)
5. Embeddings (vector chunks)

---

## Error Responses

**400 Bad Request**
```json
{
  "error": "invalid_request",
  "message": "duration_sec is required"
}
```

**401 Unauthorized**
```json
{
  "error": "unauthorized",
  "message": "Invalid or expired token"
}
```

**403 Forbidden**
```json
{
  "error": "forbidden",
  "message": "You don't have permission to access this resource"
}
```

**404 Not Found**
```json
{
  "error": "not_found",
  "message": "Audio item not found"
}
```

**429 Too Many Requests**
```json
{
  "error": "rate_limit_exceeded",
  "message": "Please slow down",
  "retry_after": 60
}
```

---

## Rate Limits

- **Authenticated**: 1000 requests/hour
- **Upload**: 10 uploads/hour
- **Events**: 100 events/minute

---

## Feature Flags

- `FEATURE_PODCAST_RSS`: ✅ Enabled
- `FEATURE_LIVE_ROOMS`: ❌ Disabled (stub only)
- `FEATURE_AUDIOGRAM_EXPORT`: ❌ Disabled (returns 501)

---

## Changelog

### 2025-01-06 - Major Refactor
- Replaced `episodes` with unified `audio_items`
- Added Smart Circles API
- Added Explore feed with ranking
- Added privacy controls (private by default)
- Added podcast RSS export
- Added search (text + vector)

