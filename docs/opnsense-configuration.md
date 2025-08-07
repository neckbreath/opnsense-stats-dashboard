### OPNsense Configuration

#### 1. Firewall/NAT Rule Labelling
- For each WAN and NAT rule, enable logging
- Set a unique, descriptive `Description` (becomes `label`/`rule_label` in pf logs)
- Apply and reload

#### 2. Remote Syslog to Promtail
- System → Settings → Logging / targets
  - Add target: Type TCP, Server = <dashboard_host_LAN_IP>, Port = 514
  - Format: RFC5424
  - Enable facilities: firewall, system, unbound (optional), suricata (optional)
- Test with a blocked inbound connection; verify log reaches Loki

#### 3. SNMP
- Services → SNMP
  - Enable agent; Community or v3 (v3 recommended)
  - Allow access from dashboard host IP only
  - Include interface statistics (if_mib)
- Verify `ifName` exposes WAN, LAN, and WireGuard (wg*) interfaces

#### 4. Unbound Remote-Control (TLS)
- Services → Unbound DNS → Advanced
  - Enable `Enable DNSCrypt` (if used) — not required for exporter
  - Enable `Enable remote control`
- Generate TLS certs on OPNsense (or via CLI):
  - `unbound-control-setup`
  - Keys typically in `/var/unbound/`
- Allow dashboard host IP in Unbound ACL for remote-control
- Note file paths for `unbound_exporter` container (copy or mount via read-only share)

#### 5. WireGuard
- Ensure WireGuard plugin is installed and interface named `wg0` (or similar)
- If available, enable WireGuard logs to syslog
- Confirm SNMP exposes WG interface counters

#### 6. Optional: Suricata IDS
- Services → Intrusion Detection → Enable syslog output
- Send to Promtail TCP 514 with RFC5424

#### 7. Firewall Rules for Monitoring Host
- Allow from dashboard host IP to OPNsense on: 161/udp (SNMP), 199/udp (SNMP traps if used), 953/tcp (Unbound rc, if applicable), WireGuard logs if separate
- Allow from OPNsense to dashboard host on: TCP 514 (syslog)
