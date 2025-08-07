### Promtail Pipelines

Syslog receivers for pf (OPNsense) and AdGuard, plus file target for event-collector JSONL. GeoIP enrichment on `src_ip`.

#### Example: promtail-syslog-pipeline.example.yml
See `configs/promtail/promtail-syslog-pipeline.example.yml` for a runnable template.

Key stages for pf logs:
- `regex` extract pf fields (IPv4/IPv6)
- `replace`/`labels` map description to `rule_label`
- `geoip` on `src_ip` using `GeoLite2-City.mmdb`
- `timestamp` parse if custom timestamps used

Key stages for AdGuard logs:
- `regex`/`json` to parse client, domain, type, status, elapsed

Event Collector JSONL:
- `json` stage; labels `service`, `instance`, `action`

Label hygiene:
- Drop excessively unique labels
- Never label per-IP in metrics; logs are acceptable for IP labels
