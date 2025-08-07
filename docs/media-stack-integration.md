### Media Stack Integration

#### qBittorrent
- Enable Web API; create read-only user
- Deploy `qbittorrent-exporter` with env:
  - `QBT_ADDRESS=http://qbittorrent:8080`
  - `QBT_USERNAME=monitor`
  - `QBT_PASSWORD=*****`
- Webhook to event collector on download completed/errored

#### Sonarr ×3 / Radarr ×3
- Provide API keys to exporters per instance
- Configure Webhooks → Event Collector for events:
  - Grabbed, Download, Import, Upgrade, Delete
- Include instance name in webhook URL (e.g., `/webhook/sonarr/main`)

#### Prowlarr
- If exporter available, deploy with API key
- Otherwise, implement lightweight poller or send webhooks for indexer health

#### Huntarr / Cleanarr
- If webhook supported, send to Event Collector
- Also ship container logs via Promtail and parse actions (removed stalled/invalid)

#### Grafana Panels
- Recent additions/upgrades/removals: Loki queries by `service`, `action`
- qBittorrent: transfer rates, completed count, error rate over 30 d
