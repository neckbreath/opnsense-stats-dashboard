### Network Configuration

#### Core Network Topology
- **OPNsense Gateway:** 192.168.10.1
  - AdGuard Home: 192.168.10.1:3000 (metrics endpoint)
  - SNMP: UDP 161 (community: public)
  - Unbound remote-control: TLS enabled
  - WireGuard interface: wg1
- **Dashboard Host:** 192.168.10.10 (monitoring stack + media services)
- **Nginx Server:** 192.168.10.11

#### IPv6 Configuration
- **WireGuard Subnet:** fd:beef:cafe::1/64
- **ULA Prefix:** fd:beef:cafe::/64
- IPv6 configuration details to be provided later

#### Network Restrictions
- ISP: CGNAT (no reliable IPv4 routing for WireGuard)
- LAN traffic: permissive internal routing
- VPN stack: outbound traffic restricted to prevent DNS/IP leaks
- External access: restricted inbound, free internal communication

#### Media Stack Network Architecture
- **Jellyfin:** bare metal on 192.168.10.10
- **Media gathering services:** Docker Compose behind NordLynx VPN
- **Jellyseer:** separate Docker Compose
- **Webhook routing:** media services → 192.168.10.10:8088 (routable within LAN)
