# OPNsense Stats Dashboard – Implementation Docs

Local-only observability stack for an OPNsense-centred home network. Visualise WAN firewall hits with GeoIP, NAT flow (IPv4/IPv6), DNS metrics (AdGuard Home + Unbound), WireGuard traffic, and media automation services activity. Data retained for 31 days. Timezone: Australia/Sydney.

## Contents
- docs/architecture.md
- docs/build-phases-and-test-gates.md
- docs/todo-resumable.md
- docs/security-and-access.md
- docs/data-model-and-labels.md
- docs/grafana-dashboards.md
- docs/promtail-pipelines.md
- docs/prometheus-scrape-config.md
- docs/exporters-and-integrations.md
- docs/opnsense-configuration.md
- docs/adguard-home-configuration.md
- docs/unbound-configuration.md
- docs/wireguard-monitoring.md
- docs/media-stack-integration.md
- docs/event-collector-spec.md
- docs/testing-and-validation.md
- docs/nginx-logging.md (optional)
- docs/optional-extensions.md (optional)
- docs/grafana-plugins.md (optional)
- docs/maxmind-geoip.md (optional)

## Environment-Specific Configuration
- docs/network-configuration.md
- docs/media-stack-topology.md
- docs/deployment-parameters.md

## Config templates
- configs/promtail/promtail-syslog-pipeline.example.yml
- configs/prometheus/prometheus-scrape-config.example.yml
- configs/loki/loki-single-process.example.yml
- configs/grafana/provisioning/datasources.example.yml
- configs/docker-compose.example.yml

## Service specs
- services/event-collector/README.md
- services/event-collector/api-schema.md
- services/event-collector/loki-log-schema.md
- services/event-collector/openapi.yaml

## Getting started
1) Read docs/architecture.md
2) Follow Phase 0 in docs/build-phases-and-test-gates.md
3) Configure OPNsense and AdGuard using their respective docs
4) Adapt config templates in configs/* for your environment

All components are intended to run via Docker Compose on a LAN-restricted host. No external access.
