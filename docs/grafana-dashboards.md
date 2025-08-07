### Grafana Dashboards

#### WAN Threat Map
- Geomap panel (Loki): aggregate pf logs by `country_iso`
- LogQL example:
  - `{app="pf"} |= "block" | unwrap src_ip | sum by (country_iso) (count_over_time({app="pf", action="block"}[1h]))`

#### NAT Flow (Sankey)
- Requires Sankey plugin
- Build edges: source country → rule_label → dst_host:port
- Use LogQL `sum by (...) (count_over_time())` and transform to Sankey format

#### DNS Overview
- Panels from Prometheus:
  - Cache hit ratio: `rate(unbound_cache_hits_total[5m]) / (rate(unbound_cache_hits_total[5m]) + rate(unbound_cache_misses_total[5m]))`
  - AdGuard queries/blocked: `rate(adguard_dns_queries_total[5m])`, `rate(adguard_dns_queries_blocked_total[5m])`
  - Upstream latency histograms from AdGuard metrics

#### WireGuard / Interfaces
- SNMP-based panels per interface: `rate(ifHCInOctets[5m]) * 8` and `rate(ifHCOutOctets[5m]) * 8`
- Availability via `ifOperStatus`

#### Media Overview
- qBittorrent transfer rates, active torrents, seeding ratio
- Recent additions/upgrades/removals from Loki event logs

#### Ops / Infra
- Exporter up: `up{job=~".*"}`
- Prometheus and Loki health dashboards (import stock dashboards)

Timezone: Australia/Sydney in Grafana preferences.
