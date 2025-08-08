# AdGuard Home API Integration

This document describes the AdGuard Home API integration solution for collecting DNS query logs and forwarding them to the monitoring stack.

## Overview

Since AdGuard Home doesn't natively support syslog export for query logs, we've implemented an API-based collector service that:
1. Periodically polls the AdGuard Home REST API
2. Fetches new query log entries
3. Formats them as syslog messages
4. Forwards to the existing syslog infrastructure
5. Maintains state to avoid duplicate processing

## Architecture

```
AdGuard Home → API Collector → rsyslog → Promtail → Loki
```

## Components

### 1. API Collector Service (`adguard-collector/`)

**Files:**
- `collector.py` - Main Python collector service
- `Dockerfile` - Container definition
- `requirements.txt` - Python dependencies

**Features:**
- HTTP Basic Auth for AdGuard API
- Persistent state management (avoids duplicates)
- Configurable polling interval
- Batch processing with size limits
- Error handling and logging
- Syslog message formatting

### 2. Docker Integration

The collector is integrated into the main `docker-compose.yml` as the `adguard_collector` service with:
- Built from local Dockerfile
- Connected to monitoring network
- Depends on rsyslog service
- Persistent data volume for state

### 3. Environment Configuration

New environment variables in `.env`:
```bash
ADGUARD_PASSWORD=CHANGEME  # AdGuard Home admin password
```

Collector configuration via environment:
- `ADGUARD_HOST`: AdGuard Home IP (default: 192.168.10.1)
- `ADGUARD_PORT`: AdGuard Home port (default: 3000)
- `ADGUARD_USERNAME`: API username (default: admin)
- `ADGUARD_PASSWORD`: API password (from .env file)
- `SYSLOG_HOST`: Syslog destination (default: rsyslog)
- `SYSLOG_PORT`: Syslog port (default: 1514)
- `POLL_INTERVAL`: Seconds between API calls (default: 30)
- `BATCH_SIZE`: Max entries per API call (default: 50)

## AdGuard Home API Details

### Authentication
- Method: HTTP Basic Authentication
- Username: AdGuard Home admin username
- Password: AdGuard Home admin password

### API Endpoint
- **URL**: `GET /control/querylog`
- **Parameters**:
  - `older_than`: RFC3339 timestamp for pagination
  - `limit`: Number of entries to return
  - `search`: Filter by domain or client IP
  - `response_status`: Filter by status (all/filtered/blocked)

### Response Format
```json
{
  "data": [
    {
      "time": "2023-01-01T12:00:00Z",
      "client": "192.168.10.100",
      "question": {
        "name": "example.com",
        "type": "A"
      },
      "answer": [...],
      "reason": "NotFiltered",
      "upstream": "1.1.1.1:53",
      "elapsedMs": 15
    }
  ],
  "oldest": "2023-01-01T11:00:00Z"
}
```

## Syslog Message Format

The collector formats API responses into syslog messages compatible with the existing Promtail pipeline:

```
<16>Aug 8 12:00:00 adguard-collector AdGuardHome: query example.com A from client 192.168.10.100 allowed 15ms upstream 1.1.1.1
```

**Format Components:**
- `<16>`: Priority (local0.info)
- `Aug 8 12:00:00`: Timestamp
- `adguard-collector`: Hostname
- `AdGuardHome`: Program name (matches Promtail filter)
- Message: Query details in expected format

## State Management

The collector maintains state in `/data/collector_state.json`:
```json
{
  "last_timestamp": "2023-01-01T12:00:00Z"
}
```

This prevents reprocessing logs after container restarts and ensures continuous collection without gaps.

## Deployment

### 1. Configure AdGuard Home
- Ensure API access is enabled
- Note the admin username/password
- Verify network connectivity from monitoring host

### 2. Update Configuration
```bash
# Edit .env file
ADGUARD_PASSWORD=your_actual_password
```

### 3. Build and Start
```bash
# Build the collector
docker-compose build adguard_collector

# Start the service
docker-compose up -d adguard_collector
```

### 4. Verify Operation
```bash
# Check collector logs
docker-compose logs -f adguard_collector

# Verify syslog reception
tail -f opnsense-logs/firewall.log | grep AdGuardHome

# Check Loki ingestion
curl "http://192.168.10.10:3100/loki/api/v1/query?query={job=\"opnsense-mixed\"} |~ \"AdGuardHome\""
```

## Monitoring

### Collector Logs
```bash
docker-compose logs adguard_collector
```

Expected log messages:
- `Starting AdGuard Home API Collector`
- `Fetched X query log entries`
- `Sent X query logs to syslog`

### Prometheus Metrics (Future Enhancement)
The collector could be enhanced to expose metrics:
- API request success/failure rate
- Query logs processed per minute
- API response times
- State file operations

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify ADGUARD_PASSWORD in .env
   - Check AdGuard Home admin credentials
   - Ensure API access is enabled

2. **Network Connectivity**
   - Verify ADGUARD_HOST is accessible
   - Check firewall rules
   - Test with: `curl http://192.168.10.1:3000/control/querylog`

3. **No Logs Appearing**
   - Check collector container logs
   - Verify rsyslog is receiving data
   - Test syslog pipeline with manual message

4. **Duplicate Processing**
   - Check state file persistence
   - Verify volume mount: `./adguard-collector-data:/data`
   - Monitor timestamp progression in logs

### Log Analysis
```bash
# Collector internal logs
docker logs adguard_collector

# Syslog reception
grep "AdGuardHome" opnsense-logs/firewall.log

# Loki query logs
curl "http://localhost:3100/loki/api/v1/query?query={log_type=\"adguard\"}"
```

## Performance Considerations

### API Rate Limiting
- AdGuard Home may have rate limits
- Default 30-second poll interval provides balance
- Batch size of 50 entries per request

### Resource Usage
- Minimal CPU/memory footprint
- Network: ~1KB per API request
- Storage: Small state file only

### Scaling
- Single collector instance recommended
- Multiple instances would cause duplicate processing
- Consider increasing BATCH_SIZE for high-volume environments

## Integration with Existing Pipeline

The collector integrates seamlessly with the existing monitoring infrastructure:

1. **rsyslog**: Receives formatted syslog messages
2. **Promtail**: Processes mixed firewall + AdGuard logs
3. **Loki**: Stores with proper labels and indexing
4. **Grafana**: Visualizes DNS query patterns

The Promtail pipeline automatically detects AdGuard logs by content matching (`|~ "AdGuardHome.*query"`) and applies the appropriate parsing rules.

## Future Enhancements

1. **Health Checks**: HTTP endpoint for monitoring
2. **Metrics Export**: Prometheus metrics for observability  
3. **Filtering**: Skip internal/cached queries
4. **Compression**: Batch multiple queries into single syslog message
5. **Retry Logic**: Handle temporary API failures gracefully
6. **Configuration Validation**: Startup checks for connectivity