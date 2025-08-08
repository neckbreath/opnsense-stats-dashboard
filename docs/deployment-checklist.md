### Deployment Checklist

**Use this checklist for on-site deployment and testing.**

#### Pre-Deployment ✓

- [ ] **MaxMind Account Created**
  - [ ] Free account registered
  - [ ] GeoLite2-City.mmdb downloaded
  - [ ] File placed in `./promtail-maxmind/`
  - [ ] File size > 50MB (verify not corrupted)

- [ ] **Unbound Certificates Exported**
  - [ ] SSH access to OPNsense confirmed
  - [ ] All 4 certificate files copied to `./unbound-certs/`
  - [ ] File permissions set correctly (readable)

- [ ] **Environment Configuration**
  - [ ] `.env` file created from `env.example`
  - [ ] EVENT_COLLECTOR_TOKEN generated (32+ chars)
  - [ ] All API keys collected from media services
  - [ ] qBittorrent monitor password set

- [ ] **Network Connectivity**
  - [ ] Dashboard host IP confirmed as 192.168.10.10
  - [ ] OPNsense accessible at 192.168.10.1
  - [ ] All media services accessible on documented ports

#### Deployment Phase ✓

- [ ] **Prerequisites Check**
  ```bash
  ./deploy.sh check
  ```
  - [ ] Docker and Docker Compose installed
  - [ ] Running on correct host IP
  - [ ] All files present and valid

- [ ] **Core Stack Deployment**
  ```bash
  ./deploy.sh deploy
  ```
  - [ ] All containers started successfully
  - [ ] No error messages in deployment log
  - [ ] Services bound to 192.168.10.10

- [ ] **Initial Service Verification**
  - [ ] Grafana: http://192.168.10.10:3000 loads
  - [ ] Prometheus: http://192.168.10.10:9090 accessible
  - [ ] Event Collector: http://192.168.10.10:8088/health returns 200

#### OPNsense Configuration ✓

- [ ] **Firewall Rules**
  - [ ] WAN rules have logging enabled
  - [ ] Rules have descriptive labels
  - [ ] Test traffic generates log entries

- [ ] **Syslog Configuration**
  - [ ] Remote logging enabled
  - [ ] Target: 192.168.10.10:514
  - [ ] All facility levels selected
  - [ ] Test log entries sent successfully

- [ ] **SNMP Configuration**
  - [ ] SNMP agent enabled
  - [ ] Community: public
  - [ ] Access restricted to 192.168.10.10
  - [ ] Interface statistics accessible

- [ ] **Unbound Remote Control**
  - [ ] Remote control enabled
  - [ ] Certificates exported and placed
  - [ ] Test connection from exporter container

#### AdGuard Configuration ✓

- [ ] **Admin Interface Port Confirmed**
  - [ ] Actual port documented: ____________
  - [ ] Prometheus config updated if not 3000

- [ ] **Metrics Export**
  - [ ] Prometheus metrics enabled
  - [ ] Metrics endpoint accessible: http://192.168.10.1:XXXX/control/metrics
  - [ ] Valid metrics data returned

- [ ] **Query Logging**
  - [ ] Query log enabled
  - [ ] Syslog output configured to 192.168.10.10:515
  - [ ] Test queries appear in logs

#### Media Services Integration ✓

- [ ] **qBittorrent**
  - [ ] Monitor user created
  - [ ] Credentials match .env file
  - [ ] Exporter connecting successfully
  - [ ] Metrics visible in Prometheus

- [ ] **Sonarr Main (8989)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/sonarr/main
  - [ ] Test webhook fires successfully
  - [ ] Events appear in Event Collector logs

- [ ] **Sonarr Cartoons (8990)**
  - [ ] API key added to .env  
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/sonarr/cartoons
  - [ ] Test webhook fires successfully

- [ ] **Sonarr Anime (8991)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/sonarr/anime
  - [ ] Test webhook fires successfully

- [ ] **Radarr Main (7878)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/radarr/main
  - [ ] Test webhook fires successfully
  - [ ] Events appear in Event Collector logs

- [ ] **Radarr Cartoons (7879)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/radarr/cartoons
  - [ ] Test webhook fires successfully

- [ ] **Radarr Anime (7880)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/radarr/anime
  - [ ] Test webhook fires successfully

- [ ] **Prowlarr (9696)**
  - [ ] API key added to .env
  - [ ] Webhook configured: http://192.168.10.10:8088/webhook/prowlarr/main
  - [ ] Test webhook fires successfully

#### Data Flow Validation ✓

- [ ] **Prometheus Targets**
  - [ ] All targets showing as UP in Prometheus
  - [ ] No authentication or connection errors
  - [ ] Metrics data populating correctly

- [ ] **Loki Log Ingestion**
  - [ ] pf logs appearing with parsed fields
  - [ ] AdGuard logs appearing with parsed fields
  - [ ] Event Collector logs appearing as JSONL

- [ ] **GeoIP Enrichment**
  - [ ] External blocked connections show country data
  - [ ] Latitude/longitude fields populated
  - [ ] GeoMap panel shows markers correctly

- [ ] **WireGuard Monitoring**
  - [ ] wg1 interface traffic visible
  - [ ] SNMP data showing bytes in/out
  - [ ] IPv6 traffic captured if active

#### Dashboard Validation ✓

- [ ] **Network Overview Dashboard**
  - [ ] WAN traffic graphs populated
  - [ ] WireGuard traffic visible
  - [ ] Service status indicators green
  - [ ] DNS performance metrics shown

- [ ] **WAN Threat Map Dashboard**
  - [ ] Geographic markers appear on map
  - [ ] Country breakdown pie charts populated
  - [ ] Recent blocked connections log shows entries
  - [ ] Map centered on Australia with visible threats

- [ ] **Media Services Dashboard**
  - [ ] All service status indicators green
  - [ ] qBittorrent transfer rates showing
  - [ ] Torrent activity metrics populated
  - [ ] Recent events log shows webhook activity

#### Performance Validation ✓

- [ ] **Resource Usage**
  - [ ] Docker containers within memory limits
  - [ ] Disk usage reasonable for retention period
  - [ ] CPU usage not excessive during normal operations

- [ ] **Query Performance**
  - [ ] Grafana dashboards load within 5 seconds
  - [ ] LogQL queries complete without timeout
  - [ ] PromQL queries execute efficiently

- [ ] **Data Retention**
  - [ ] Prometheus retention set to 31 days
  - [ ] Loki retention set to 31 days
  - [ ] Old data cleanup functioning

#### Security Validation ✓

- [ ] **Access Control**
  - [ ] Services bound only to LAN IP
  - [ ] No external access to monitoring ports
  - [ ] Default passwords changed

- [ ] **Authentication**
  - [ ] Event Collector requires valid token
  - [ ] API keys configured correctly
  - [ ] SNMP community string secure

#### Final Verification ✓

- [ ] **End-to-End Testing**
  - [ ] Generate test firewall block → visible in threat map
  - [ ] Trigger media webhook → event appears in dashboard
  - [ ] DNS query → shows in AdGuard metrics
  - [ ] WireGuard traffic → reflected in interface graphs

- [ ] **Documentation Updated**
  - [ ] Network configuration documented
  - [ ] Service credentials securely stored
  - [ ] Contact information for future maintenance

- [ ] **Monitoring Health**
  - [ ] All exporters healthy and collecting data
  - [ ] No critical alerts or service failures
  - [ ] Baseline metrics established for future comparison

#### Post-Deployment Notes

**Date Completed:** _______________  
**Deployed By:** _______________  
**Issues Encountered:** 
_________________________________
_________________________________
_________________________________

**Next Review Date:** _______________
