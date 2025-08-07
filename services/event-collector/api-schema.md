### API Schema

Headers:
- `Content-Type: application/json`
- `X-Auth-Token: <token>`

Endpoints:
- `POST /webhook/sonarr/{instance}`
- `POST /webhook/radarr/{instance}`
- `POST /webhook/prowlarr/{instance}`
- `POST /webhook/qbittorrent/{instance}`
- `POST /webhook/cleanuparr/{instance}`
- `POST /webhook/huntarr/{instance}`

Body (generic):
```
{
  "action": "Imported|Upgraded|Deleted|Grabbed|Completed|Errored",
  "title": "string",
  "quality": "string",
  "size_bytes": 123456,
  "timestamp": "2025-01-01T10:15:30+10:00",
  "details": {
    "indexer": "...",
    "torrent_hash": "...",
    "path": "..."
  }
}
```

Response:
- 202 Accepted
- Body: `{ "status": "accepted" }`
