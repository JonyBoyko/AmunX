# 🎯 Детальний breakdown задач (для Cursor AI)

**Кожна таска = 15-45 хвилин роботи**

---

## 🔥 Priority 1.1: Mobile UI Core (5-7 днів)

### Task 1.1.1: Recorder Screen (RCRD-001) — 2-3 години

**Файли:**
- `mobile/src/screens/RecorderScreen.tsx` (новий)
- `mobile/src/components/RecordButton.tsx` (новий)
- `mobile/src/components/UndoBanner.tsx` (новий)
- `mobile/src/hooks/useAudioRecorder.ts` (новий)

**Мікро-таски:**

```typescript
// 1.1.1.1 (30 хв): Base RecorderScreen layout
// Промпт: "Create RecorderScreen.tsx with: big round Record FAB, timer (00:00), 
// noise indicator, toggles (Public/Anon, Raw/Clean, Mask), 
// Live button (navigate to LiveHostScreen). Dark theme, Material 3 / iOS Human."

// 1.1.1.2 (45 хв): Recording logic (useAudioRecorder hook)
// Промпт: "Create useAudioRecorder.ts hook: start/stop recording, 
// save to temp file, upload to presigned URL from POST /v1/episodes API,
// handle permissions, noise level detection (VAD)."

// 1.1.1.3 (30 хв): Undo 10s banner
// Промпт: "Create UndoBanner.tsx component: countdown from 10s, 
// 'Публічно через 10с — Скасувати' text, progress bar, 
// on cancel → call POST /v1/episodes/{id}/undo"

// 1.1.1.4 (30 хв): Integration with Episode API
// Промпт: "Connect RecorderScreen to API: 
// 1) POST /v1/episodes (get upload_url)
// 2) Upload audio file
// 3) POST /v1/episodes/{id}/finalize
// 4) Show Undo banner
// 5) Navigate to Feed on success"

// 1.1.1.5 (15 хв): Error handling & offline queue
// Промпт: "Add error handling: show toast on failure, 
// queue upload for retry if offline using AsyncStorage"
```

---

### Task 1.1.2: Feed Screen (FEED-001) — 2-3 години

**Файли:**
- `mobile/src/screens/FeedScreen.tsx` (новий)
- `mobile/src/components/EpisodeCard.tsx` (новий)
- `mobile/src/components/MiniPlayer.tsx` (новий)
- `mobile/src/hooks/useFeed.ts` (новий)

**Мікро-таски:**

```typescript
// 1.1.2.1 (45 хв): FeedScreen + EpisodeCard
// Промпт: "Create FeedScreen.tsx: FlatList of episodes from GET /v1/episodes,
// EpisodeCard shows: avatar/Anon chip, Public/Anon badge, 
// Raw/Clean/Studio + Mask badges, Topic chip, TL;DR, 
// progress bar, 3 reactions, comments count. 
// Pull-to-refresh, pagination (after param)."

// 1.1.2.2 (30 хв): useFeed hook with TanStack Query
// Промпт: "Create useFeed.ts hook using @tanstack/react-query:
// fetch episodes, infinite scroll (useInfiniteQuery), 
// auto-refetch every 10s, cache 5min, handle errors."

// 1.1.2.3 (45 хв): MiniPlayer (sticky bottom)
// Промпт: "Create MiniPlayer.tsx: sticky bottom bar, 
// show current episode title, play/pause button, progress bar, 
// tap to expand to full player (navigate to EpisodeScreen).
// Use React Native Track Player or expo-av."

// 1.1.2.4 (30 хв): Empty/Error states
// Промпт: "Add empty state: 'Ще немає епізодів. Запишіть перший — 1 хв',
// error state with retry button, offline indicator."
```

---

### Task 1.1.3: Episode Detail Screen (EP-001) — 2 години

**Файли:**
- `mobile/src/screens/EpisodeScreen.tsx` (новий або оновити існуючий)
- `mobile/src/components/Player.tsx` (новий)
- `mobile/src/components/ReactionButtons.tsx` (новий)

**Мікро-таски:**

```typescript
// 1.1.3.1 (45 хв): Episode detail layout
// Промпт: "Create/update EpisodeScreen.tsx: 
// large player (waveform visual), title/tags, TL;DR text,
// chapters list (clickable timestamps), reactions (3 quick), 
// comments button (navigate to Comments), report button (overflow menu)."

// 1.1.3.2 (45 хв): Player component
// Промпт: "Create Player.tsx: play/pause/stop buttons, 
// scrubber (seek), speed controls (1x/1.5x/2x), 
// 15s back/forward buttons, show duration/current time.
// Use expo-av or react-native-track-player."

// 1.1.3.3 (30 хв): Reactions + API integration
// Промпт: "Create ReactionButtons.tsx: 3 quick reactions (👏🔥❤️),
// POST /v1/episodes/{id}/react on tap, show count (if available),
// optimistic updates."
```

---

### Task 1.1.4: Comments Screen (CMT-001) — 1.5 години

**Файли:**
- `mobile/src/screens/CommentsScreen.tsx` (новий)
- `mobile/src/components/CommentItem.tsx` (новий)
- `mobile/src/hooks/useComments.ts` (новий)

**Мікро-таски:**

```typescript
// 1.1.4.1 (45 хв): Comments list + input
// Промпт: "Create CommentsScreen.tsx: FlatList from GET /v1/episodes/{id}/comments,
// CommentItem shows avatar, text, timestamp, report button.
// Bottom input field + Send button, quick templates 
// ('Питання…', 'Розкажи продовження завтра')."

// 1.1.4.2 (30 хв): useComments hook
// Промпт: "Create useComments.ts: fetch comments (TanStack Query),
// post comment (mutation), pagination, optimistic updates."

// 1.1.4.3 (15 хв): Report comment
// Промпт: "Add report action: tap overflow → show ActionSheet 
// with reasons → POST /v1/reports {object_ref: 'comments/{id}', reason},
// hide comment locally after report."
```

---

### Task 1.1.5: Topic Screen (TOP-001) — 1.5 години

**Файли:**
- `mobile/src/screens/TopicScreen.tsx` (новий)
- `mobile/src/components/TopicHeader.tsx` (новий)
- `mobile/src/hooks/useTopic.ts` (новий)

**Мікро-таски:**

```typescript
// 1.1.5.1 (45 хв): Topic detail + episodes list
// Промпт: "Create TopicScreen.tsx: 
// TopicHeader (cover, title, description, Follow button),
// episodes list (same EpisodeCard from Feed),
// filters (Newest/Trending tabs)."

// 1.1.5.2 (30 хв): useTopic hook + Follow API
// Промпт: "Create useTopic.ts: GET /v1/topics/{id}, 
// fetch topic episodes GET /v1/episodes?topic={id},
// Follow: POST /v1/topics/{id}/follow, 
// Unfollow: DELETE /v1/topics/{id}/follow."

// 1.1.5.3 (15 хв): Create topic (if allowed)
// Промпт: "Add FAB 'Create Topic' (if user can): 
// navigate to CreateTopicScreen (simple form: title, description, is_public toggle),
// POST /v1/topics."
```

---

### Task 1.1.6: Profile/Settings Screen (PRF-001) — 1.5 години

**Файли:**
- `mobile/src/screens/ProfileScreen.tsx` (новий)
- `mobile/src/screens/SettingsScreen.tsx` (новий)

**Мікро-таски:**

```typescript
// 1.1.6.1 (30 хв): Profile screen
// Промпт: "Create ProfileScreen.tsx: 
// avatar/nick or 'Anonymous', 
// list of user's episodes (GET /v1/episodes?author={id}),
// stats (total episodes, followers - if implemented),
// Settings button."

// 1.1.6.2 (45 хв): Settings screen
// Промпт: "Create SettingsScreen.tsx:
// toggles: Public by default (ON), Anon mode (OFF),
// Default Mask (None/Basic/Studio picker),
// Default Quality (Raw/Clean picker),
// Notifications (navigate to NotificationsSettings),
// About, Sign out."

// 1.1.6.3 (15 хв): PATCH /v1/me integration
// Промпт: "Connect settings to API: 
// GET /v1/me (load current user),
// PATCH /v1/me {display_name, is_anon, ...} on save."
```

---

### Task 1.1.7: Auth Screen (ONB-001) — 1 година

**Файли:**
- `mobile/src/screens/AuthScreen.tsx` (новий)
- `mobile/src/hooks/useAuth.ts` (оновити або створити)

**Мікро-таски:**

```typescript
// 1.1.7.1 (30 хв): Auth screen UI
// Промпт: "Create AuthScreen.tsx: 
// logo, tagline ('Голосом як у твітері'), 
// email input, 'Надіслати лінк' button, legal footer."

// 1.1.7.2 (30 хв): Magic link flow
// Промпт: "Implement auth flow:
// 1) POST /v1/auth/magiclink {email} → 'Лінк надіслано на email'
// 2) Handle deep link (magic link callback)
// 3) Extract token from URL
// 4) POST /v1/auth/magiclink/verify {token} → save access_token/refresh_token
// 5) Navigate to Feed.
// Use AsyncStorage for tokens, useAuth hook for state."
```

---

## 🔥 Priority 1.2: Backend Improvements (2-3 дні)

### Task 1.2.1: PUBLIC_BY_DEFAULT enforcement — 30 хв

**Файл:** `backend/internal/app/config.go`, `backend/internal/http/episode_handlers.go`

```go
// Промпт: "Ensure PUBLIC_BY_DEFAULT=true is enforced:
// In episode_handlers.go normalizeVisibility(), 
// if visibility is empty and cfg.PublicByDefault==true → return 'public'.
// Add config field PublicByDefault bool `envconfig:\"PUBLIC_BY_DEFAULT\" default:\"true\"`"
```

---

### Task 1.2.2: UNDO_SECONDS=10 proper timing — 30 хв

**Файл:** `backend/internal/app/config.go`, `backend/internal/http/episode_handlers.go`

```go
// Промпт: "Change UNDO_SECONDS default from 300 to 10:
// In config.go: UndoSeconds int `envconfig:\"UNDO_SECONDS\" default:\"10\"`
// Verify undoEpisode() SQL uses this correctly:
// WHERE now() - status_changed_at <= ($2::int || ' seconds')::interval"
```

---

### Task 1.2.3: Better TL;DR generation — 1-2 години

**Файл:** `backend/internal/worker/audio/processor.go`, створити `backend/internal/nlp/tldr.go`

```go
// Промпт: "Improve generatePlaceholderSummary():
// Instead of 'Voice note (~X min)', generate:
// - Rule-based title from mask+duration: 
//   'Quick thought' (< 1min), 'Short reflection' (1-3min), 
//   'Deep dive' (> 3min)
// - Add mood emoji based on mask: 
//   none → '💭', basic → '🎙️', studio → '🎧'
// - Keywords: extract from duration bands (< 1min → ['quick', 'thought'])"
```

---

### Task 1.2.4: Topics API improvements — 1 година

**Файл:** створити `backend/internal/http/topic_handlers.go`

```go
// Промпт: "Create full Topics CRUD API:
// - POST /v1/topics {title, is_public, slug?} → create topic
// - GET /v1/topics?query=&page= → search topics
// - GET /v1/topics/{id} → detail
// - PATCH /v1/topics/{id} {title, description} → update (owner only)
// - DELETE /v1/topics/{id} → delete (owner only)
// - POST /v1/topics/{id}/follow → follow
// - DELETE /v1/topics/{id}/follow → unfollow
// - GET /v1/topics/{id}/followers → count
// Add search by slug or title (PG ILIKE)"
```

---

## 🔥 Priority 1.3: Mobile Polish (2 дні)

### Task 1.3.1: Offline support — 2-3 години

**Файли:**
- `mobile/src/lib/offlineQueue.ts` (новий)
- `mobile/src/hooks/useOfflineQueue.ts` (новий)

```typescript
// Промпт: "Implement offline upload queue:
// - When POST /v1/episodes fails (network error), save to AsyncStorage queue
// - Background task: check queue every 30s, retry upload
// - Show indicator in RecorderScreen: 'X uploads pending'
// - Use NetInfo to detect online/offline state"
```

---

### Task 1.3.2: Error states (ERR-001) — 1 година

**Файли:**
- `mobile/src/components/ErrorState.tsx` (новий)
- `mobile/src/components/EmptyState.tsx` (новий)

```typescript
// Промпт: "Create reusable error/empty components:
// ErrorState.tsx: friendly icon + text + 'Retry' button
// EmptyState.tsx: icon + text + primary action CTA
// Use in Feed, Comments, Topic screens."
```

---

### Task 1.3.3: Loading states — 30 хв

```typescript
// Промпт: "Add loading skeletons to:
// - FeedScreen: 3 skeleton EpisodeCards
// - EpisodeScreen: skeleton player + title
// - CommentsScreen: skeleton comment list
// Use react-native-skeleton-placeholder or custom shimmer."
```

---

### Task 1.3.4: Audio player controls polish — 1-2 години

```typescript
// Промпт: "Enhance Player.tsx:
// - Add waveform visualization (use audio_url waveform_json)
// - Show chapters as clickable markers on progress bar
// - Add sleep timer (15/30/45/60 min)
// - Background audio support (continue playing when app backgrounded)
// - Lock screen controls (media session API)"
```

---

## 🔥 Priority 2.1: Listener UI (2-3 дні)

### Task 2.1.1: LiveListenerScreen — 2-3 години

**Файл:** `mobile/src/screens/LiveListenerScreen.tsx` (оновити існуючий)

```typescript
// Промпт: "Create/update LiveListenerScreen.tsx:
// - Join/Leave button
// - Show host info (avatar, name, topic)
// - Audio player (LiveKit audio track)
// - Reactions buttons (floating emojis animation)
// - Chat panel (read-only or send messages)
// - Show listener count ('Десятки слухачів')
// - After host ends → auto-navigate to resulting Episode"
```

---

### Task 2.1.2: Reactions stream animation — 1-2 години

```typescript
// Промпт: "Create ReactionStream.tsx component:
// - Floating emojis animation (react-native-reanimated)
// - Emojis fly up from bottom → fade out at top
// - Receive reactions via LiveKit data channel
// - Show last 5-10 reactions on screen
// - Tap quick reaction button → send via data channel"
```

---

### Task 2.1.3: Chat panel improvements — 1 година

```typescript
// Промпт: "Enhance chat in Live screens:
// - Auto-scroll to latest message
// - Show typing indicator
// - Throttle send (max 1 msg/2s)
// - Link detection (clickable)
// - Message length limit (500 chars)"
```

---

## 🔥 Priority 2.2: Live Mask (2-3 дні)

### Task 2.2.1: Client-side DSP — 4-6 годин (складно!)

**Це найскладніша частина. Потребує native modules.**

```typescript
// Промпт: "Implement real-time voice masking (pitch shift):
// Option A: Use react-native-audio-processing (if exists) or superpowered SDK
// Option B: Create native module (Obj-C/Swift + Java/Kotlin):
//   - Audio input → apply pitch shift (±2-3 semitones) → output
//   - Buffer size 20-40ms to minimize latency
//   - Use WSOLA/Phase vocoder algorithm
// Option C: Fallback to post-processing only (easier)
// 
// For MVP: start with Option C (post-processing), mark as 'beta'"
```

---

### Task 2.2.2: Fallback toggle — 30 хв

```typescript
// Промпт: "Add toggle in LiveHostScreen:
// 'Mask voice in real-time' (ON/OFF)
// - If OFF: show banner 'Voice will be masked in recording only'
// - If ON: enable DSP pipeline
// - Monitor battery drain: if > 10%/15min → auto-disable + toast warning"
```

---

### Task 2.2.3: Battery/CPU monitoring — 1 година

```typescript
// Промпт: "Add performance monitoring:
// - Use react-native-device-info to track battery level
// - Log CPU usage during live (if possible)
// - If battery drops > 10% in 15min while live → show warning
// - If app crashes 2+ times with DSP enabled → disable DSP by default next time"
```

---

## 🔥 Priority 3.1: STT Service (3-4 дні)

### Task 3.1.1: Faster-Whisper Docker service — 3-4 години

**Файли:**
- `backend/services/stt/Dockerfile` (новий)
- `backend/services/stt/main.py` (новий)
- `docker-compose.yml` (оновити)

```python
# Промпт: "Create Faster-Whisper HTTP service:
# - Dockerfile: Python 3.11 + faster-whisper (small-int8 model)
# - main.py (FastAPI):
#   POST /transcribe {audio_url or audio_file} → {text, segments[], language}
#   GET /health
# - Segments: [{start, end, text}] for chapters
# - Add to docker-compose.yml as 'stt' service
# - Env: MODEL_SIZE=small (default), DEVICE=cpu|cuda"
```

---

### Task 3.1.2: Queue `full_stt` job — 1-2 години

**Файл:** `backend/internal/worker/audio/processor.go`, `backend/internal/queue/topics.go`

```go
// Промпт: "Add full_stt queue handling:
// - Define queue.TopicFullSTT = 'full_stt'
// - In processor.go: add claimAndTranscribe() method
// - Job payload: {episode_id, audio_url, user_plan}
// - If plan != 'pro' → skip (or error)
// - Call STT service: POST http://stt:5000/transcribe
// - Save transcript to summaries.transcript_text (add column)
// - Generate chapters from segments (every 60-120s or on silence gaps)"
```

---

### Task 3.1.3: Transcripts storage & API — 1-2 години

**Файли:**
- `backend/db/migrations/0006_transcripts.up.sql` (новий)
- `backend/internal/http/transcript_handlers.go` (новий)

```sql
-- Промпт: "Create migration 0006_transcripts:
ALTER TABLE summaries ADD COLUMN transcript_text TEXT;
ALTER TABLE summaries ADD COLUMN transcript_language TEXT;
ALTER TABLE summaries ADD COLUMN chapters_json JSONB; -- [{start:int, end:int, title:string}]

CREATE INDEX ON summaries USING gin(to_tsvector('english', transcript_text));
```

```go
// Промпт: "Create transcript_handlers.go:
// GET /v1/episodes/{id}/transcript
//   → if user.plan != 'pro': 402 Payment Required
//   → return {text, language, chapters: [{start, end, title}]}
// GET /v1/episodes/{id}/search?q=keyword
//   → Pro-only, search in transcript_text using PG full-text"
```

---

### Task 3.1.4: Chapters generation — 1-2 години

```go
// Промпт: "Implement semantic chapter generation:
// - Input: transcript segments from Whisper
// - Algorithm:
//   1) Group segments by silence gaps > 2s
//   2) Or every 60-120s fixed
//   3) Title: first 3-5 words of segment + '...'
//   4) Or use simple keyword extraction (most frequent nouns)
// - Output: [{start: 0, end: 65, title: 'Quick intro'}]
// - Save to summaries.chapters_json"
```

---

### Task 3.1.5: Free keywords (30-60s) — 1 година

```go
// Промпт: "Implement free keywords for long public episodes:
// - In processor.go after audio processing:
//   IF episode.visibility == 'public' AND duration > 300s (5min):
//     - Extract first 60s audio chunk
//     - Call STT service (faster-whisper)
//     - Extract keywords (simple: most frequent words, exclude stop words)
//     - Save to summaries.keywords (max 10 keywords)
//   ELSE: skip (Pro feature)
// - Add env: FREE_KEYWORDS_SEC=60"
```

---

## 🔥 Priority 3.2: RevenueCat Billing (3-4 дні)

### Task 3.2.1: RevenueCat SDK setup — 2-3 години

**Файли:**
- `mobile/ios/Podfile` (оновити)
- `mobile/android/app/build.gradle` (оновити)
- `mobile/src/lib/purchases.ts` (новий)

```typescript
// Промпт: "Integrate RevenueCat SDK:
// - Install: npm install react-native-purchases
// - iOS: pod install
// - Android: update build.gradle
// - Create purchases.ts wrapper:
//   - configurePurchases(apiKey)
//   - getOfferings() → Pro monthly/yearly
//   - purchasePackage(package)
//   - restorePurchases()
//   - getCustomerInfo() → check active subscriptions
// - Add RevenueCat API keys to mobile/.env (iOS/Android separate)"
```

---

### Task 3.2.2: Paywall UI (PAY-001) — 2-3 години

**Файл:** `mobile/src/screens/PaywallScreen.tsx` (новий)

```typescript
// Промпт: "Create PaywallScreen.tsx:
// - Hero section: 'Unlock Pro Features'
// - Feature bullets:
//   ✨ Real-time captions & dubbing (12 languages)
//   📝 Full transcripts & search
//   🎧 Studio voice mask (best quality)
//   ⏱️ Longer lives (up to 60min)
//   📊 Advanced analytics
// - Pricing cards: Monthly $9.99, Yearly $79.99 (save 33%)
// - CTA buttons: 'Start Free Trial' (if applicable), 'Subscribe'
// - Terms & privacy links
// - 'Restore Purchases' button
// - Use offerings from RevenueCat getOfferings()"
```

---

### Task 3.2.3: Backend webhook — 1-2 години

**Файл:** `backend/internal/http/billing_handlers.go` (новий)

```go
// Промпт: "Create RevenueCat webhook handler:
// POST /v1/billing/rc/webhook
//   - Verify webhook signature (RevenueCat docs)
//   - Handle events:
//     - INITIAL_PURCHASE → UPDATE users SET plan='pro' WHERE email=event.app_user_id
//     - RENEWAL → extend plan
//     - CANCELLATION → UPDATE users SET plan='free' (after grace period)
//     - REFUND → UPDATE users SET plan='free'
//   - Log all events to billing_events table (create migration)
//   - Return 200 OK"
```

---

### Task 3.2.4: Plan entitlements middleware — 1 година

**Файл:** `backend/internal/http/middleware/entitlements.go` (новий)

```go
// Промпт: "Create RequirePro() middleware:
// - Check if user.plan == 'pro'
// - If not: return 402 Payment Required + 
//   {error: 'pro_required', message: 'This feature requires Pro plan'}
// - Apply to endpoints:
//   - GET /v1/episodes/{id}/transcript
//   - POST /v1/live/sessions (if > 15min duration)
//   - POST /v1/live/sessions/{id}/translate/enable
//   - GET /v1/search?full_text=..."
```

---

### Task 3.2.5: Pro features gating (UI) — 1-2 години

```typescript
// Промпт: "Add Pro locks in mobile UI:
// - EpisodeScreen: if transcript exists but user.plan != 'pro':
//   Show 'Transcript (Pro)' tab with lock icon → tap → PaywallScreen
// - LiveHostScreen: if duration > 15min:
//   Show banner 'Lives > 15min require Pro' → CTA to paywall
// - Settings: 'Studio Mask (Pro)' with lock
// - Search: 'Search in transcripts' input disabled for Free → tooltip 'Pro feature'"
```

---

## 🔥 Priority 4.1: Search & Trending (3 дні)

### Task 4.1.1: Search API — 2-3 години

**Файл:** `backend/internal/http/search_handlers.go` (новий), міграція

```sql
-- Промпт: "Create migration for full-text search:
CREATE INDEX episodes_search_idx ON episodes 
  USING gin(to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(summary, '')));

CREATE INDEX summaries_search_idx ON summaries 
  USING gin(to_tsvector('english', COALESCE(transcript_text, '')));
```

```go
// Промпт: "Create search_handlers.go:
// GET /v1/search?q=query&type=episodes|topics
//   - For Free users: search in episodes.title + summaries.keywords (ILIKE)
//   - For Pro users: search in summaries.transcript_text (PG full-text)
//   - Return {episodes: [], topics: [], has_more: bool}
//   - Pagination: limit=20, offset
//   - Highlight matches in results"
```

---

### Task 4.1.2: Trending scoring — 1-2 години

```go
// Промпт: "Implement trending algorithm:
// - Score formula: 
//   score = (reactions_count * 2 + comments_count * 5) / (hours_since_publish + 2)^1.5
// - Add virtual column or materialized view:
//   CREATE MATERIALIZED VIEW trending_episodes AS
//   SELECT e.id, e.title, 
//     (COALESCE(r_count, 0) * 2 + COALESCE(c_count, 0) * 5) / 
//     POWER(EXTRACT(EPOCH FROM (now() - e.published_at))/3600 + 2, 1.5) as score
//   FROM episodes e
//   LEFT JOIN (SELECT episode_id, COUNT(*) as r_count FROM reactions GROUP BY episode_id) r ON r.episode_id = e.id
//   LEFT JOIN (SELECT episode_id, COUNT(*) as c_count FROM comments GROUP BY episode_id) c ON c.episode_id = e.id
//   WHERE e.status = 'public' AND e.published_at > now() - interval '7 days'
//   ORDER BY score DESC;
// - Refresh every 10 minutes (cron job or worker)
// - GET /v1/trending → top 50 episodes"
```

---

### Task 4.1.3: Explore screen (mobile) — 2 години

```typescript
// Промпт: "Create ExploreScreen.tsx:
// - Tabs: Trending / New / Topics
// - Trending tab: fetch from GET /v1/trending
// - New tab: GET /v1/episodes (default sort)
// - Topics tab: GET /v1/topics (popular)
// - Search bar at top → navigate to SearchScreen on tap"
```

---

### Task 4.1.4: Search screen (mobile) — 1-2 години

```typescript
// Промпт: "Create SearchScreen.tsx:
// - Search input (debounced)
// - Tabs: Episodes / Topics
// - Results list (same EpisodeCard / TopicCard)
// - Empty state: 'No results for "{query}"'
// - Recent searches (save to AsyncStorage)
// - For Pro: show 'Search in transcripts' toggle"
```

---

## 🔥 Priority 4.2: Notifications (2-3 дні)

### Task 4.2.1: Push service setup — 3-4 години

**Файли:**
- `backend/internal/notifications/fcm.go` (новий)
- `backend/internal/notifications/apns.go` (новий)
- `backend/db/migrations/0007_push_tokens.up.sql` (новий)

```sql
-- Промпт: "Create migration:
CREATE TABLE push_tokens (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL, -- 'ios' | 'android'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);
```

```go
// Промпт: "Implement push notifications:
// - fcm.go: Send via Firebase Cloud Messaging (FCM)
// - apns.go: Send via Apple Push Notification Service (APNS)
// - POST /v1/push/register {token, platform} → save to push_tokens
// - Trigger notifications on events:
//   - New episode in followed topic → 'New episode in {topic}'
//   - Reply to your episode/comment → '{user} replied to your {type}'
//   - Daily digest → 'You have 5 new episodes from your follows'
// - Use worker queue for async sending"
```

---

### Task 4.2.2: Notification categories — 1-2 години

```sql
-- Промпт: "Add user notification preferences:
ALTER TABLE users ADD COLUMN notification_settings JSONB DEFAULT '{
  \"new_episode_in_topic\": true,
  \"reply_to_my_content\": true,
  \"daily_digest\": true,
  \"live_started\": true
}'::jsonb;
```

```go
// Промпт: "Check preferences before sending:
// - Before sending push, check user.notification_settings[category]
// - If false → skip
// - Add API: PATCH /v1/me/notifications {category: bool}"
```

---

### Task 4.2.3: NTF-001 screen (mobile) — 1-2 години

```typescript
// Промпт: "Create NotificationsScreen.tsx:
// - FlatList of notifications (fetch from backend or local)
// - Notification types:
//   - 'New episode in {topic}' → tap → EpisodeScreen
//   - 'Reply to your episode' → tap → CommentsScreen
//   - 'Daily digest' → tap → Feed
// - Mark as read on tap
// - Settings button → NotificationsSettingsScreen"
```

---

### Task 4.2.4: Settings for notifications — 1 година

```typescript
// Промпт: "Create NotificationsSettingsScreen.tsx:
// - Toggle switches for each category:
//   - New episode in followed topics
//   - Replies to my content
//   - Daily digest
//   - Live started
// - Save to backend: PATCH /v1/me/notifications"
```

---

## 📊 Загальна оцінка часу

| Priority | Група | Час оцінка |
|----------|-------|------------|
| **P1.1** | Mobile UI Core | 12-15 годин |
| **P1.2** | Backend Improvements | 3-4 години |
| **P1.3** | Mobile Polish | 6-8 годин |
| **P2.1** | Listener UI | 5-7 годин |
| **P2.2** | Live Mask | 8-12 годин |
| **P3.1** | STT Service | 10-14 годин |
| **P3.2** | RevenueCat Billing | 8-12 годин |
| **P4.1** | Search & Trending | 8-10 годин |
| **P4.2** | Notifications | 8-12 годин |

**Загалом:** ~70-100 годин чистої розробки = **2-3 тижні активної роботи**

---

## 🚀 Готово до старту!

**Оберіть, з чого почати, і я почну генерувати код:**

1️⃣ **Task 1.1.1** (Recorder Screen) — найвидиміший результат  
2️⃣ **Task 1.1.2** (Feed Screen) — база для всього  
3️⃣ **Task 3.1.1** (STT Service) — backend-first підхід  
4️⃣ **Ваш вибір** — скажіть номер таски

Після вибору я створю файли, код, і ми рухаємось далі! 🎯

