### Media Stack Topology

#### Service Locations
All services run on **192.168.10.10** unless specified otherwise.

#### Port Assignments

**Core Media Services:**
- **qBittorrent:** :8080 (default port, behind NordLynx)
- **Prowlarr:** :9696 (default port, behind NordLynx)
- **Jellyfin:** :8096 (default port, bare metal)
- **Jellyseer:** :5055 (default port, separate Docker Compose)

**Sonarr Instances (incremental ports):**
- **Main Library:** :8989 (default port, largest library, highest activity)
- **Cartoons:** :8991 (smaller library, lower activity)
- **Anime:** :8990 (smaller library, lower activity)

**Radarr Instances (incremental ports):**
- **Main Library:** :7878 (default port, largest library, highest activity)
- **Cartoons:** :7879 (smaller library, lower activity)
- **Anime:** :7880 (smaller library, lower activity)

#### Instance Purpose
- **Main instances:** Primary libraries with highest content volume and activity
- **Cartoons instances:** Separate content category, smaller collection
- **Anime instances:** Separate content category, smaller collection

#### Network Isolation
- **VPN services:** qBittorrent, Prowlarr run behind NordLynx
- **Direct services:** Jellyfin, Jellyseer, Sonarr, Radarr accessible directly on LAN
- **Webhook connectivity:** All services can reach Event Collector at 192.168.10.10:8088

#### Monitoring Priority
- **High frequency scraping:** Main instances (higher activity)
- **Standard frequency scraping:** Cartoon/anime instances (lower activity)
- **Event collection:** All instances generate webhook events for import/upgrade/delete actions
