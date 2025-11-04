#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-amunx}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

# Construct DB URL
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

# Migration direction (default: up)
DIRECTION="${1:-up}"

if [ "$DIRECTION" != "up" ] && [ "$DIRECTION" != "down" ]; then
  echo -e "${RED}Error: Direction must be 'up' or 'down'${NC}"
  echo "Usage: $0 [up|down]"
  exit 1
fi

echo -e "${GREEN}Running migrations ${DIRECTION}...${NC}"
echo -e "${YELLOW}Database: ${DB_URL}${NC}"

# Check if we're running inside Docker or need to use Docker
if [ -f /.dockerenv ]; then
  # We're inside a container, run migrate directly
  echo -e "${YELLOW}Running inside container...${NC}"
  migrate -path=/migrations -database "${DB_URL}" ${DIRECTION}
else
  # Check if docker is available
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
  fi

  # Determine network name
  NETWORK="${DOCKER_NETWORK:-amunx_default}"
  
  # Check if network exists
  if ! docker network inspect "${NETWORK}" &> /dev/null; then
    echo -e "${YELLOW}Warning: Network '${NETWORK}' not found. Trying without network...${NC}"
    NETWORK_FLAG=""
  else
    NETWORK_FLAG="--network ${NETWORK}"
  fi

  # For Docker Compose, adjust host to 'postgres' instead of 'localhost'
  if [ "$DB_HOST" == "localhost" ] && [ -n "$NETWORK_FLAG" ]; then
    echo -e "${YELLOW}Adjusting DB_HOST from localhost to postgres for Docker network${NC}"
    DB_HOST="postgres"
    DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"
  fi

  # Run migrations using Docker
  echo -e "${YELLOW}Running migrations via Docker...${NC}"
  docker run --rm \
    ${NETWORK_FLAG} \
    -v "$(pwd)/backend/db/migrations:/migrations" \
    migrate/migrate:latest \
    -path=/migrations \
    -database "${DB_URL}" \
    ${DIRECTION}
fi

echo -e "${GREEN}Migrations completed successfully!${NC}"

