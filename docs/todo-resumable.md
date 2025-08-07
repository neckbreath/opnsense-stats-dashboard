### Resumable To-Do

- Bootstrap
  - Create Docker network `monitoring`
  - Create volumes: `prometheus-data`, `loki-data`, `grafana-data`, `promtail-maxmind`
  - Place GeoLite2-City.mmdb into volume/mount
  - Start Grafana, Prometheus, Loki, Promtail

- OPNsense Integration
  - Enable remote syslog (TCP 514) to dashboard host
  - Ensure firewall/NAT rules have descriptive `label` and logging enabled
  - Enable SNMP and allow dashboard host
  - Enable Unbound remote-control with TLS; allow dashboard host; export keys
  - Optional: enable WireGuard logs

- Promtail Config
  - Add syslog receiver(s): TCP 514, UDP 514 if needed
  - pf pipeline: regex extract, rule_label, geoip on src_ip
  - AdGuard pipeline: extract client, domain, status, type, elapsed_ms
  - Media pipeline: extract action, title, size_bytes, error

- Prometheus Scrapes
  - Add jobs: snmp_exporter, unbound_exporter, adguard, qbittorrent, sonarr*, radarr*, prowlarr
  - Set scrape intervals (infra 15 s; media 30–60 s)

- Event Collector
  - Implement endpoints; require token header; write JSONL to file
  - Promtail file target to ship JSONL to Loki
  - Healthcheck and minimal logging

- Grafana
  - Add data sources: Prometheus, Loki
  - Import/create dashboards: WAN Threat Map, NAT Flow, DNS Overview, Interfaces/WireGuard, Media Overview, Ops/Infra
  - Configure timezone Australia/Sydney

- Retention/Storage
  - Prometheus retention 31 d; storage path to `prometheus-data`
  - Loki single-process with boltdb-shipper; retention 31 d

- Hardening
  - Bind to LAN IP only
  - Credentials via env files
  - OPNsense firewall rules to permit only required ports from dashboard host
