#!/bin/bash

# OPNsense Stats Dashboard Deployment Script
# Timezone: Australia/Sydney

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_PROJECT_NAME="opnsense-stats-dashboard"
NETWORK_NAME="monitoring"
DASHBOARD_HOST="192.168.10.10"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if we're running on the correct host
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    if [[ "$LOCAL_IP" != "$DASHBOARD_HOST" ]]; then
        print_warning "This script is designed to run on $DASHBOARD_HOST, current IP is $LOCAL_IP"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate environment file
check_env_file() {
    print_status "Checking environment configuration..."
    
    if [[ ! -f ".env" ]]; then
        print_error ".env file not found. Please create it from .env.example"
        exit 1
    fi
    
    # Check required variables
    required_vars=(
        "EVENT_COLLECTOR_TOKEN"
        "QBITTORRENT_MONITOR_PASSWORD"
        "SONARR_MAIN_API_KEY"
        "SONARR_CARTOONS_API_KEY"
        "SONARR_ANIME_API_KEY"
        "RADARR_MAIN_API_KEY"
        "RADARR_CARTOONS_API_KEY"
        "RADARR_ANIME_API_KEY"
        "PROWLARR_API_KEY"
    )
    
    missing_vars=()
    while IFS= read -r line; do
        if [[ $line =~ ^([A-Z_]+)= ]]; then
            var_name="${BASH_REMATCH[1]}"
            if [[ " ${required_vars[@]} " =~ " ${var_name} " ]]; then
                var_value=$(echo "$line" | cut -d'=' -f2-)
                if [[ -z "$var_value" || "$var_value" == "CHANGEME" ]]; then
                    missing_vars+=("$var_name")
                fi
            fi
        fi
    done < .env
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing or invalid environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        exit 1
    fi
    
    print_success "Environment configuration validated"
}

# Function to check GeoIP database
check_geoip() {
    print_status "Checking GeoIP database..."
    
    GEOIP_PATH="./promtail-maxmind/GeoLite2-City.mmdb"
    if [[ ! -f "$GEOIP_PATH" ]]; then
        print_error "GeoLite2-City.mmdb not found at $GEOIP_PATH"
        print_error "Please download from MaxMind and place it in the promtail-maxmind directory"
        exit 1
    fi
    
    # Check if file is recent (less than 60 days old)
    if [[ $(find "$GEOIP_PATH" -mtime +60) ]]; then
        print_warning "GeoIP database is older than 60 days, consider updating"
    fi
    
    print_success "GeoIP database found"
}

# Function to check Unbound certificates
check_unbound_certs() {
    print_status "Checking Unbound certificates..."
    
    cert_files=(
        "unbound-certs/unbound_control.key"
        "unbound-certs/unbound_control.pem"
        "unbound-certs/unbound_server.key"
        "unbound-certs/unbound_server.pem"
    )
    
    missing_certs=()
    for cert_file in "${cert_files[@]}"; do
        if [[ ! -f "$cert_file" ]]; then
            missing_certs+=("$cert_file")
        fi
    done
    
    if [[ ${#missing_certs[@]} -gt 0 ]]; then
        print_error "Missing Unbound certificate files:"
        for cert in "${missing_certs[@]}"; do
            echo "  - $cert"
        done
        print_error "Please export certificates from OPNsense Unbound configuration"
        exit 1
    fi
    
    print_success "Unbound certificates found"
}

# Function to create Docker network
create_network() {
    print_status "Creating Docker network..."
    
    if ! docker network inspect "$NETWORK_NAME" &> /dev/null; then
        docker network create "$NETWORK_NAME"
        print_success "Created network: $NETWORK_NAME"
    else
        print_status "Network $NETWORK_NAME already exists"
    fi
}

# Function to create log directories
create_directories() {
    print_status "Creating log directories..."
    
    sudo mkdir -p /var/log/event-collector
    sudo chown -R $USER:$USER /var/log/event-collector
    
    # Create promtail-maxmind directory if it doesn't exist
    mkdir -p promtail-maxmind
    
    print_success "Directories created"
}

# Function to deploy services
deploy_services() {
    print_status "Deploying services..."
    
    # Build Event Collector
    print_status "Building Event Collector..."
    docker-compose build event-collector
    
    # Start core infrastructure first
    print_status "Starting core infrastructure..."
    docker-compose up -d prometheus loki grafana
    
    # Wait for core services to be ready
    print_status "Waiting for core services to start..."
    sleep 30
    
    # Start data collection services
    print_status "Starting data collection services..."
    docker-compose up -d promtail snmp_exporter unbound_exporter
    
    # Start media exporters
    print_status "Starting media exporters..."
    docker-compose up -d qbittorrent_exporter
    docker-compose up -d sonarr_exporter_main sonarr_exporter_cartoons sonarr_exporter_anime
    docker-compose up -d radarr_exporter_main radarr_exporter_cartoons radarr_exporter_anime
    docker-compose up -d prowlarr_exporter
    
    # Start event collector
    print_status "Starting Event Collector..."
    docker-compose up -d event-collector
    
    print_success "All services deployed"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check service health
    services=(
        "prometheus:9090"
        "loki:3100"
        "grafana:3000"
        "promtail:9080"
        "event-collector:8088"
    )
    
    failed_services=()
    for service in "${services[@]}"; do
        service_name=$(echo "$service" | cut -d':' -f1)
        port=$(echo "$service" | cut -d':' -f2)
        
        if ! curl -s -f "http://$DASHBOARD_HOST:$port/health" &> /dev/null && \
           ! curl -s -f "http://$DASHBOARD_HOST:$port/" &> /dev/null && \
           ! curl -s -f "http://$DASHBOARD_HOST:$port/metrics" &> /dev/null; then
            failed_services+=("$service_name:$port")
        fi
    done
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        print_warning "Some services may not be fully ready:"
        for service in "${failed_services[@]}"; do
            echo "  - $service"
        done
        print_status "This is normal during initial startup. Check again in a few minutes."
    else
        print_success "All services appear to be healthy"
    fi
}

# Function to display access information
show_access_info() {
    print_success "Deployment completed!"
    echo
    echo "Service Access URLs:"
    echo "  Grafana:    http://$DASHBOARD_HOST:3000 (admin/admin)"
    echo "  Prometheus: http://$DASHBOARD_HOST:9090"
    echo "  Loki:       http://$DASHBOARD_HOST:3100"
    echo
    echo "Next Steps:"
    echo "  1. Configure OPNsense syslog to send to $DASHBOARD_HOST:514"
    echo "  2. Configure AdGuard syslog to send to $DASHBOARD_HOST:515"
    echo "  3. Set up webhooks in media services to $DASHBOARD_HOST:8088"
    echo "  4. Check Grafana dashboards for data flow"
    echo
    echo "Log locations:"
    echo "  Event Collector: /var/log/event-collector/"
    echo "  Docker logs:     docker-compose logs [service]"
}

# Function to show phase information
show_phase_info() {
    echo "=========================================="
    echo "OPNsense Stats Dashboard - Phase 0 & 1"
    echo "=========================================="
    echo
    echo "This script implements:"
    echo "  ✓ Phase 0: Prerequisites and setup"
    echo "  ✓ Phase 1: Core stack deployment"
    echo
    echo "Manual configuration still required:"
    echo "  • OPNsense syslog configuration"
    echo "  • AdGuard syslog configuration"
    echo "  • Media service webhook configuration"
    echo "  • GeoIP enrichment testing"
    echo
}

# Main execution
main() {
    show_phase_info
    
    print_status "Starting deployment process..."
    
    check_prerequisites
    check_env_file
    check_geoip
    check_unbound_certs
    create_network
    create_directories
    deploy_services
    
    # Give services time to start
    print_status "Waiting for services to initialize..."
    sleep 60
    
    verify_deployment
    show_access_info
}

# Handle script arguments
case "$1" in
    "check")
        check_prerequisites
        check_env_file
        check_geoip
        check_unbound_certs
        ;;
    "deploy")
        main
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        echo "Usage: $0 {check|deploy|verify}"
        echo "  check   - Check prerequisites only"
        echo "  deploy  - Full deployment"
        echo "  verify  - Verify existing deployment"
        exit 1
        ;;
esac
