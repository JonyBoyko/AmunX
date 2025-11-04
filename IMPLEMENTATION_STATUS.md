# 📊 AmunX Implementation Status & Plan

**Аналіз виконано:** 2025-11-04  
**Базований на:** Product Spec v0.1 + Delivery Plan

---

## ✅ Вже реалізовано (що працює)

### Phase 0 — Infrastructure (90% done)

✅ **Backend (Go + chi)**
- ✅ Health endpoints (`/healthz`, `/readyz`)
- ✅ Middleware: request-id, gzip, CORS, rate-limit (Redis)
- ✅ Auth: **Magic link** (`POST /v1/auth/magiclink`, verify)
- ✅ JWT: Access + Refresh tokens з rotation
- ✅ Storage module (S3-compatible, R2 ready)
- ✅ Queue (Redis streams)
- ✅ Config від env
- ✅ PostgreSQL + sqlc
- ✅ Migrations (golang-migrate)

✅ **Infrastructure**
- ✅ Docker Compose (api, worker, postgres, redis, livekit, loki, grafana)
- ✅ Міграції автоматизовані (`migrate.sh`, `migrate.ps1`)
- ✅ Logging (zerolog)
- ✅ Grafana + Loki (базово)

✅ **Mobile (React Native + TS)**
- ✅ Bare workflow + TypeScript
- ✅ React Navigation
- ✅ TanStack Query
- ✅ **PostHog analytics** (events tracking)
- ✅ Sentry (error tracking)
- ✅ Audio recording permissions

❌ **Missing from Phase 0:**
- ❌ CI/CD pipelines (GitHub Actions)
- ❌ Snyk/Trivy security scans

---

### Phase 1 — Capture & Feed (70% done)

✅ **Backend API**
- ✅ `POST /v1/episodes` → presigned upload URL
- ✅ `POST /v1/episodes/{id}/finalize` → queue job
- ✅ `POST /v1/episodes/{id}/undo` → cancel publish
- ✅ `GET /v1/episodes` → feed (pagination, filters)
- ✅ `GET /v1/episodes/{id}` → detail
- ✅ Topics CRUD + follow
- ✅ Comments CRUD
- ✅ Reactions (react/unreact)

✅ **Audio Processing (Worker)**
- ✅ FFmpeg pipeline: denoise (arnndn) + loudnorm + opus 24kbps
- ✅ Voice mask (basic/studio) через pitch shift
- ✅ Waveform generation (placeholder)
- ✅ Placeholder TL;DR/keywords/mood generation
- ✅ Moderation keyword spotting

❌ **Missing from Phase 1:**
- ❌ **10-sec Undo timer** на клієнті (є API, немає UI/таймера)
- ❌ Proper keywords extraction (зараз placeholder)
- ❌ Real mood detection (зараз placeholder `{valence:0.1, arousal:0.3}`)
- ❌ **Mobile UI:**
  - ❌ Recorder screen з Undo banner
  - ❌ Feed screen (карточки епізодів)
  - ❌ Episode detail screen
  - ❌ Comments screen
  - ❌ Topic screen
- ❌ Push notifications (нові епізоди, коменти)

---

### Phase 1.5 — Moderation V1 (60% done)

✅ **Backend**
- ✅ `moderation_flags` table
- ✅ `POST /v1/reports` API
- ✅ Keyword spotting у worker
- ✅ Shadowban field у users
- ✅ Rate limits (episodes, comments)

❌ **Missing:**
- ❌ Mod panel UI (список reports, actions)
- ❌ Role-based access (admin/moderator)
- ❌ Auto-hide flagged content

---

### Phase 2 — Livecast (80% done)

✅ **Backend + LiveKit**
- ✅ `POST /v1/live/sessions` (create, host token)
- ✅ `GET /v1/live/sessions/{id}` (join, listener token)
- ✅ `POST /v1/live/sessions/{id}/end`
- ✅ LiveKit integration (self-host ready)
- ✅ Server-side recording → job `finalize_live`
- ✅ Auto-convert live → episode

✅ **Mobile**
- ✅ LiveHostScreen (повний)
- ✅ LiveKit React Native SDK integration
- ✅ Host controls (mute, end, reactions, chat)

❌ **Missing:**
- ❌ LiveListenerScreen (listener UI) — є файл, але не перевірено
- ❌ WebSocket для reactions/chat (може працює через LiveKit data channel?)
- ❌ Listener count display ("десятки/сотні" approximation)

---

### Phase 2.5 — Live Mask Beta (70% done)

✅ **Backend**
- ✅ `mask` field у `live_sessions` table
- ✅ Mask processing у worker

❌ **Missing:**
- ❌ Client-side DSP (real-time pitch/formant shift перед send)
- ❌ Fallback toggle "mask only in recording"
- ❌ Battery/CPU profiling
- ❌ UI для live mask settings

---

### Phase 2.7 — Live Translate (0% done)

❌ **Повністю відсутнє:**
- ❌ ASR streaming service
- ❌ MT (Machine Translation) service  
- ❌ TTS (Text-to-Speech) для dub
- ❌ Translation Router
- ❌ Captions WebSocket
- ❌ Pro gating для translate
- ❌ Mobile UI (CC button, language selector, track switch)
- ❌ Budget guards

---

### Phase 3 — Pro & Billing (5% done)

✅ **Existing:**
- ✅ `users.plan` field (free/pro)
- ✅ PostHog analytics events

❌ **Missing:**
- ❌ **STT service (Faster-Whisper)**
- ❌ Full transcript generation
- ❌ Chapters (semantic splitting)
- ❌ Search по тексту (Pro-only)
- ❌ **RevenueCat integration:**
  - ❌ Mobile IAP setup
  - ❌ Webhook `/v1/billing/rc/webhook`
  - ❌ Plan entitlements check
- ❌ Paywall UI (mobile)
- ❌ Free keywords (30-60s для довгих епізодів)

---

### Phase 4 — Discovery (0% done)

❌ **Повністю відсутнє:**
- ❌ Search API (keywords/tags для free, full-text для Pro)
- ❌ Trending scoring (time decay + reactions + comments)
- ❌ Push notifications service
- ❌ Notification categories (episodes, replies, digest)
- ❌ Explore screen (mobile)
- ❌ Search screen (mobile)

---

### Phase 5 — Analytics & Costs (20% done)

✅ **Existing:**
- ✅ PostHog integration (mobile)
- ✅ Basic events tracking

❌ **Missing:**
- ❌ Comprehensive event tracking:
  - `record_start/stop`
  - `episode_publish`
  - `undo`
  - `listen_start/complete`
  - `comment_add`
  - `follow`
  - `live_join/leave`
  - `paywall_view/convert`
- ❌ Cost monitoring dashboard
- ❌ Budget alerts (STT, CDN, Live minutes)
- ❌ Metrics: DAU/WAU, % creators, median listen time

---

### Phase 6 — Hardening (10% done)

✅ **Existing:**
- ✅ Docker setup
- ✅ Basic logging

❌ **Missing:**
- ❌ Privacy policy & content guidelines
- ❌ Automated PG backups
- ❌ R2 lifecycle (archive after 30 days)
- ❌ LiveKit 2-node setup (failover)
- ❌ Mod panel UI
- ❌ Feature flags system
- ❌ Go/No-Go checklist automation

---

## 📋 Пріоритизований план реалізації

### 🔥 Priority 1: MVP Core (2-3 тижні)

**Ціль:** Повноцінний one-tap record → publish → feed → playback флоу

#### Group 1.1: Mobile UI Core (5-7 днів)

1. ✨ **Recorder Screen** з Undo 10s banner
2. ✨ **Feed Screen** (episode cards + mini-player)
3. ✨ **Episode Detail Screen** (player + comments)
4. ✨ **Comments Screen**
5. ✨ **Topic Screen**
6. ✨ **Profile/Settings Screen**
7. ✨ **Auth Screen** (magic link flow)

#### Group 1.2: Backend Improvements (2-3 дні)

8. ✨ **PUBLIC_BY_DEFAULT=true** enforcement
9. ✨ **UNDO_SECONDS=10** proper timing
10. ✨ Better TL;DR generation (rule-based, no STT yet)
11. ✨ Topics API improvements (search, trending topics)

#### Group 1.3: Mobile Polish (2 дні)

12. ✨ Offline support (queue uploads)
13. ✨ Error states (ERR-001)
14. ✨ Loading states
15. ✨ Audio player controls (play/pause/scrub)

---

### 🔥 Priority 2: Live Experience (1 тиждень)

#### Group 2.1: Listener UI (2-3 дні)

16. ✨ **LiveListenerScreen** (повний)
17. ✨ Reactions stream UI
18. ✨ Chat panel
19. ✨ Join/Leave flow

#### Group 2.2: Live Mask (2-3 дні)

20. ✨ Client-side DSP (pitch shift real-time)
21. ✨ Fallback toggle
22. ✨ Battery monitoring
23. ✨ UI controls для mask у live

---

### 🔥 Priority 3: Monetization (1-1.5 тижні)

#### Group 3.1: STT Service (3-4 дні)

24. ✨ **Faster-Whisper service** (Docker)
25. ✨ Queue `full_stt` job
26. ✨ Transcripts storage
27. ✨ Chapters generation (semantic)
28. ✨ Free keywords (30-60s для публічних)

#### Group 3.2: RevenueCat Billing (3-4 дні)

29. ✨ **RevenueCat SDK** (iOS + Android)
30. ✨ Paywall UI (PAY-001)
31. ✨ Webhook `/v1/billing/rc/webhook`
32. ✨ Plan entitlements middleware
33. ✨ Pro features gating:
    - Full transcripts
    - Chapters
    - Search по тексту
    - Studio mask (краща якість)

---

### 🔥 Priority 4: Discovery & Retention (1 тиждень)

#### Group 4.1: Search & Trending (3 дні)

34. ✨ Search API (PG full-text search)
35. ✨ Trending scoring
36. ✨ Explore screen (mobile)
37. ✨ Search screen (mobile)

#### Group 4.2: Notifications (2-3 дні)

38. ✨ Push notifications service (FCM/APNS)
39. ✨ Notification categories
40. ✨ NTF-001 screen (mobile)
41. ✨ Settings для notifications

---

### 🔥 Priority 5: Advanced Features (2 тижні)

#### Group 5.1: Live Translate (1 тиждень)

42. ✨ ASR streaming service (Google/Azure Speech-to-Text)
43. ✨ MT service (Google/Azure Translate)
44. ✨ TTS service (Google/Azure/ElevenLabs)
45. ✨ Translation Router
46. ✨ Captions WebSocket
47. ✨ Dub audio tracks (LiveKit)
48. ✨ Pro gating
49. ✨ TRNS-H-001 screen (host controls)
50. ✨ TRNS-L-001 UI (listener CC + language)
51. ✨ Budget guards

#### Group 5.2: Analytics & Monitoring (3-4 дні)

52. ✨ Comprehensive PostHog events
53. ✨ Cost monitoring endpoint
54. ✨ Grafana dashboards (продуктові + витрати)
55. ✨ Budget alerts (Slack/email)

---

### 🔥 Priority 6: Production Ready (1 тиждень)

#### Group 6.1: Hardening (3 дні)

56. ✨ Privacy policy + TOS
57. ✨ Automated PG backups
58. ✨ R2 lifecycle rules
59. ✨ Feature flags system
60. ✨ Mod panel UI

#### Group 6.2: DevOps (2-3 дні)

61. ✨ CI/CD (GitHub Actions)
62. ✨ Security scans (Snyk/Trivy)
63. ✨ LiveKit 2-node setup
64. ✨ Health checks improvements
65. ✨ Go/No-Go automation

---

## 📊 Прогрес по фазах

| Phase | Прогрес | Пріоритет | Час |
|-------|---------|-----------|-----|
| **Phase 0** (Infrastructure) | 90% ✅ | ✅ Done | - |
| **Phase 1** (Capture & Feed) | 70% 🟡 | 🔥 P1 | 1-1.5 тижні |
| **Phase 1.5** (Moderation) | 60% 🟡 | 🟢 P6 | 2 дні |
| **Phase 2** (Livecast) | 80% ✅ | 🔥 P2 | 3-4 дні |
| **Phase 2.5** (Live Mask) | 70% 🟡 | 🔥 P2 | 2-3 дні |
| **Phase 2.7** (Live Translate) | 0% ❌ | 🟡 P5 | 1 тиждень |
| **Phase 3** (Pro & Billing) | 5% ❌ | 🔥 P3 | 1-1.5 тижні |
| **Phase 4** (Discovery) | 0% ❌ | 🔥 P4 | 1 тиждень |
| **Phase 5** (Analytics) | 20% 🟡 | 🟡 P5 | 3-4 дні |
| **Phase 6** (Hardening) | 10% ❌ | 🟢 P6 | 1 тиждень |

**Загальний прогрес:** ~45% ✅

---

## 🎯 Рекомендована послідовність

### Sprint 1 (тиждень 1-2): MVP Core

```
Priority 1.1 (Mobile UI) → Priority 1.2 (Backend) → Priority 1.3 (Polish)
```

**Deliverable:** Повний флоу record → publish → feed → playback

---

### Sprint 2 (тиждень 3): Live Experience

```
Priority 2.1 (Listener UI) → Priority 2.2 (Live Mask)
```

**Deliverable:** Host + Listener live sessions з mask

---

### Sprint 3 (тиждень 4-5): Monetization

```
Priority 3.1 (STT) → Priority 3.2 (RevenueCat)
```

**Deliverable:** Pro plan з транскриптами та billing

---

### Sprint 4 (тиждень 6): Discovery

```
Priority 4.1 (Search) → Priority 4.2 (Notifications)
```

**Deliverable:** Search, trending, push notifications

---

### Sprint 5-6 (тиждень 7-8): Advanced + Polish

```
Priority 5 (Live Translate + Analytics) → Priority 6 (Production Ready)
```

**Deliverable:** Live translate (Pro), monitoring, production hardening

---

## 🚀 Наступні кроки

**Я готовий почати реалізацію!**

Оберіть один з варіантів:

### Варіант A: Швидкий MVP (рекомендовано)
Почати з **Priority 1.1** (Mobile UI Core) — це найбільш видимі результати

### Варіант B: Backend-First
Почати з **Priority 3.1** (STT Service) — щоб мати реальні transcripts

### Варіант C: Live-First
Почати з **Priority 2** (Live Experience) — завершити live функціонал

### Варіант D: Ваш порядок
Скажіть, з чого хочете почати, і я розіб'ю на мікро-таски по 15-30 хв

---

**Що обираєте?** Я готовий створювати код прямо зараз! 🚀

