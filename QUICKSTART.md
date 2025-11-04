# 🚀 AmunX — Швидкий старт

Мінімальна інструкція для швидкого запуску проекту.

---

## ⚡ За 5 хвилин до запущеного стеку

### 1. Клонуйте репозиторій (якщо ще не зробили)

```bash
git clone <repository-url>
cd AmunX
```

### 2. Створіть .env файли

**На Windows (PowerShell):**

```powershell
# Backend .env
@"
ENVIRONMENT=development
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret
LIVEKIT_URL=http://livekit:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true
"@ | Out-File -FilePath backend\.env -Encoding utf8

# Mobile .env (для Android Emulator)
@"
API_BASE_URL=http://10.0.2.2:8080
"@ | Out-File -FilePath mobile\.env -Encoding utf8
```

**На macOS/Linux:**

```bash
# Backend .env
cat > backend/.env << 'EOF'
ENVIRONMENT=development
JWT_ACCESS_SECRET=dev-secret-change-in-production
JWT_REFRESH_SECRET=dev-refresh-secret
LIVEKIT_URL=http://livekit:7880
LIVEKIT_API_KEY=demo
LIVEKIT_API_SECRET=supersecret
FEATURE_LIVE_RECORDING=true
FEATURE_LIVE_MASK_BETA=true
EOF

# Mobile .env (для iOS Simulator)
cat > mobile/.env << 'EOF'
API_BASE_URL=http://localhost:8080
EOF
```

### 3. Запустіть Docker Compose

```bash
docker compose up -d
```

### 4. Запустіть міграції

**Windows:**
```powershell
.\migrate.ps1 up
```

**macOS/Linux:**
```bash
chmod +x migrate.sh
./migrate.sh up
```

### 5. Перевірте здоров'я сервісів

```bash
curl http://localhost:8080/healthz    # API
curl http://localhost:7880/            # LiveKit
```

### 6. Запустіть мобільний клієнт

```bash
cd mobile
npm install
npm run expo:start
```

Натисніть `i` (iOS) або `a` (Android) для запуску в емуляторі.

---

## 🎙️ Тестування live-сценарію

1. У мобільному застосунку зареєструйтесь / увійдіть
2. Перейдіть на **"Host Live"**
3. Натисніть **"Start Live"**
4. Натисніть **"Join Audio"** (дозвольте доступ до мікрофону)
5. Говоріть кілька секунд
6. Натисніть **"End Live"**
7. Поверніться на головний екран (Feed)
8. Потягніть вниз для оновлення — має з'явитись новий епізод

---

## 📚 Детальна документація

- **[SETUP.md](./SETUP.md)** — повна інструкція з troubleshooting
- **[ENV_SETUP.md](./ENV_SETUP.md)** — детальний опис змінних оточення

---

## 🛑 Зупинка

```bash
docker compose down          # зупинити без видалення даних
docker compose down -v       # зупинити і видалити всі дані
```

---

## 🐛 Проблеми?

### Порт зайнятий:

```bash
# Windows
netstat -ano | findstr "8080"

# macOS/Linux
lsof -ti :8080 | xargs kill -9
```

### Мобільний клієнт не підключається:

- **Android Emulator:** використовуйте `http://10.0.2.2:8080`
- **iOS Simulator:** використовуйте `http://localhost:8080`
- **Реальний пристрій:** використовуйте IP вашого комп'ютера (наприклад `http://192.168.1.100:8080`)

### Worker не обробляє аудіо:

```bash
# Перевірте логи
docker compose logs -f worker

# Перевірте чергу
docker compose exec redis redis-cli
> XLEN process_audio
```

---

**Успішного запуску! 🎉**

