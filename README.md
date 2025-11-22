# AmunX - Asynchronous Voice Messenger

Повнофункціональний додаток для асинхронного голосового спілкування з підтримкою подкастів, коротких аудіо повідомлень та live трансляцій.

## 🚀 Швидкий старт

### Передумови

- Docker та Docker Compose
- Flutter SDK (>=3.0.0)
- Go 1.21+
- Android Studio / Xcode (для мобільної розробки)

### 1. Клонування репозиторію

```bash
git clone <repository-url>
cd AmunX
```

### 2. Запуск бекенду

```bash
# Запуск всіх сервісів (PostgreSQL, Redis, API)
docker-compose up -d

# Перевірка статусу
docker-compose ps
```

### 3. Застосування міграцій

```bash
cd backend

# Linux/Mac
./scripts/migrate.sh up

# Windows PowerShell
Get-Content db\migrations\*.up.sql | docker exec -i amunx-postgres-1 psql -U postgres -d amunx
```

### 4. Заповнення тестовими даними

```bash
cd backend

# Linux/Mac
./scripts/seed.sh

# Windows PowerShell
.\scripts\seed.ps1

# Або з очищенням існуючих даних
.\scripts\seed.ps1 -Reset
```

### 5. Запуск Flutter додатку

```bash
cd mobile

# Перевірка доступних пристроїв
flutter devices

# Запуск на Android емуляторі
flutter run -d emulator-5554

# Або на iOS симуляторі
flutter run -d iPhone
```

## 📚 Документація

- [Локальна розробка](LOCAL_DEVELOPMENT.md) - детальна інструкція для локальної розробки
- [Архітектура](docs/ARCHITECTURE.md) - опис архітектури системи
- [API документація](docs/API.md) - опис API endpoints

## 🧪 Тестування

### Backend тести

```bash
cd backend
go test ./internal/http/... -v
```

### Flutter тести

```bash
cd mobile

# Unit тести
flutter test

# Інтеграційні тести
flutter test integration_test/
```

## 📁 Структура проекту

```
AmunX/
├── backend/          # Go backend API
│   ├── cmd/         # Entry points
│   ├── internal/    # Internal packages
│   ├── db/          # Database migrations & seeds
│   └── scripts/     # Utility scripts
├── mobile/          # Flutter mobile app
│   ├── lib/         # Dart source code
│   ├── test/        # Unit tests
│   └── integration_test/  # Integration tests
└── docs/            # Documentation
```

## 🔧 Розробка

### Додавання нових тестових даних

Редагуйте `backend/db/seed.sql` та запустіть seed скрипт:

```bash
cd backend
.\scripts\seed.ps1 -Reset  # Windows
# або
./scripts/seed.sh reset    # Linux/Mac
```

### Логування

#### Backend

Логи доступні через Docker:

```bash
# API логи
docker logs amunx-api-1 --tail 100 -f

# PostgreSQL логи
docker logs amunx-postgres-1 --tail 100 -f
```

#### Flutter

Логи виводяться в консоль під час розробки. Всі логи зберігаються в пам'яті:

```dart
// Отримати всі логи
final logs = AppLogger.getAllLogs();

// Отримати як рядок
final logsString = AppLogger.getLogsAsString();
```

## 🐛 Відлагодження

### Перевірка підключення до бази даних

```bash
docker exec -it amunx-postgres-1 psql -U postgres -d amunx
```

### Перевірка API

```bash
# Health check
curl http://localhost:8080/health

# Тестовий запит
curl http://localhost:8080/v1/me
```

### Перевірка Flutter підключення

Переконайтеся, що Flutter додаток використовує правильний API URL:
- Android Emulator: `http://10.0.2.2:8080`
- iOS Simulator: `http://localhost:8080`
- Фізичний пристрій: `http://<your-ip>:8080`

## 📝 Тестові користувачі

Після виконання seed скрипту доступні наступні тестові користувачі:

- `test1@example.com` (testuser1) - Tech enthusiast
- `test2@example.com` (testuser2) - Music producer
- `test3@example.com` (testuser3) - Content creator
- `test4@example.com` (testuser4) - Developer
- `test5@example.com` (testuser5) - Artist

## 🛠️ Корисні команди

```bash
# Перегляд всіх логів
docker-compose logs -f

# Перезапуск всіх сервісів
docker-compose restart

# Зупинка всіх сервісів
docker-compose down

# Видалення всіх даних (ОБЕРЕЖНО!)
docker-compose down -v
```

## 📄 Ліцензія

[Додайте інформацію про ліцензію]

## 👥 Автори

[Додайте інформацію про авторів]
