### Deployment Parameters

#### Regional Configuration
- **Timezone:** Australia/Sydney (all services)
- **Standards:** Australian formatting for addresses, phone numbers, postcodes
- **Locale:** en_AU where applicable

#### Authentication & Security
- **Event Collector Token:** To be generated (secure random)
- **SNMP Community:** public (default)
- **Unbound Certificates:** Export from OPNsense required
  - unbound_control.key
  - unbound_control.pem
  - unbound_server.key
  - unbound_server.pem

#### External Dependencies
- **MaxMind Account:** Required for GeoLite2-City.mmdb download
- **AdGuard Admin Port:** To be confirmed later (reminder set)

#### Monitoring Configuration
- **Retention Period:** 31 days (Prometheus + Loki)
- **Scrape Intervals:**
  - Infrastructure (SNMP, Unbound): 15s
  - Media services: 30-60s
- **Storage Estimates:**
  - Prometheus: 512-1024 MB memory
  - Loki: 5-15 GB disk, 512-1024 MB memory
  - Grafana: 256-512 MB memory

#### Service Binding
- **Dashboard Host IP:** 192.168.10.10 (bind all monitoring services)
- **External Access:** LAN-only, no internet exposure
- **Container Network:** monitoring (isolated Docker network)

#### Build Phases
Following 10-phase deployment plan from docs/build-phases-and-test-gates.md:
- Phase 0: Prerequisites (GeoIP, volumes, network)
- Phase 1-10: Progressive service deployment with validation gates

#### Automation Level
- **Fully Automated:** 85% (stack deployment, configuration, dashboards)
- **Manual Setup Required:** MaxMind account, OPNsense certificates, webhook configuration
- **User Input Required:** Network validation, service credentials
