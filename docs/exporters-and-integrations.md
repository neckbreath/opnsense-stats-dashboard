### Exporters and Integrations

- AdGuard Home: built-in metrics at `/control/metrics`
- Unbound: `unbound_exporter` (e.g., `github.com/letsencrypt/unbound_exporter` variants) via remote-control
- SNMP: `prometheus/snmp-exporter` (module `if_mib`)
- qBittorrent: `esanchezm/prometheus-qbittorrent-exporter` (or similar)
- Sonarr/Radarr: community exporters exposing queues and status
- Prowlarr: exporter if available; otherwise custom poller
- Blackbox exporter: optional for ICMP/TCP/TLS checks
- Speedtest exporter: optional daily scheduled speed tests

All exporters scraped by Prometheus; label instances appropriately.
