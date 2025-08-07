### Event Collector Service

Receives webhooks from media services (Sonarr, Radarr, Prowlarr, qBittorrent, Cleanarr, Huntarr). Writes structured JSON Lines to disk for Promtail to ship to Loki.

- Bind: `EVENT_COLLECTOR_BIND` (default `0.0.0.0:8088`)
- Auth: `X-Auth-Token` header must equal `EVENT_COLLECTOR_TOKEN`
- Log dir: `EVENT_COLLECTOR_LOG_DIR` (e.g., `/var/log/event-collector`)
- File rotation: daily rotate by date

See `api-schema.md` and `openapi.yaml` for payloads and endpoints.
