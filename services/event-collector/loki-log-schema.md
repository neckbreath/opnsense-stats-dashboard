### Loki Log Schema

Labels:
- `job=event-collector`
- `service` (sonarr|radarr|prowlarr|qbittorrent|cleanuparr|huntarr)
- `instance` (free text)
- `action`

JSON Line fields:
- `timestamp` (ISO 8601)
- `title`
- `quality`
- `size_bytes`
- `details` (object)

Example line:
```
{"service":"sonarr","instance":"main","action":"Imported","timestamp":"2025-01-01T10:15:30+10:00","title":"Foo S01E01","quality":"1080p","size_bytes":1234,"details":{"path":"/data/..."}}
```
