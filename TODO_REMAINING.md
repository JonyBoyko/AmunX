# Залишилось реалізувати

## 🎯 Пріоритетні функції (UI + Backend інтеграція)

### 1. Emoji-реакції з анімаціями та бейджами популярності
**Статус**: UI частково реалізовано (статичні реакції в `EpisodeCard`, `EpisodeDetailScreen`), але:
- ❌ Немає анімацій при натисканні
- ❌ Немає бейджів популярності (наприклад, "🔥 Топ реакція тижня")
- ❌ Backend endpoint `/episodes/{id}/react` існує, але не інтегрований з Flutter
- ❌ Немає синхронізації реакцій між клієнтом та сервером
- ❌ Немає відображення загальної кількості реакцій кожного типу

**Файли для оновлення**:
- `mobile/lib/presentation/widgets/episode_card.dart` - додати анімації та бейджи
- `mobile/lib/presentation/screens/episode_detail_screen.dart` - інтегрувати з API
- `mobile/lib/data/api/api_client.dart` - додати методи для reactions
- `mobile/lib/presentation/providers/reaction_provider.dart` - новий провайдер для управління реакціями

---

### 2. Backend інтеграція для Follow/Unfollow
**Статус**: UI реалізовано (`FollowButton`, `AuthorDirectoryNotifier`), але:
- ❌ Немає backend endpoint для follow/unfollow
- ❌ Немає синхронізації з сервером
- ❌ Follow статус зберігається тільки локально

**Файли для створення/оновлення**:
- `backend/internal/http/follow_handlers.go` - новий файл з endpoints
- `backend/db/migrations/` - міграція для таблиці `follows` (якщо ще немає)
- `mobile/lib/data/api/api_client.dart` - додати методи follow/unfollow
- `mobile/lib/presentation/providers/author_directory_provider.dart` - інтегрувати з API

---

### 3. LiveKit інтеграція для Live Rooms
**Статус**: UI реалізовано (`LiveHostScreen`, `LiveListenerScreen`), але:
- ❌ Немає підключення до LiveKit SDK
- ❌ Немає реального стримінгу аудіо
- ❌ Немає синхронізації listener count з LiveKit
- ❌ Немає реальних реакцій у live сесіях
- ❌ Немає live transcript (ASR + MT + TTS)

**Файли для створення/оновлення**:
- `mobile/lib/presentation/services/livekit_service.dart` - новий сервіс для LiveKit
- `mobile/pubspec.yaml` - додати `livekit_client` пакет
- `mobile/lib/presentation/screens/live_host_screen.dart` - інтегрувати LiveKit
- `mobile/lib/presentation/screens/live_listener_screen.dart` - інтегрувати LiveKit
- `backend/internal/http/live_handlers.go` - перевірити та доопрацювати endpoints

---

### 4. Backend інтеграція для Feed Filters
**Статус**: Client-side фільтри реалізовано, але:
- ⚠️ Backend отримує query parameters, але не всі фільтри повністю обробляються
- ❌ Немає реального ranking для "recommended" та "trending"
- ❌ Немає геолокаційної фільтрації для "nearby"

**Файли для оновлення**:
- `backend/internal/http/episode_handlers.go` - покращити `listPublicEpisodes` для фільтрів
- `backend/internal/http/feed_handlers.go` - якщо є окремий feed handler

---

## 🔧 Backend функціонал (частково реалізовано)

### 5. Audio Pipeline (S3, Worker Processing)
**Статус**: Dev upload працює локально, але:
- ❌ Немає S3 інтеграції
- ❌ Немає presigned URLs для завантаження
- ❌ Worker не обробляє аудіо (transcription, summarization, clips)
- ❌ Немає `/v1/episodes/finalize` endpoint

**Файли для оновлення**:
- `backend/internal/http/uploads_handlers.go` - реалізувати presigned URLs
- `backend/internal/worker/pipeline.go` - завершити обробку аудіо
- `backend/internal/worker/audiogram.go` - завершити генерацію audiograms

---

### 6. Authentication (Magic Links)
**Статус**: Dev login працює, але:
- ❌ Немає реальних magic link emails
- ❌ Немає refresh token rotation
- ❌ Немає email verification

**Файли для оновлення**:
- `backend/internal/http/auth_handlers.go` - реалізувати magic links
- `backend/internal/integrations/email.go` - якщо є, додати відправку emails

---

### 7. Podcast RSS функціонал
**Статус**: Endpoints існують, але:
- ❌ `CreatePodcastShow` - не реалізовано
- ❌ `AddPodcastEpisode` - не реалізовано
- ❌ `GetPodcastRSS` - частково реалізовано (TODO коментарі)

**Файли для оновлення**:
- `backend/internal/http/podcast_rss_handlers.go` - завершити реалізацію

---

### 8. Circles (Smart Circles)
**Статус**: Endpoints існують, але:
- ❌ Всі handlers мають TODO коментарі
- ❌ Немає UI в Flutter
- ❌ Немає інтеграції з feed

**Файли для створення/оновлення**:
- `backend/internal/http/circles_handlers.go` - завершити реалізацію
- `mobile/lib/presentation/screens/circles_screen.dart` - новий екран
- `mobile/lib/presentation/screens/circle_detail_screen.dart` - новий екран

---

### 9. Search функціонал
**Статус**: Handler існує, але:
- ❌ Hybrid search не реалізовано
- ❌ Немає UI в Flutter

**Файли для створення/оновлення**:
- `backend/internal/http/search_handlers.go` - реалізувати hybrid search
- `mobile/lib/presentation/screens/search_screen.dart` - новий екран

---

### 10. Explore Feed з Ranking
**Статус**: Handler існує, але:
- ❌ Всі фільтри та ranking не реалізовано
- ❌ Немає UI в Flutter

**Файли для оновлення**:
- `backend/internal/http/explore_handlers.go` - реалізувати ranking та фільтри
- `mobile/lib/presentation/screens/explore_screen.dart` - новий екран (якщо потрібно)

---

## 📱 Mobile UI покращення

### 11. Paywall Screen доопрацювання
**Статус**: Екран існує, але:
- ❌ Немає реальної інтеграції з payment provider
- ❌ Немає перевірки Pro статусу після покупки

**Файли для оновлення**:
- `mobile/lib/presentation/screens/paywall_screen.dart` - додати payment integration

---

### 12. Comments Screen доопрацювання
**Статус**: UI реалізовано, але:
- ❌ Немає backend інтеграції (використовується mock data)
- ❌ Немає reply до коментарів
- ❌ Немає reactions на коментарі

**Файли для оновлення**:
- `mobile/lib/presentation/screens/comments_screen.dart` - інтегрувати з API
- `mobile/lib/data/api/api_client.dart` - перевірити методи для comments

---

### 13. Profile Screen доопрацювання
**Статус**: UI реалізовано, але:
- ❌ Немає редагування профілю
- ❌ Немає налаштувань профілю
- ❌ Немає статистики (plays, reactions, etc.)

**Файли для оновлення**:
- `mobile/lib/presentation/screens/profile_screen.dart` - додати редагування
- `mobile/lib/presentation/screens/settings_screen.dart` - додати налаштування

---

## 🧪 Тести

### 14. Розширення тестового покриття
**Статус**: Базові тести є, але:
- ❌ Немає тестів для нових провайдерів (reactions, live rooms)
- ❌ Немає integration тестів для feed filters
- ❌ Немає тестів для follow/unfollow логіки

**Файли для створення**:
- `mobile/test/reaction_provider_test.dart`
- `mobile/test/feed_filter_provider_test.dart`
- `mobile/integration_test/feed_filters_test.dart`
- `mobile/integration_test/follow_test.dart`

---

## 📊 Production-ready задачі

### 15. Content Moderation
- ❌ Немає автоматичної модерації контенту
- ❌ Немає reporting функціоналу

### 16. Analytics & Telemetry
- ❌ Немає tracking подій (plays, reactions, shares)
- ❌ Немає інтеграції з analytics сервісами

### 17. Push Notifications (реальна реалізація)
**Статус**: Stub існує, але:
- ❌ Немає реальної інтеграції з FCM/APNS
- ❌ Немає налаштувань для користувачів

**Файли для оновлення**:
- `mobile/lib/presentation/services/live_notification_service.dart` - реалізувати реальні push
- `mobile/lib/presentation/screens/settings_screen.dart` - додати налаштування notifications

---

## 📝 Резюме

**Найпріоритетніші задачі** (для завершення MVP):
1. ✅ Emoji-реакції з анімаціями та бейджами (UI + Backend інтеграція)
2. ✅ Follow/Unfollow backend інтеграція
3. ✅ LiveKit інтеграція для live rooms
4. ✅ Feed filters backend доопрацювання
5. ✅ Comments backend інтеграція

**Середній пріоритет**:
6. Audio pipeline (S3, worker)
7. Authentication (magic links)
8. Paywall payment integration
9. Profile editing

**Низький пріоритет** (можна після MVP):
10. Circles UI
11. Search UI
12. Explore feed
13. Content moderation
14. Analytics






