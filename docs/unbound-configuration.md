### Unbound Configuration for Exporter

#### 1. Enable Remote-Control
- In OPNsense UI: Services → Unbound DNS → Advanced
  - Tick `Enable remote control`

#### 2. Generate TLS Keys (on OPNsense)
- SSH to OPNsense and run:
  - `unbound-control-setup`
- Resulting files (paths may vary):
  - `/var/unbound/unbound_control.key`
  - `/var/unbound/unbound_control.pem`
  - `/var/unbound/unbound_server.key`
  - `/var/unbound/unbound_server.pem`

#### 3. ACL
- Allow the dashboard host IP for remote-control connections

#### 4. Exporter Container
- Mount the four files read-only into the `unbound_exporter` container
- Exporter config (env):
  - `UNBOUND_HOST=192.168.10.1`
  - `UNBOUND_PORT=8953` (default remote-control)
  - `UNBOUND_CONTROL_KEY=/certs/unbound_control.key`
  - `UNBOUND_CONTROL_CERT=/certs/unbound_control.pem`
  - `UNBOUND_SERVER_KEY=/certs/unbound_server.key`
  - `UNBOUND_SERVER_CERT=/certs/unbound_server.pem`

#### 5. Verification
- From exporter container, run `unbound-control -c /path/to/conf stats` if available
- Prometheus should scrape metrics like `unbound_queries_total`, `unbound_cache_hits_total`, etc.
