### Optional Extensions

- NetFlow/IPFIX with pmacct → ClickHouse/InfluxDB for flow analytics
- ntopng container for deep traffic analysis with nDPI
- VictoriaMetrics single-node replacing Prometheus for longer retention
- Blackbox exporter for ICMP/TCP/TLS checks to critical hosts
- Speedtest exporter daily scheduled tests; track jitter/loss/latency
- Suricata IDS dashboards (if enabled) from syslog data in Loki
- TLS cert expiry dashboards (blackbox TLS probe)
