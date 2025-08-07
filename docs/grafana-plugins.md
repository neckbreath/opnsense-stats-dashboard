### Grafana Plugins

Required for described dashboards:
- Sankey panel: e.g., `marcusolsson-sankey-panel` (or any supported Sankey plugin)

Built-in:
- Geomap panel is built-in (Grafana >= 8)

#### Install via Docker env
Add to Grafana service in Docker Compose:
```
GF_INSTALL_PLUGINS=marcusolsson-sankey-panel
```
Multiple plugins can be comma-separated.

#### Validation
- After container start, visit Grafana → Administration → Plugins and verify the Sankey panel is installed.
