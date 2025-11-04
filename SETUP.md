# AmunX — Повна інструкція запуску та тестування

Ця інструкція описує, як підняти весь стек (backend, worker, LiveKit, databases) і вручну протестувати сценарій від створення live-сесії до появи епізоду у фіді.

---

## 📋 Передумови

### Необхідне програмне забезпечення

1. **Docker Engine** (версія 20.10+) та **Docker Compose V2**
   - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - macOS: Docker Desktop
   - Linux: Docker Engine + docker-compose-plugin

2. **Node.js** (версія 18+ або 20+) та **npm**
   - Для мобільного клієнту

3. **Git** (для клонування репозиторію)

### Перевірка встановлення

```bash
docker --version          # Docker version 24.0+
docker compose version    # Docker Compose version v2.x
node --version           # v18.x або v20.x
npm --version            # 9.x або 10.x
```

---

## 🚀 Крок 1: Підготовка конфігурації

### 1.1. Створення .env файлу для backend

Backend потребує змінних оточення. Створіть файл `backend/.env` (або скопіюйте з прикладу):

```bash
# На Windows (PowerShell)
Copy-Item backend\.env.example backend\.env -ErrorAction SilentlyContinue

# На macOS/Linux
cp backend/.env.example backend/.env 2>/dev/null || true
```

**Мінімальна конфігурація для локальної розробки** (`backend/.env`):

```env
# JWT Secrets (для локальної розробки можна залишити defaults)
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret

# LiveKit (значення з docker-compose.yml і livekit.yaml)
LIVEKIT_URL=http://livekit:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret

# Feature flags
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true
```

> ⚠️ **Важливо**: Для production змініть секрети на надійні випадкові значення!

### 1.2. Створення .env файлу для mobile

Мобільний клієнт потребує URL бекенду:

```bash
# На Windows (PowerShell)
Copy-Item mobile\.env.example mobile\.env -ErrorAction SilentlyContinue

# На macOS/Linux
cp mobile/.env.example mobile/.env 2>/dev/null || true
```

Відредагуйте `mobile/.env` в залежності від вашої платформи:

```env
# Для iOS Simulator на macOS:
API_BASE_URL=http://localhost:8080

# Для Android Emulator на Windows/Linux:
# API_BASE_URL=http://10.0.2.2:8080

# Для реального телефону (замініть на IP вашого комп'ютера в локальній мережі):
# API_BASE_URL=http://192.168.1.100:8080
```

> 💡 **Порада**: Щоб дізнатись IP вашого комп'ютера:
> - Windows: `ipconfig` → шукайте IPv4 Address
> - macOS/Linux: `ifconfig` або `ip addr`

### 1.3. Перевірка вільності портів

Переконайтесь, що наступні порти вільні:

- **8080** — Backend API
- **5432** — PostgreSQL
- **6379** — Redis
- **7880, 7881** — LiveKit
- **3000** — Grafana
- **3100** — Loki

**Перевірка зайнятих портів:**

```bash
# Windows (PowerShell)
netstat -ano | findstr "8080"

# macOS/Linux
lsof -i :8080
```

---

## 🐳 Крок 2: Запуск Docker Compose

### 2.1. Старт усіх сервісів

З кореня репозиторію виконайте:

```bash
docker compose up -d
```

Це підніме:
- **postgres** — база даних
- **redis** — черга задач
- **livekit** — WebRTC сервер для live-стрімінгу
- **api** — HTTP API (Go)
- **worker** — обробник аудіо (Go)
- **loki** — збір логів
- **promtail** — відправка логів
- **grafana** — візуалізація (опційно)

**Перевірка статусу:**

```bash
docker compose ps
```

Очікуваний результат — всі сервіси мають статус `Up` або `running`.

**Перегляд логів в реальному часі:**

```bash
docker compose logs -f api worker livekit
```

---

## 🗄️ Крок 3: Запуск міграцій БД

Після старту контейнерів, один раз виконайте SQL міграції.

### Варіант A: Використовуючи готові скрипти (рекомендовано)

**На Windows (PowerShell):**

```powershell
.\migrate.ps1 up
```

**На macOS/Linux:**

```bash
chmod +x migrate.sh
./migrate.sh up
```

### Варіант B: Вручну через Docker

```bash
docker run --rm \
  --network amunx_default \
  -v "$(pwd)/backend/db/migrations:/migrations" \
  migrate/migrate:latest \
  -path=/migrations \
  -database "postgres://postgres:postgres@postgres:5432/amunx?sslmode=disable" \
  up
```

**На Windows (PowerShell) замість `$(pwd)` використовуйте:**

```powershell
docker run --rm `
  --network amunx_default `
  -v "${PWD}\backend\db\migrations:/migrations" `
  migrate/migrate:latest `
  -path=/migrations `
  -database "postgres://postgres:postgres@postgres:5432/amunx?sslmode=disable" `
  up
```

**Очікуваний результат:**

```
Applying migration 0001_init.up.sql
Applying migration 0002_reports_add_reporter.up.sql
...
Applying migration 0005_live_sessions_mask.up.sql
Migration successful
```

---

## 🏥 Крок 4: Перевірка здоров'я сервісів

### 4.1. API Health Check

```bash
curl http://localhost:8080/healthz
```

**Очікувана відповідь:**
```json
{"status":"ok"}
```

### 4.2. API Readiness Check

```bash
curl http://localhost:8080/readyz
```

Перевіряє з'єднання з Postgres та Redis.

**Очікувана відповідь:**
```json
{"database":"ok","redis":"ok"}
```

### 4.3. LiveKit Health Check

```bash
curl http://localhost:7880/
```

**Очікувана відповідь:** HTML сторінка LiveKit або статус 200 OK.

### 4.4. Перегляд логів

```bash
docker compose logs -f api worker
```

Переконайтесь, що немає критичних помилок (ERROR level).

---

## 📱 Крок 5: Запуск мобільного клієнта

### 5.1. Встановлення залежностей

```bash
cd mobile
npm install
```

### 5.2. Запуск Expo Dev Server

```bash
npm run expo:start
```

або

```bash
npx expo start
```

### 5.3. Підключення пристрою

Expo покаже QR-код та інструкції. Варіанти:

1. **iOS Simulator** (тільки macOS):
   - Натисніть `i` в терміналі

2. **Android Emulator**:
   - Натисніть `a` в терміналі
   - Або запустіть емулятор з Android Studio

3. **Реальний пристрій**:
   - Встановіть Expo Go з App Store / Google Play
   - Скануйте QR-код

> ⚠️ **Важливо**: Для реального пристрою переконайтесь, що `API_BASE_URL` у `mobile/.env` вказує на IP вашого комп'ютера в локальній мережі (не `localhost`).

---

## 🎙️ Крок 6: Smoke-тест live сценарію

### 6.1. Реєстрація / Вхід

1. Відкрийте мобільний застосунок
2. Зареєструйтесь або увійдіть (створіть тестовий обліковий запис)

### 6.2. Створення live-сесії

1. Перейдіть на екран **"Host Live"** (LiveHostScreen)
2. Заповніть поля (опційно):
   - **Title**: "Test live session"
   - **Topic ID**: залиште порожнім або вкажіть існуючий UUID
3. Виберіть **Mask** опцію:
   - **None** — без обробки голосу
   - **Basic** — базова маскіровка (pitch shift)
   - **Studio** — студійна обробка (більш агресивна)
4. Натисніть **"Start Live"**

**Очікуваний результат:**
- З'явиться інформація про сесію (ID, Room, Token, URL)
- Статус: "Connecting to LiveKit room..."

### 6.3. Підключення до аудіо

1. Натисніть **"Join Audio"**
2. Дозвольте доступ до мікрофону (якщо запитає система)

**Очікуваний результат:**
- Статус змінюється на: **"Streaming live audio..."**
- Індикатор показує кількість слухачів (спочатку 0)

### 6.4. Тестування реакцій та чату (опційно)

- Відправте кілька реакцій (емодзі)
- Напишіть повідомлення в чаті
- Перевірте, що вони відображаються в Event Log

### 6.5. Завершення live-сесії

1. Введіть **Recording Key** (опційно):
   ```
   episodes/test-recording/processed.opus
   ```
   > 💡 Якщо залишити порожнім, бекенд використає ключ з БД або створить автоматично

2. Введіть **Duration (seconds)** (опційно):
   ```
   120
   ```

3. Натисніть **"End Live"** (червона кнопка)

**Очікуваний результат:**
- Event log показує: "Live session ended and queued for processing."
- Сесія завершується, статус змінюється на "Not connected"

### 6.6. Перевірка обробки у worker

Відкрийте логи worker:

```bash
docker compose logs -f worker
```

**Очікувані події:**

1. Worker отримує задачу `finalize_live`:
   ```
   {"level":"info","message":"finalize loop claimed 1 jobs"}
   {"level":"info","session_id":"...","message":"handling finalize live"}
   ```

2. Створюється епізод:
   ```
   {"level":"info","episode_id":"...","message":"episode created from live session"}
   ```

3. Worker отримує задачу `process_audio`:
   ```
   {"level":"info","message":"processor loop claimed 1 jobs"}
   {"level":"info","episode_id":"...","message":"processing audio"}
   ```

4. Завершення обробки:
   ```
   {"level":"info","episode_id":"...","message":"episode status updated to public"}
   ```

Обробка може зайняти **10-60 секунд** в залежності від тривалості запису та потужності машини.

### 6.7. Перевірка епізоду у фіді

1. Поверніться на **Home Screen** (Feed)
2. Потягніть список вниз (pull-to-refresh) або почекайте автооновлення (~10 сек)

**Очікуваний результат:**
- У фіді з'являється новий епізод з бейджем **"Live replay"** (is_live: true)
- Title: заголовок, який ви ввели або "Live session"
- Metadata: duration, mask type

### 6.8. Відтворення епізоду

1. Тапніть на епізод → відкриється **EpisodeScreen**
2. Натисніть **Play**

**Очікуваний результат:**
- Аудіо програється
- Кнопки **Play / Pause / Stop** працюють
- Відображаються ключові слова (keywords) та настрій (mood) — згенеровані placeholder'и
- Якщо був застосований mask, звук має відрізнятись від оригіналу

### 6.9. Перевірка додаткових функцій (опційно)

- **Коментарі**: додайте коментар до епізоду
- **Репорт**: створіть report (модерація)
- **Профіль**: перегляньте епізоди автора

---

## 🔍 Крок 7: Моніторинг та діагностика

### 7.1. Grafana (опційно)

Відкрийте http://localhost:3000

- **Login**: admin / admin (за замовчуванням)
- Налаштуйте дашборди для перегляду логів з Loki

### 7.2. Перегляд даних у БД

```bash
docker compose exec postgres psql -U postgres -d amunx
```

**Корисні запити:**

```sql
-- Перегляд live-сесій
SELECT id, host_id, title, started_at, ended_at, mask FROM live_sessions ORDER BY started_at DESC LIMIT 10;

-- Перегляд епізодів
SELECT id, author_id, title, status, is_live, created_at FROM episodes ORDER BY created_at DESC LIMIT 10;

-- Перегляд черги задач (Redis)
-- Вийдіть з psql (\q) та виконайте:
```

```bash
docker compose exec redis redis-cli

# У redis-cli:
XLEN process_audio
XLEN finalize_live
```

---

## 🛑 Крок 8: Зупинка стека

### Зупинка без видалення даних

```bash
docker compose down
```

Це зупинить контейнери, але збереже дані у volumes (БД, Redis).

### Повне видалення (включаючи дані)

```bash
docker compose down -v
```

> ⚠️ **Увага**: Це видалить усі дані з PostgreSQL та Redis!

---

## 🐛 Типові проблеми та рішення

### Проблема: Порт вже зайнятий

**Помилка:**
```
Error starting userland proxy: listen tcp 0.0.0.0:8080: bind: address already in use
```

**Рішення:**

1. Знайдіть процес, що використовує порт:

   **Windows:**
   ```powershell
   netstat -ano | findstr "8080"
   taskkill /PID <PID> /F
   ```

   **macOS/Linux:**
   ```bash
   lsof -ti :8080 | xargs kill -9
   ```

2. Або змініть порт у `docker-compose.yml`:
   ```yaml
   ports:
     - "8081:8080"  # зовнішній порт 8081
   ```

### Проблема: Міграції не застосовуються

**Помилка:**
```
error: pq: SSL is not enabled on the server
```

**Рішення:** Переконайтесь, що в DB_URL є `?sslmode=disable`.

---

**Помилка:**
```
error: network amunx_default not found
```

**Рішення:** Запустіть `docker compose up -d` перед запуском міграцій, або використовуйте:

```bash
docker network create amunx_default
```

### Проблема: Мобільний клієнт не може з'єднатися з API

**Симптоми:**
- Помилка "Network request failed"
- Timeout при спробі логіну

**Рішення:**

1. **Android Emulator на Windows/Linux:**
   - Використовуйте `API_BASE_URL=http://10.0.2.2:8080`

2. **Реальний пристрій:**
   - Переконайтесь, що пристрій і комп'ютер у одній WiFi мережі
   - Використовуйте IP комп'ютера (не localhost):
     ```env
     API_BASE_URL=http://192.168.1.100:8080
     ```
   - Вимкніть firewall або додайте виключення для порту 8080

3. **Перевірте доступність API:**
   ```bash
   # На комп'ютері:
   curl http://localhost:8080/healthz
   
   # З телефону (через браузер):
   http://<YOUR_IP>:8080/healthz
   ```

### Проблема: LiveKit не підключається

**Симптоми:**
- "Connecting..." без переходу до "Streaming live audio..."
- Помилки в логах про connection timeout

**Рішення:**

1. Перевірте health LiveKit:
   ```bash
   curl http://localhost:7880/
   docker compose logs livekit
   ```

2. Переконайтесь, що порти 7880 та 7881 відкриті

3. Для реального пристрою може знадобитись TURN сервер (складніша конфігурація)

### Проблема: Worker не обробляє аудіо

**Симптоми:**
- Епізод залишається у статусі `pending_public`
- Немає логів в worker

**Рішення:**

1. Перевірте логи worker:
   ```bash
   docker compose logs worker
   ```

2. Переконайтесь, що задачі є в Redis:
   ```bash
   docker compose exec redis redis-cli
   XLEN process_audio
   ```

3. Перевірте, чи встановлений FFmpeg у worker контейнері:
   ```bash
   docker compose exec worker ffmpeg -version
   ```

### Проблема: Obrazy не скачуються

**Помилка:**
```
failed to pull image "livekit/livekit-server:latest"
```

**Рішення:**

1. Переконайтесь, що є інтернет з'єднання
2. Спробуйте вручну:
   ```bash
   docker pull livekit/livekit-server:latest
   docker pull migrate/migrate:latest
   docker pull postgres:16-alpine
   docker pull redis:7-alpine
   ```

3. Для corporate network з proxy додайте налаштування Docker proxy

---

## 📚 Додаткова інформація

### Структура проекту

```
AmunX/
├── backend/          # Go backend
│   ├── cmd/          # Entry points (api, worker)
│   ├── internal/     # Business logic
│   ├── db/
│   │   └── migrations/  # SQL migrations
│   └── Dockerfile, Dockerfile.worker
├── mobile/           # React Native (Expo)
│   ├── src/
│   │   ├── screens/  # UI screens
│   │   ├── api/      # API client
│   │   └── utils/
│   └── package.json
├── livekit/
│   └── livekit.yaml  # LiveKit config
├── docker-compose.yml
├── migrate.sh        # Migration helper (bash)
├── migrate.ps1       # Migration helper (PowerShell)
└── SETUP.md          # Ця інструкція
```

### Корисні команди

```bash
# Перезапуск окремого сервісу
docker compose restart api

# Rebuild образів після змін у коді
docker compose up -d --build

# Очистка всього (images, volumes, networks)
docker compose down -v --rmi all

# Перегляд логів окремого сервісу
docker compose logs -f worker

# Вхід у контейнер для дебагу
docker compose exec api sh
docker compose exec worker sh

# Перевірка використання ресурсів
docker stats
```

### Environment variables (повний список)

Див. `backend/.env.example` для детального опису всіх змінних.

---

## 🎯 Автоматизація smoke-тестів

Для повторних тестів можна створити shell-скрипт, який:

1. Піднімає стек (`docker compose up -d`)
2. Чекає readyz endpoint
3. Виконує HTTP-виклики:
   - `POST /v1/auth/register` — створює тестового користувача
   - `POST /v1/live/sessions` — стартує live
   - `POST /v1/live/sessions/{id}/end` — завершує
   - `GET /v1/episodes` — чекає появу епізоду

**Приклад (bash):**

```bash
#!/bin/bash
# smoke-test.sh

API_BASE="http://localhost:8080"

# 1. Wait for API
until curl -sf "$API_BASE/healthz" > /dev/null; do
  echo "Waiting for API..."
  sleep 2
done

# 2. Register user
USER_EMAIL="test_$(date +%s)@example.com"
USER_PASS="testpass123"

REGISTER_RESPONSE=$(curl -sf -X POST "$API_BASE/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}")

TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.access_token')

# 3. Start live session
LIVE_RESPONSE=$(curl -sf -X POST "$API_BASE/v1/live/sessions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Smoke test","mask":"basic"}')

SESSION_ID=$(echo "$LIVE_RESPONSE" | jq -r '.session.id')
echo "Started live session: $SESSION_ID"

# 4. Wait a bit (simulate streaming)
sleep 10

# 5. End session
curl -sf -X POST "$API_BASE/v1/live/sessions/$SESSION_ID/end" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"duration_sec":10}'

echo "Ended live session"

# 6. Wait for processing
echo "Waiting for episode to appear in feed..."
for i in {1..30}; do
  EPISODES=$(curl -sf "$API_BASE/v1/episodes" | jq -r '.items | length')
  if [ "$EPISODES" -gt 0 ]; then
    echo "Episode found in feed!"
    exit 0
  fi
  sleep 2
done

echo "Episode did not appear in feed after 60 seconds"
exit 1
```

> **Примітка:** Живий аудіопотік все одно зручніше перевіряти через мобільний клієнт.

---

## 📞 Підтримка та контакти

Якщо виникли проблеми:

1. Перевірте логи: `docker compose logs -f`
2. Перевірте статус сервісів: `docker compose ps`
3. Перевірте порти: `netstat` або `lsof`
4. Створіть issue у репозиторії з логами та описом проблеми

---

**Успішного тестування! 🚀**

