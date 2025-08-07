### Nginx Access/Error Logs (optional)

Goal: ship Nginx logs from 192.168.10.11 to Loki via Promtail for visibility into local HTTP traffic.

Options:
1) Install a lightweight Promtail agent on 192.168.10.11 to tail files and send to central Loki
2) Export logs over syslog to central Promtail receiver

#### Option 1: Promtail on 192.168.10.11
- Install Promtail container or binary on the Nginx host
- Example scrape config:
```
scrape_configs:
  - job_name: nginx-access
    static_configs:
      - targets: [localhost]
        labels:
          job: nginx
          host: nginx-01
          app: nginx
          __path__: /var/log/nginx/access.log
    pipeline_stages:
      - regex:
          expression: '^(?P<client_ip>[^ ]*) [^ ]* [^ ]* \[(?P<ts>[^\]]+)\] "(?P<method>\S+) (?P<path>[^ ]+) (?P<proto>[^"]+)" (?P<status>\d{3}) (?P<bytes>\d+) "(?P<referrer>[^"]*)" "(?P<ua>[^"]*)".*'
      - labels:
          client_ip:
          method:
          status:
      - timestamp:
          source: ts
          format: '02/Jan/2006:15:04:05 -0700'
```

#### Option 2: Syslog from Nginx
- In Nginx, configure syslog output for access/error logs targeting central Promtail TCP 516 (add a receiver)
- Example in `nginx.conf`:
```
access_log syslog:server=192.168.10.X:516,facility=local7,tag=nginx,severity=info combined;
error_log syslog:server=192.168.10.X:516,facility=local7,tag=nginx,severity=info;
```
- Add Promtail syslog job listening on 0.0.0.0:516 and parse fields as needed

#### Dashboards
- 4xx/5xx rates, top paths, client IPs, TLS versions (if logged)
- GeoIP on `client_ip` if desired (same geoip stage as pf)
