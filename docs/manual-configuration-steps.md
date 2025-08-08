### Manual Configuration Steps

These steps must be completed on-site to fully activate the monitoring stack.

#### Phase 0: Prerequisites (Complete Before Deployment)

1. **MaxMind GeoIP Setup**
   - Create free account at https://www.maxmind.com/en/geolite2/signup
   - Sign in to MaxMind account
   - Navigate to "Download Files" section
   - Download "GeoLite2 City" in MaxMind DB binary format (.mmdb)
   - Verify file size is approximately 70-80MB (not corrupted)
   - Create directory: `mkdir -p ./promtail-maxmind/`
   - Place file as `./promtail-maxmind/GeoLite2-City.mmdb`
   - Verify file permissions are readable: `chmod 644 ./promtail-maxmind/GeoLite2-City.mmdb`

2. **Unbound Certificate Export**
   
   **Method 1: OPNsense WebUI (Preferred)**
   - Log into OPNsense WebUI at https://192.168.10.1
   - Navigate to Services → Unbound DNS → Advanced
   - Enable "Enable remote control" if not already enabled
   - Click "Generate Keys" if certificates don't exist
   - Download certificate files via WebUI or proceed to Method 2
   
   **Method 2: SSH Direct Access**
   - SSH to OPNsense: `ssh root@192.168.10.1`
   - Navigate to: `cd /var/unbound/`
   - List files: `ls -la *.pem *.key`
   - Copy these files to local `./unbound-certs/` directory:
     - `unbound_control.key`
     - `unbound_control.pem`
     - `unbound_server.key` 
     - `unbound_server.pem`
   
   **File Transfer Commands:**
   ```bash
   # Create local directory
   mkdir -p ./unbound-certs/
   
   # Copy files (from OPNsense CLI)
   scp /var/unbound/unbound_control.key user@192.168.10.10:/path/to/project/unbound-certs/
   scp /var/unbound/unbound_control.pem user@192.168.10.10:/path/to/project/unbound-certs/
   scp /var/unbound/unbound_server.key user@192.168.10.10:/path/to/project/unbound-certs/
   scp /var/unbound/unbound_server.pem user@192.168.10.10:/path/to/project/unbound-certs/
   
   # Or copy files (from dashboard host)
   scp root@192.168.10.1:/var/unbound/unbound_control.* ./unbound-certs/
   scp root@192.168.10.1:/var/unbound/unbound_server.* ./unbound-certs/
   ```
   
   **Verify Certificate Files:**
   ```bash
   # Check all 4 files are present
   ls -la ./unbound-certs/
   
   # Verify certificate validity
   openssl x509 -in ./unbound-certs/unbound_control.pem -text -noout
   openssl x509 -in ./unbound-certs/unbound_server.pem -text -noout
   ```

3. **Environment Configuration**
   
   **Create Environment File:**
   ```bash
   # Copy template
   cp env.example .env
   
   # Generate secure Event Collector token
   openssl rand -hex 32
   # Copy this value to EVENT_COLLECTOR_TOKEN in .env
   ```
   
   **Collect API Keys from Media Services:**
   
   **qBittorrent:**
   - Access qBittorrent WebUI: http://192.168.10.10:8080
   - Tools → Options → Web UI
   - Create new user: `monitor` with strong password
   - Copy password to `QBITTORRENT_MONITOR_PASSWORD` in .env
   
   **Sonarr Instances:**
   - Main (8989): Settings → General → Security → API Key
   - Cartoons (8990): Settings → General → Security → API Key  
   - Anime (8991): Settings → General → Security → API Key
   - Copy each to respective `SONARR_*_API_KEY` variables in .env
   
   **Radarr Instances:**
   - Main (7878): Settings → General → Security → API Key
   - Cartoons (7879): Settings → General → Security → API Key
   - Anime (7880): Settings → General → Security → API Key
   - Copy each to respective `RADARR_*_API_KEY` variables in .env
   
   **Prowlarr:**
   - Access Prowlarr WebUI: http://192.168.10.10:9696
   - Settings → General → Security → API Key
   - Copy to `PROWLARR_API_KEY` in .env
   
   **Verify .env File:**
   ```bash
   # Check all required variables are set (no CHANGEME values)
   grep -E "^[A-Z_]+=CHANGEME" .env
   # Should return no results
   
   # Verify token length (should be 64 characters)
   grep EVENT_COLLECTOR_TOKEN .env | cut -d'=' -f2 | wc -c
   ```

#### Phase 1: Stack Deployment

1. **Deploy Core Services**
   ```bash
   ./deploy.sh check    # Verify prerequisites
   ./deploy.sh deploy   # Full deployment
   ```

2. **Initial Verification**
   - Grafana: http://192.168.10.10:3000 (admin/admin)
   - Prometheus: http://192.168.10.10:9090
   - Event Collector health: http://192.168.10.10:8088/health

#### Phase 2: OPNsense Integration

1. **Configure Remote Syslog Output**
   - Log into OPNsense WebUI: https://192.168.10.1
   - Navigate to: System → Settings → Logging / Targets
   - Click "Add" to create new log target
   - **Configuration:**
     - Enabled: ✓ Checked
     - Transport: TCP
     - Applications: Firewall, System, Unbound (select all relevant)
     - Levels: Info, Notice, Warning, Error, Critical, Alert, Emergency
     - Facilities: All facilities
     - Hostname: 192.168.10.10
     - Port: 514
     - Certificate: (leave empty for TCP)
     - Format: RFC5424
   - Click "Save" and "Apply changes"
   
   **Verification:**
   ```bash
   # Generate test log entry from OPNsense
   logger "Test syslog message from OPNsense"
   
   # Check if logs reach Promtail (after deployment)
   docker-compose logs promtail | grep "Test syslog"
   ```

2. **Configure Firewall Rule Logging**
   - Navigate to: Firewall → Rules → WAN
   - **For each rule you want to monitor:**
     - Click pencil icon to edit rule
     - **Advanced Options:**
       - Log: ✓ Enable logging for this rule
       - Description: Add descriptive label (e.g., "Block-China-SSH", "Allow-VPN-Access")
     - Click "Save" and "Apply changes"
   
   **Important:** Rule descriptions become `rule_label` in logs for filtering
   
   **NAT Rules (for internal traffic monitoring):**
   - Navigate to: Firewall → NAT → Port Forward
   - Edit existing rules to add logging and descriptions
   - Example descriptions: "Jellyfin-External", "SSH-Access", "Media-Services"

3. **SNMP Configuration**
   - Navigate to: Services → SNMP
   - **General Settings:**
     - Enable: ✓ Checked
     - Contact: admin@home.local
     - Location: Home Network
     - Community: `public` (note: update configs/prometheus/prometheus.yml if changed)
   - **Access Restrictions:**
     - Networks: `192.168.10.10/32`
     - Users: (leave empty for v2c)
   - **Advanced:**
     - Listen Interfaces: LAN (192.168.10.1)
     - Bind Interface: (leave empty)
   - Click "Save" and "Apply changes"
   
   **Verification:**
   ```bash
   # Test SNMP access from dashboard host
   snmpwalk -v2c -c public 192.168.10.1 1.3.6.1.2.1.2.2.1.2
   # Should return interface names including wg1
   
   # Test interface counters
   snmpwalk -v2c -c public 192.168.10.1 1.3.6.1.2.1.2.2.1.10
   # Should return byte counters for all interfaces
   ```

4. **Unbound Remote Control Configuration**
   - Navigate to: Services → Unbound DNS → Advanced
   - **Remote Control Settings:**
     - Enable: ✓ Enable remote control
     - Port: 8953 (default)
     - Interface: 127.0.0.1, 192.168.10.1
     - Access Control: 192.168.10.10/32
   - Click "Save" and "Apply changes"
   
   **Generate Certificates (if not exist):**
   - SSH to OPNsense: `ssh root@192.168.10.1`
   - Run: `unbound-control-setup`
   - Verify certificates created in `/var/unbound/`
   
   **Test Remote Control:**
   ```bash
   # From dashboard host (after certificate copy)
   unbound-control -c ./unbound-certs/unbound_control.pem stats
   ```

#### Phase 3: AdGuard Home Integration

1. **Enable Prometheus Metrics**
   - Access AdGuard WebUI: http://192.168.10.1:3000 (confirm port)
   - Navigate to: Settings → General Settings
   - **Statistics Configuration:**
     - Statistics: ✓ Enable statistics
     - Statistics interval: 24 hours
     - Query log: ✓ Enable query log
     - Query log interval: 2160 hours (90 days)
     - Anonymize client IP: ✗ Disabled (needed for monitoring)
   
   **Enable Prometheus Metrics:**
   - If available in UI: Settings → General → Prometheus metrics
   - Or edit AdGuard config file manually (see below)
   
   **Manual Configuration (if needed):**
   ```bash
   # SSH to AdGuard host (usually OPNsense)
   ssh root@192.168.10.1
   
   # Edit AdGuard configuration
   nano /var/db/adguardhome/AdGuardHome.yaml
   
   # Add/modify prometheus section:
   prometheus:
     enabled: true
     address: 192.168.10.1:3000
     path: /metrics
   
   # Restart AdGuard
   service adguardhome restart
   ```
   
   **Verify Metrics Endpoint:**
   ```bash
   curl http://192.168.10.1:3000/control/metrics
   # Should return Prometheus formatted metrics
   ```

2. **Configure Query Log Syslog Output**
   
   **Method 1: AdGuard WebUI (if available)**
   - Settings → Logging → Syslog
   - Server: 192.168.10.10
   - Port: 515
   - Protocol: TCP
   
   **Method 2: Manual Configuration**
   ```bash
   # Edit AdGuard config
   nano /var/db/adguardhome/AdGuardHome.yaml
   
   # Add syslog configuration:
   log:
     file: ""
     max_backups: 0
     max_size: 100
     max_age: 3
     compress: false
     local_time: false
     verbose: false
     syslog:
       enabled: true
       facility: "LOG_LOCAL0"
       server_addr: "192.168.10.10:515"
   
   # Restart AdGuard
   service adguardhome restart
   ```
   
   **Verification:**
   ```bash
   # Generate test DNS query
   nslookup test.example.com 192.168.10.1
   
   # Check if query appears in Promtail logs (after deployment)
   docker-compose logs promtail | grep "test.example.com"
   ```

3. **Confirm AdGuard Admin Interface Port**
   
   **CRITICAL:** Verify actual AdGuard admin port
   ```bash
   # Check AdGuard listening ports
   netstat -tlnp | grep AdGuard
   
   # Common ports: 3000, 8080, 80
   # Test access:
   curl -I http://192.168.10.1:3000/
   curl -I http://192.168.10.1:8080/
   ```
   
   **If port is NOT 3000:**
   - Update `configs/prometheus/prometheus.yml`
   - Change line: `- targets: ['192.168.10.1:3000']`
   - To actual port: `- targets: ['192.168.10.1:XXXX']`

#### Phase 4: Media Services Integration

1. **qBittorrent**
   - Create monitor user with read-only permissions
   - Username: `monitor`
   - Password: (use value from .env file)

2. **Sonarr Instances Configuration**
   
   **Sonarr Main (8989):**
   - Access: http://192.168.10.10:8989
   - Settings → General → Security → API Key (copy to `SONARR_MAIN_API_KEY`)
   - Settings → Connect → Add → Webhook
     - Name: "OPNsense Stats Dashboard"
     - URL: `http://192.168.10.10:8088/webhook/sonarr/main`
     - Method: POST
     - Username: (leave empty)
     - Password: (leave empty)
     - **Triggers:**
       - ✓ On Grab
       - ✓ On Import
       - ✓ On Upgrade
       - ✓ On Rename
       - ✓ On Series Delete
       - ✓ On Episode File Delete
       - ✓ On Health Issue
     - **Custom Headers:**
       - Key: `X-Auth-Token`
       - Value: `[EVENT_COLLECTOR_TOKEN from .env]`
   
   **Sonarr Cartoons (8990):**
   - Repeat above steps with URL: `http://192.168.10.10:8088/webhook/sonarr/cartoons`
   - API Key to: `SONARR_CARTOONS_API_KEY`
   
   **Sonarr Anime (8991):**
   - Repeat above steps with URL: `http://192.168.10.10:8088/webhook/sonarr/anime`
   - API Key to: `SONARR_ANIME_API_KEY`

3. **Radarr Instances Configuration**
   
   **Radarr Main (7878):**
   - Access: http://192.168.10.10:7878
   - Settings → General → Security → API Key (copy to `RADARR_MAIN_API_KEY`)
   - Settings → Connect → Add → Webhook
     - Name: "OPNsense Stats Dashboard"
     - URL: `http://192.168.10.10:8088/webhook/radarr/main`
     - Method: POST
     - **Triggers:**
       - ✓ On Grab
       - ✓ On Import
       - ✓ On Upgrade
       - ✓ On Rename
       - ✓ On Movie Delete
       - ✓ On Movie File Delete
       - ✓ On Health Issue
     - **Custom Headers:**
       - Key: `X-Auth-Token`
       - Value: `[EVENT_COLLECTOR_TOKEN from .env]`
   
   **Radarr Cartoons (7879):**
   - Repeat above steps with URL: `http://192.168.10.10:8088/webhook/radarr/cartoons`
   - API Key to: `RADARR_CARTOONS_API_KEY`
   
   **Radarr Anime (7880):**
   - Repeat above steps with URL: `http://192.168.10.10:8088/webhook/radarr/anime`
   - API Key to: `RADARR_ANIME_API_KEY`

4. **Prowlarr Configuration**
   - Access: http://192.168.10.10:9696
   - Settings → General → Security → API Key (copy to `PROWLARR_API_KEY`)
   - Settings → Connect → Add → Webhook
     - Name: "OPNsense Stats Dashboard"
     - URL: `http://192.168.10.10:8088/webhook/prowlarr/main`
     - Method: POST
     - **Triggers:**
       - ✓ On Health Issue
       - ✓ On Application Update
     - **Custom Headers:**
       - Key: `X-Auth-Token`
       - Value: `[EVENT_COLLECTOR_TOKEN from .env]`

5. **Webhook Testing**
   ```bash
   # Test webhook endpoints before configuring services
   EVENT_TOKEN="your_event_collector_token_here"
   
   # Test Sonarr webhook
   curl -X POST http://192.168.10.10:8088/webhook/sonarr/main \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: $EVENT_TOKEN" \
     -d '{"action":"test","title":"Test Series","quality":"1080p"}'
   
   # Test Radarr webhook
   curl -X POST http://192.168.10.10:8088/webhook/radarr/main \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: $EVENT_TOKEN" \
     -d '{"action":"test","title":"Test Movie","quality":"1080p"}'
   
   # Check Event Collector logs
   tail -f /var/log/event-collector/events-$(date +%Y-%m-%d).jsonl
   ```

#### Phase 5: Validation Testing

1. **Network Connectivity**
   ```bash
   # Test from OPNsense
   logger "Test pf log entry"
   
   # Test SNMP
   snmpwalk -v2c -c public 192.168.10.1 1.3.6.1.2.1.2.2.1.10
   ```

2. **Webhook Testing**
   ```bash
   # Test Event Collector
   curl -X POST http://192.168.10.10:8088/webhook/test/main \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: YOUR_TOKEN" \
     -d '{"action":"test","title":"Test Event"}'
   ```

3. **GeoIP Validation**
   - Generate external traffic to trigger firewall blocks
   - Check Grafana WAN Threat Map for country markers
   - Verify coordinates populate correctly

#### AdGuard Admin Interface Confirmation

**REMINDER:** Confirm AdGuard admin interface port
- Current assumption: 192.168.10.1:3000
- Verify actual port and update Prometheus scrape config if different

#### Troubleshooting Commands

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs prometheus
docker-compose logs loki
docker-compose logs promtail
docker-compose logs event-collector

# Restart specific service
docker-compose restart promtail

# Check Prometheus targets
curl http://192.168.10.10:9090/api/v1/targets

# Check Loki ingestion
curl http://192.168.10.10:3100/ready

# Verify Event Collector logs
tail -f /var/log/event-collector/events-$(date +%Y-%m-%d).jsonl
```

#### Security Hardening (Optional)

1. **Change Default Passwords**
   - Grafana admin password
   - Generate strong Event Collector token

2. **Firewall Rules**
   - OPNsense → Allow only dashboard host to SNMP/syslog ports
   - Block external access to monitoring ports

3. **SSL/TLS** (Optional)
   - Configure reverse proxy with SSL termination
   - Use Let's Encrypt for certificates if external access needed
