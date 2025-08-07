### Build Phases and Test Gates

- Phase 0 — Prerequisites
  - Create MaxMind account, download GeoLite2-City.mmdb
  - Reserve static LAN IP for dashboard host
  - Create Docker volumes and network
  - Test: file available to Promtail; timezone set to Australia/Sydney

- Phase 1 — Core Stack Up
  - Bring up Grafana, Prometheus, Loki, Promtail
  - Add Prometheus and Loki as Grafana data sources
  - Test: Grafana queries both data sources

- Phase 2 — OPNsense Syslog → Loki
  - Configure OPNsense remote syslog to Promtail TCP 514
  - Implement pf parsing pipeline (no geoip yet)
  - Test: pf logs visible; fields extracted

- Phase 3 — GeoIP Enrichment
  - Add geoip stage on src_ip
  - Build initial Geomap panel
  - Test: markers render with correct countries

- Phase 4 — NAT Rule Labels and Flow
  - Ensure rule labels in pf logs; adjust OPNsense labels
  - Build Sankey panel (country → rule_label → internal host:port)
  - Test: edges populated; drill-down filters function

- Phase 5 — SNMP Interfaces incl. WireGuard
  - Deploy snmp_exporter; add job; target OPNsense
  - Verify ifHCInOctets/ifHCOutOctets for WAN/LAN/WG
  - Test: rate graphs show traffic; WG traffic visible

- Phase 6 — AdGuard Metrics and Logs
  - Enable Prometheus metrics; add job
  - Enable syslog; add Promtail parsing
  - Dashboards for blocked/allowed, latency, top clients/domains
  - Test: counters and logs align

- Phase 7 — Unbound Exporter
  - Enable remote-control with TLS; deploy unbound_exporter
  - Dashboards: cache hit ratio, misses, memory, rcodes
  - Test: metrics populate and match unbound-control stats

- Phase 8 — Media Exporters + Event Collector
  - Deploy exporters and event collector; configure webhooks
  - Dashboards: recent additions/upgrades/removals; transfer rates; queues
  - Test: webhook events appear quickly; scrapes OK

- Phase 9 — Health and Alerts
  - Configure Grafana alerting for spikes/failures/exporter down
  - Test: synthetic triggers fire and resolve

- Phase 10 — Retention and Limits
  - Set Prometheus and Loki retention to 31 d
  - Validate disk usage; enforce label cardinality limits
  - Test: old data pruned as expected
