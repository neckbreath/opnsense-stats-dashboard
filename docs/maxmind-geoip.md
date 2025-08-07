### MaxMind GeoIP Setup

Purpose: enable GeoIP enrichment in Promtail for pf and Nginx client IPs.

#### Steps
1. Create a free MaxMind account (`GeoLite2`)
2. Generate a license key
3. Download `GeoLite2-City.mmdb` (tarball) from MaxMind
4. Extract `GeoLite2-City.mmdb`
5. Place it at `configs/promtail/GeoLite2-City.mmdb`

Promtail config references:
- `db: /etc/promtail/GeoLite2-City.mmdb`
- Docker Compose mounts: `./configs/promtail/GeoLite2-City.mmdb:/etc/promtail/GeoLite2-City.mmdb:ro`

#### Update policy
- MaxMind updates weekly; set a monthly reminder to refresh

#### Privacy
- GeoLite2 is coarse location; acceptable for home monitoring
