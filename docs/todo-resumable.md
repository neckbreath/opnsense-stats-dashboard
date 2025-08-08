# OPNsense Stats Dashboard - Resumable Progress

## ✅ COMPLETED PHASES

### Phase 0: Prerequisites - COMPLETED ✅
- **MaxMind GeoIP**: `GeoLite2-City.mmdb` placed in `/home/alex/config/opnsense-stats-dashboard/promtail-maxmind/`
- **Unbound Certificates**: Extracted and placed in `/home/alex/config/opnsense-stats-dashboard/unbound-certs/`
  - `unbound_control.key`, `unbound_control.pem`, `unbound_server.key`, `unbound_server.pem`
- **Environment File**: Created `/home/alex/config/opnsense-stats-dashboard/.env` with secure 64-char EVENT_COLLECTOR_TOKEN

### Phase 1: Stack Deployment - COMPLETED ✅
- **Docker Compose**: Full monitoring stack deployed successfully
- **Network**: `monitoring` Docker network created and all services connected
- **Services Running**: Prometheus, Loki, Grafana, Promtail, SNMP exporter, Unbound exporter, media exporters
- **Bind Addresses**: All services bound to `192.168.10.10` (LAN IP only)

### Phase 2: OPNsense Integration - COMPLETED ✅ 
**CRITICAL: Custom rsyslog solution implemented due to syslog format incompatibility**

#### ⚠️ Major Troubleshooting - Syslog Format Issue RESOLVED
**Problem**: OPNsense sends BSD syslog (RFC3164) but Promtail expects RFC5424 format
**Error**: `"expecting a version value in the range 1-999 [col 5]"`
**Solution**: Deployed intermediate rsyslog container to convert formats

#### 🔧 Configuration Changes Made During Troubleshooting:

1. **Created rsyslog Container** (NEW):
   - **File**: `/home/alex/config/opnsense-stats-dashboard/Dockerfile.rsyslog`
   - **Content**: Alpine-based rsyslog container with UDP receiver
   - **Port**: Listens on UDP 1514 for OPNsense logs

2. **Created rsyslog Configuration** (NEW):
   - **File**: `/home/alex/config/opnsense-stats-dashboard/rsyslog.conf`
   - **Purpose**: Receives BSD syslog and writes to files that Promtail can tail
   - **Template**: Custom format for OPNsense log compatibility

3. **Modified docker-compose.yml** (MODIFIED):
   - **Added rsyslog service**:
     ```yaml
     rsyslog:
       build:
         context: .
         dockerfile: Dockerfile.rsyslog
       container_name: rsyslog
       hostname: rsyslog
       volumes:
         - ./opnsense-logs:/var/log/opnsense
       ports:
         - "192.168.10.10:1514:1514/udp"  # Changed from 514 to 1514
       networks:
         - monitoring
       restart: unless-stopped
     ```
   - **Added volume mount**: `./opnsense-logs:/var/log/opnsense:ro` to Promtail

4. **Modified Promtail Configuration** (MAJOR CHANGE):
   - **File**: `/home/alex/config/opnsense-stats-dashboard/configs/promtail/promtail.yml`
   - **Changed from**: Direct syslog receiver approach
   - **Changed to**: File-based log tailing approach
   - **Key change**: 
     ```yaml
     # OPNsense firewall logs via file (bypass syslog parser issues)
     - job_name: opnsense-firewall-logs
       static_configs:
       - targets:
           - localhost
         labels:
           job: opnsense-firewall
           host: opnsense  
           env: home
           __path__: /var/log/opnsense/*.log
     ```

5. **OPNsense Remote Logging Configuration**:
   - **Location**: System → Settings → Logging → Remote
   - **Server**: `192.168.10.10`
   - **Port**: `1514` (UDP)
   - **Contents**: Firewall, System, DHCP, Unbound selected

#### 🔌 Final Working Architecture:
```
OPNsense → UDP:1514 → rsyslog container → /var/log/opnsense/firewall.log → Promtail → Loki
```

#### ✅ OPNsense Configuration Completed:
- **SNMP**: Plugin `os-net-snmp` installed and configured
  - Community: `monitoring`, Contact: `admin@homebase`, Location: `homebase`
  - Network: `192.168.10.0/24` access allowed
- **Unbound Remote Control**: Enabled with certificates exported
- **Firewall Logging**: All rules configured with descriptive labels and logging enabled
- **Remote Syslog**: Configured to send logs to monitoring host on UDP:1514

#### 📊 Data Flow Verification SUCCESSFUL:
- **Log Volume**: 544KB+ of real firewall logs ingested
- **Log Types**: Firewall (filterlog), DHCP (dhcpd), DNS (unbound), ICMPv6
- **Loki Integration**: 79 log entries confirmed in Loki with job="opnsense-firewall"
- **Traffic Coverage**: IPv4 and IPv6 traffic being captured with full packet metadata

### Phase 3: AdGuard Integration - COMPLETED ✅

#### ✅ AdGuard Metrics Integration COMPLETED:
- **AdGuard Exporter**: Deployed `sfragata/adguardhome_exporter:latest` container
- **Docker Configuration**: 
  ```yaml
  adguard_exporter:
    image: sfragata/adguardhome_exporter:latest
    container_name: adguard_exporter
    command:
      - "--host=192.168.10.1"
      - "--port=3000"
    ports:
      - "192.168.10.10:9617:9311"
  ```
- **Prometheus Integration**: Successfully scraping AdGuard metrics on port 9311
- **Working Metrics**: DNS query types, filter status, blocked domains, client statistics
- **Verification**: `adguard_exporter_build_info{adguard_version="v0.107.64"}` confirmed in Prometheus

#### ✅ AdGuard Query Log Integration COMPLETED:
- **Syslog Configuration**: rsyslog container configured to receive AdGuard logs on port 1514
- **Mixed Log Handling**: AdGuard and OPNsense logs both routed to `/var/log/opnsense/firewall.log`
- **Promtail Pipeline**: Advanced pipeline with content-based log separation:
  - AdGuard logs: Parsed with `log_type="adguard"` label
  - Firewall logs: Parsed with `log_type="firewall"` label
  - Content matching: `|~ "AdGuardHome.*query"` vs `|~ "filterlog"`
- **Loki Integration**: Verified AdGuard query logs ingested with proper label extraction:
  - `client_ip`, `client_name`, `domain`, `query_type`, `status`, `elapsed_ms`, `upstream`, `rule`
- **Test Results**: Successfully parsed sample query: `github.com A from 192.168.10.99 allowed 18ms upstream 8.8.8.8`

#### ⚠️ AdGuard Home Native Limitation:
**Important**: AdGuard Home does NOT currently support native syslog export for query logs (GitHub issues #958, #1346).

#### ✅ API Integration Solution IMPLEMENTED:
Since native syslog isn't available, we've implemented a complete API-based solution:

**🔧 AdGuard API Collector Service:**
- **Container**: `adguard_collector` built from `./adguard-collector/`
- **Functionality**: Polls AdGuard Home REST API every 30 seconds
- **API Endpoint**: `GET /control/querylog` with HTTP Basic Auth  
- **State Management**: Persistent timestamps prevent duplicate processing
- **Syslog Forwarding**: Formats API responses as syslog messages to rsyslog:1514

**📊 Data Flow Architecture:**
```
AdGuard Home API → Collector Service → rsyslog → Promtail → Loki
```

**🔑 Configuration Required:**
1. **Environment**: Set `ADGUARD_PASSWORD=your_password` in `.env`
2. **AdGuard Access**: Ensure API access enabled with admin credentials
3. **Network**: Verify connectivity from monitoring host to AdGuard Home

**📋 Integration Status:**
- **API Collector**: Built and ready for deployment
- **Docker Integration**: Fully integrated into docker-compose.yml
- **Syslog Pipeline**: Compatible with existing infrastructure
- **Promtail Parsing**: Uses same pipeline as native syslog (content-based routing)
- **State Persistence**: Volume mounted for crash recovery

**📖 Documentation**: See `docs/adguard-api-integration.md` for complete implementation details

**🚀 Deployment Ready**: Run `docker-compose up -d adguard_collector` after password configuration

### ✅ Verification (Today)
- Synthetic AdGuard-style syslog sent to rsyslog and confirmed in `opnsense-logs/firewall.log`
- Same synthetic entry visible in Loki via `{job="opnsense-mixed"}` query
- `adguard_exporter` metrics endpoint returning 200 OK on `:9617/metrics`
- `loki` ready endpoint returns `ready`
- `grafana` reachable (302 to `/login`)
- `adguard_collector` polling AdGuard API and forwarding to rsyslog every 30s

## 🔄 PENDING PHASES

### Phase 4: Media Services Integration - IN PROGRESS  
- Exporters defined and running for qBittorrent, Sonarr x3, Radarr x3, Prowlarr
- Event Collector service built and started; JSONL pipeline in Promtail configured
- NEXT: Configure webhooks in services to Event Collector and validate ingestion
  - Sonarr: `/webhook/sonarr/{main|cartoons|anime}` (ports 8989, 8991, 8990)
  - Radarr: `/webhook/radarr/{main|cartoons|anime}`
  - Prowlarr: `/webhook/prowlarr/main`
  - Header: `X-Auth-Token: $EVENT_COLLECTOR_TOKEN`

### Phase 5: Validation & Testing - PENDING
- Verify all Grafana dashboards display data correctly
- Test GeoIP enrichment on firewall logs
- Validate retention policies and storage usage
- Perform end-to-end monitoring stack health checks

## ⚠️ IMPORTANT NOTES FOR FUTURE SESSIONS

1. **Working Directory**: Always use `/home/alex/config/opnsense-stats-dashboard/` as base
2. **Log Files Location**: OPNsense logs appear in `/home/alex/config/opnsense-stats-dashboard/opnsense-logs/firewall.log`
3. **rsyslog Container**: Critical component - do not remove or modify without understanding the syslog format issue
4. **Port Configuration**: OPNsense sends to UDP:1514 (not standard 514) due to rsyslog container setup
5. **Volume Mounts**: Promtail has read-only access to opnsense-logs directory via bind mount
6. **Network Configuration**: All services bound to `192.168.10.10` (not localhost)

## ▶️ NEXT ACTIONS (Phase 4)
1. Populate `.env` with all media API keys and `EVENT_COLLECTOR_TOKEN`
2. Configure Sonarr/Radarr/Prowlarr webhooks to Event Collector URLs
3. Generate test events; confirm JSONL created under `/var/log/event-collector/`
4. Verify `{job="event-collector"}` logs appear in Loki and Grafana dashboard panels
