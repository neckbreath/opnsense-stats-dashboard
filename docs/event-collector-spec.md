### Event Collector Specification

Purpose: receive webhooks from media services and forward structured events to Loki via JSON Lines file or HTTP push. Low resource, local-only.

#### Security
- Require `X-Auth-Token` header matching `EVENT_COLLECTOR_TOKEN`
- Bind to LAN IP only

#### Endpoints
- `POST /webhook/sonarr/{instance}`
- `POST /webhook/radarr/{instance}`
- `POST /webhook/prowlarr/{instance}`
- `POST /webhook/qbittorrent/{instance}`
- `POST /webhook/cleanuparr/{instance}`
- `POST /webhook/huntarr/{instance}`

#### Generic JSON Event (body)
```
{
  "service": "sonarr",
  "instance": "main",
  "action": "Imported|Upgraded|Deleted|Grabbed|Errored",
  "title": "string",
  "quality": "string",
  "size_bytes": 123456789,
  "timestamp": "ISO8601",
  "details": { "k": "v" }
}
```

#### Loki JSON Line (one per line)
```
{"service":"sonarr","instance":"main","action":"Imported","title":"...","size_bytes":1234,"timestamp":"...","details":{...}}
```

Promtail file target picks up the JSONL and ships with labels `service`, `instance`, `action`.

#### OpenAPI
See `services/event-collector/openapi.yaml` for a minimal spec.
