### Architecture

- UI: Grafana
- Metrics TSDB: Prometheus (single node, 31 d retention)
- Logs DB: Loki (single-process, filesystem, 31 d retention) with Promtail
- Exporters/Collectors:
  - AdGuard Home metrics via built-in Prometheus endpoint; query logs via syslog → Promtail
  - Unbound via unbound_exporter using remote-control TLS
  - OPNsense pf logs via syslog → Promtail; SNMP for interfaces (WAN/LAN/WG)
  - Media: qbittorrent-exporter, sonarr_exporter (×3), radarr_exporter (×3), prowlarr exporter or custom poller
  - Event Collector: receives webhooks from Sonarr/Radarr/Prowlarr/qBittorrent/Cleanarr/Huntarr and forwards structured logs to Loki
- GeoIP: Promtail geoip stage with MaxMind GeoLite2-City.mmdb

### Networking
- Bind services to LAN IP only
- Syslog from OPNsense and AdGuard to Promtail TCP 514
- SNMP from OPNsense to snmp_exporter (dashboard host only)
- Unbound remote-control TCP/TLS from exporter container

### Retention and Sizing
- Prometheus: 31 d retention; scrape 15–60 s; memory target 512–1024 MB
- Loki: 31 d retention; expected 5–15 GB disk usage; memory 512–1024 MB
- Grafana: 256–512 MB RAM
- Exporters+Promtail: < 256 MB aggregate

### Timezone and Locale
- Australia/Sydney timezone at Grafana and exporters
- Australian formats for documentation examples

### Docker Compose (high-level)
- Networks: `monitoring`
- Volumes: `prometheus-data`, `loki-data`, `grafana-data`, `promtail-maxmind`
- Services: `grafana`, `prometheus`, `loki`, `promtail`, `snmp_exporter`, `unbound_exporter`, `qbittorrent_exporter`, `sonarr_exporter_*`, `radarr_exporter_*`, `prowlarr_exporter`, `event-collector`, optional `blackbox_exporter`, `speedtest_exporter`

### Data Flow
1) OPNsense/AdGuard send syslog → Promtail → Loki
2) Exporters expose /metrics → Prometheus scrapes
3) Event Collector receives webhooks → writes JSON Lines → Promtail (file target) or pushes to Loki
4) Grafana queries Prometheus and Loki for dashboards
