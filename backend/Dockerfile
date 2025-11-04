# syntax=docker/dockerfile:1.6

FROM golang:1.22 AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./cmd/api

FROM gcr.io/distroless/base-debian12
WORKDIR /srv
COPY --from=builder /app/server /srv/server

ENV HTTP_HOST=0.0.0.0 HTTP_PORT=8080

EXPOSE 8080

ENTRYPOINT ["/srv/server"]

