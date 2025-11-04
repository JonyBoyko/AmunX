# Налаштування змінних оточення (.env файли)

Цей файл містить шаблони для створення `.env` файлів, необхідних для роботи проекту.

---

## 📝 Backend Environment (`backend/.env`)

Створіть файл `backend/.env` з наступним вмістом:

```env
# Application Environment
ENVIRONMENT=development

# HTTP Server
HTTP_HOST=0.0.0.0
HTTP_PORT=8080

# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable

# Redis
REDIS_ADDRESS=localhost:6379

# JWT Secrets (ОБОВ'ЯЗКОВО ЗМІНІТЬ ДЛЯ PRODUCTION!)
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret

# LiveKit Configuration
# Для локальної розробки з Docker Compose:
LIVEKIT_URL=http://livekit:7880
# Для мобільного клієнта, що підключається ззовні Docker:
# LIVEKIT_URL=http://localhost:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret

# Storage & CDN
# Залиште порожнім для локальної розробки (використовує відносні шляхи)
# Для production вкажіть URL вашого CDN (наприклад, https://cdn.example.com)
CDN_BASE=

# Object Storage (S3/MinIO/тощо) - опційно
# STORAGE_ENDPOINT=
# STORAGE_ACCESS_KEY=
# STORAGE_SECRET_KEY=
# STORAGE_BUCKET=amunx
# STORAGE_REGION=us-east-1
# STORAGE_USE_SSL=true

# Feature Flags
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true

# Content Policy
PUBLIC_BY_DEFAULT=false
UNDO_SECONDS=300

# Worker Configuration
MEDIA_PATH=/tmp/media
MODERATION_KEYWORDS=hate,abuse,violence,kill,weapon,drugs,terror,self-harm

# Logging
LOG_LEVEL=info
```

---

## 📱 Mobile Environment (`mobile/.env`)

Створіть файл `mobile/.env` з наступним вмістом (оберіть відповідний варіант):

### Для iOS Simulator / Android Emulator на macOS:

```env
API_BASE_URL=http://localhost:8080
```

### Для Android Emulator на Windows/Linux:

```env
API_BASE_URL=http://10.0.2.2:8080
```

### Для реального пристрою (на тій же WiFi мережі):

```env
# Замініть 192.168.1.100 на IP вашого комп'ютера
API_BASE_URL=http://192.168.1.100:8080
```

**Як дізнатись IP вашого комп'ютера:**

- **Windows (PowerShell):**
  ```powershell
  ipconfig
  # Шукайте "IPv4 Address" у розділі вашого WiFi адаптера
  ```

- **macOS:**
  ```bash
  ifconfig | grep "inet " | grep -v 127.0.0.1
  ```

- **Linux:**
  ```bash
  ip addr show | grep "inet " | grep -v 127.0.0.1
  ```

### Опційні налаштування (analytics):

```env
# Mixpanel (опційно)
# MIXPANEL_TOKEN=your_mixpanel_token

# Sentry (опційно)
# SENTRY_DSN=your_sentry_dsn
```

---

## 🚀 Швидке створення

### На Windows (PowerShell):

```powershell
# Backend
@"
ENVIRONMENT=development
HTTP_HOST=0.0.0.0
HTTP_PORT=8080
DATABASE_URL=postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable
REDIS_ADDRESS=localhost:6379
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret
LIVEKIT_URL=http://livekit:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret
CDN_BASE=
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true
PUBLIC_BY_DEFAULT=false
UNDO_SECONDS=300
MEDIA_PATH=/tmp/media
MODERATION_KEYWORDS=hate,abuse,violence,kill,weapon,drugs,terror,self-harm
LOG_LEVEL=info
"@ | Out-File -FilePath backend\.env -Encoding utf8

# Mobile (для Android Emulator на Windows)
@"
API_BASE_URL=http://10.0.2.2:8080
"@ | Out-File -FilePath mobile\.env -Encoding utf8

Write-Host "✅ .env файли створено!" -ForegroundColor Green
```

### На macOS / Linux (Bash):

```bash
# Backend
cat > backend/.env << 'EOF'
ENVIRONMENT=development
HTTP_HOST=0.0.0.0
HTTP_PORT=8080
DATABASE_URL=postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable
REDIS_ADDRESS=localhost:6379
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret
LIVEKIT_URL=http://livekit:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret
CDN_BASE=
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true
PUBLIC_BY_DEFAULT=false
UNDO_SECONDS=300
MEDIA_PATH=/tmp/media
MODERATION_KEYWORDS=hate,abuse,violence,kill,weapon,drugs,terror,self-harm
LOG_LEVEL=info
EOF

# Mobile
cat > mobile/.env << 'EOF'
API_BASE_URL=http://localhost:8080
EOF

echo "✅ .env файли створено!"
```

---

## ⚠️ Важливі примітки

1. **Ніколи не commitте `.env` файли в Git!**
   - Вони вже додані в `.gitignore`
   - Для production використовуйте секрети з CI/CD або secret managers

2. **JWT секрети:**
   - Для production згенеруйте надійні випадкові значення:
     ```bash
     # Генерація випадкового секрету (32 байти)
     openssl rand -base64 32
     ```

3. **LiveKit URL для мобільного клієнта:**
   - Мобільний клієнт отримує `url` від API у відповіді `/v1/live/sessions`
   - API використовує `LIVEKIT_URL` з свого `.env`
   - Для локальної розробки це має бути `http://livekit:7880` (внутрішня Docker мережа)
   - Реальний пристрій матиме доступ до LiveKit через API proxy або публічний URL

4. **Storage:**
   - Без налаштування S3/MinIO файли не зберігаються довгостроково
   - Для production обов'язково налаштуйте Object Storage

---

## 🔐 Production налаштування

Для production середовища:

1. **Змініть всі секрети:**
   - `JWT_ACCESS_SECRET`
   - `JWT_REFRESH_SECRET`
   - `LIVEKIT_API_KEY`
   - `LIVEKIT_API_SECRET`
   - Паролі БД

2. **Налаштуйте HTTPS:**
   - Використовуйте reverse proxy (nginx, Traefik, Caddy)
   - Додайте SSL сертифікати
   - Змініть `LIVEKIT_URL` на `https://...`

3. **Налаштуйте Object Storage:**
   - AWS S3, Google Cloud Storage, або MinIO
   - Додайте credentials у змінні `STORAGE_*`

4. **Змініть база даних паролі:**
   - У `docker-compose.yml` → `POSTGRES_PASSWORD`
   - У `DATABASE_URL`

5. **Налаштуйте моніторинг:**
   - Sentry для error tracking
   - Grafana + Loki для логів
   - Prometheus для метрик

---

**Готово! Тепер ви можете запускати проект згідно [SETUP.md](./SETUP.md)**

