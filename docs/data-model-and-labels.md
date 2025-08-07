### Data Model and Labels

Common log labels:
- `job`, `host`, `app`, `env=home`, `facility`, `severity`

pf firewall logs (Loki labels):
- `action`, `direction`, `iface`, `proto`, `rule_label`, `src_ip`, `dst_ip`, `src_port`, `dst_port`, `country_iso`, `city`, `latitude`, `longitude`

AdGuard query logs (Loki labels):
- `client_ip`, `client_name`, `domain`, `type`, `status` (blocked|ok|cached), `rule`, `upstream`

Media event logs (Loki labels):
- `service` (sonarr|radarr|prowlarr|qbittorrent|cleanuparr|huntarr), `instance`, `action`, additional fields as JSON

Prometheus metrics labels:
- Keep cardinality low. Avoid per-IP labels. Prefer aggregations by instance and service.

Retention:
- Prometheus: 31 d
- Loki: 31 d (compactor removes old chunks)

Cardinality controls:
- Avoid adding `domain` as a label in metrics; keep in logs only
- Use `drop` stages in Promtail to discard noisy or unhelpful fields
