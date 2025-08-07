### Prometheus Scrape Config

See `configs/prometheus/prometheus-scrape-config.example.yml`.

Jobs to include:
- `adguard` → http://192.168.10.1:3000/control/metrics (adjust port)
- `unbound_exporter` → exporter container:9167 (example)
- `snmp_opnsense` → snmp_exporter:9116, module `if_mib`, target 192.168.10.1
- `qbittorrent_exporter` → container:9022
- `sonarr_exporter_*` → per instance
- `radarr_exporter_*` → per instance
- `prowlarr_exporter` or custom exporter

Scrape intervals:
- 15 s for infra (SNMP, Unbound)
- 30–60 s for media exporters

Relabel to set `instance` names for media stacks.
