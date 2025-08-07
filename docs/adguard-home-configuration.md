### AdGuard Home Configuration

#### 1. Prometheus Metrics
- Settings → General Settings → Enable Prometheus metrics
- Verify `/control/metrics` is reachable from Prometheus (LAN only)

#### 2. Syslog for Query Logs
- Settings → Logging → Enable syslog output
  - Server: <dashboard_host_LAN_IP>
  - Port: 515
  - Protocol: TCP
  - Format: RFC5424
- Ensure query log fields include client, domain, status, elapsed

#### 3. Access Controls
- Restrict AdGuard UI/API to LAN
- Create API token if required by exporters (not typical for metrics endpoint)

#### 4. Upstream DNS
- Keep upstream set to Unbound on 192.168.10.1:5353
- Ensure EDNS client subnet is disabled unless needed; privacy first
