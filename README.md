# AmunX

Voice-first journal & livecast platform.

## Structure

- `backend/` — Go services (API + workers), migrations, infra manifests.
- `mobile/` — React Native client scaffold (TypeScript).
- `docker-compose.yml` — Local stack (Postgres, Redis, LiveKit, Loki/Grafana).
- `configs/` — Example configuration for analytics/observability.

## Getting Started

### Backend

```bash
cd backend
cp .env.example .env
go mod download
go run ./cmd/api
```

Run migrations (requires [golang-migrate](https://github.com/golang-migrate/migrate)):

```bash
./scripts/migrate.sh up
```

### Mobile

```bash
cd mobile
npm install
npm run start
```

Fill `.env` using `.env.example` before bundling to simulators or devices.

### Docker Compose

Bring up the full stack (API, worker, Postgres, Redis, LiveKit, Loki, Grafana):

```bash
docker compose up --build
```

### CI

GitHub Actions workflow (`.github/workflows/ci.yml`) runs lint, tests, and builds for both backend and mobile targets.
