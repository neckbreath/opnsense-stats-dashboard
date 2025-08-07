### WireGuard Monitoring

- Prefer SNMP interface counters for `wg*` interfaces on OPNsense
- Confirm `ifName` exposes WG interfaces via SNMP
- Metrics:
  - `ifHCInOctets`, `ifHCOutOctets`, `ifOperStatus`
- Optional logs: enable WireGuard logs to syslog; ship to Loki for peer handshake events
- Grafana: traffic rates, availability, handshake timeline (if logs present)
