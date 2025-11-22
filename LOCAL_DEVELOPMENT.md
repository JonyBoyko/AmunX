# Локальна розробка та тестування

Цей документ описує, як налаштувати повне локальне середовище для розробки та тестування.

## Передумови

- Docker та Docker Compose
- Flutter SDK
- Go 1.21+
- PostgreSQL (через Docker)

## Швидкий старт

### 1. Запуск бекенду

```bash
# Запуск всіх сервісів
docker-compose up -d

# Перевірка статусу
docker-compose ps
```

### 2. Застосування міграцій

```bash
# Linux/Mac
cd backend
./scripts/migrate.sh up

# Windows PowerShell
cd backend
Get-Content db\migrations\*.up.sql | docker exec -i amunx-postgres-1 psql -U postgres -d amunx
```

### 3. Заповнення тестовими даними

```bash
# Linux/Mac
cd backend
./scripts/seed.sh

# Windows PowerShell
cd backend
.\scripts\seed.ps1

# Або з очищенням існуючих даних
.\scripts\seed.ps1 -Reset
```

### 4. Запуск Flutter додатку

```bash
cd mobile
flutter run -d emulator-5554
```

## Тестові користувачі

Після виконання seed скрипту будуть створені наступні тестові користувачі:

- **test1@example.com** (testuser1) - Tech enthusiast
- **test2@example.com** (testuser2) - Music producer
- **test3@example.com** (testuser3) - Content creator
- **test4@example.com** (testuser4) - Developer
- **test5@example.com** (testuser5) - Artist

Для входу використовуйте dev-login endpoint або magic link.

## Структура тестових даних

### Користувачі
- 5 тестових користувачів з різними профілями
- Різні плани (free/pro)
- Різні дати реєстрації

### Аудіо контент
- 9 аудіо епізодів (7 podcast_episode, 2 micro)
- Різні тривалості (90 сек - 3600 сек)
- Різні теги та категорії
- Різні дати публікації

### Взаємодії
- Коментарі до епізодів
- Лайки
- Підписки між користувачами
- Підписки на теми
- Feed events

## Логування

### Backend

Логи зберігаються в Docker контейнерах:

```bash
# Перегляд логів API
docker logs amunx-api-1 --tail 100 -f

# Перегляд логів PostgreSQL
docker logs amunx-postgres-1 --tail 100 -f
```

Логування включає:
- Всі HTTP запити з деталями (method, path, status, duration)
- Помилки з повним stack trace
- Детальна інформація про помилки бази даних

### Flutter

Логи виводяться в консоль під час розробки. Всі логи зберігаються в пам'яті і можуть бути експортовані:

```dart
// Отримати всі логи
final logs = AppLogger.getAllLogs();

// Отримати логи як рядок
final logsString = AppLogger.getLogsAsString();

// Очистити логи
AppLogger.clearLogs();
```

## Тестування

### Інтеграційні тести Backend

```bash
cd backend
go test ./internal/http/... -v
```

### Інтеграційні тести Flutter

```bash
cd mobile
flutter test integration_test/
```

## Розробка

### Додавання нових тестових даних

Редагуйте `backend/db/seed.sql` та запустіть seed скрипт знову.

### Очищення даних

```bash
# Linux/Mac
./scripts/seed.sh reset

# Windows PowerShell
.\scripts\seed.ps1 -Reset
```

### Перезапуск сервісів

```bash
docker-compose restart
```

## Відлагодження

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

## Проблеми та рішення

### База даних не підключається

```bash
# Перевірка статусу контейнера
docker ps | grep postgres

# Перезапуск контейнера
docker-compose restart postgres
```

### API повертає помилки

Перевірте логи:
```bash
docker logs amunx-api-1 --tail 50
```

### Flutter не може підключитися до API

1. Перевірте, що Docker контейнери запущені
2. Перевірте правильність API URL в `mobile/lib/core/config/app_config.dart`
3. Перевірте firewall налаштування

## Корисні команди

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

