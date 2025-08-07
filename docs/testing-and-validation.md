### Testing and Validation

- Syslog path: trigger a blocked WAN hit; verify Loki record and GeoIP fields
- NAT labels: hit a labelled NAT rule; verify aggregation in Sankey panel
- SNMP: generate WG traffic; see spikes on interface rate graphs
- AdGuard: query a blocked domain; verify counters and log entry
- Unbound: run `unbound-control stats` and compare with exporter metrics
- qBittorrent: start a small torrent; verify exporter metrics and webhook event
- Sonarr/Radarr: force an import/upgrade; verify recent list
- Retention: mark a record with old timestamp; ensure it prunes after 31 d
