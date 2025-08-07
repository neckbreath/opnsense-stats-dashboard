### Security and Access

- Local-only: bind Grafana, Prometheus, Loki, Promtail, exporters to LAN IP
- Grafana: disable sign-up, set strong admin password, local auth only
- Secrets: use Docker env files; never bake secrets into images
- Network ACLs: OPNsense rules allowing SNMP and syslog only from dashboard host
- Unbound remote-control: TLS certs, restrict to dashboard host IP
- Syslog: prefer TCP over UDP for reliability; consider TLS if available
- Logs and PII: avoid logging full query strings unnecessarily; redact tokens
- Backups: periodic copy of Grafana provisioning/dashboards; TSDBs are ephemeral by design (31 d retention)
