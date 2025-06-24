#!/bin/bash
set -e

# Color codes for nice logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Start initialization
log_info "Starting webui container initialization..."

# Check required environment variables
if [ -z "$WEBUI_AGENT_BACKEND_BASE_URL" ]; then
    log_error "WEBUI_AGENT_BACKEND_BASE_URL environment variable is not set!"
    exit 1
fi

log_info "Backend URL: $WEBUI_AGENT_BACKEND_BASE_URL"

# Generate self-signed SSL certificate for HTTP/2 and HTTP/3 support
log_info "Generating self-signed SSL certificate for HTTPS/HTTP2/HTTP3..."
if [ ! -f /etc/ssl/certs/nginx.crt ] || [ ! -f /etc/ssl/private/nginx.key ]; then
    mkdir -p /etc/ssl/certs /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    log_success "SSL certificate generated"
else
    log_info "SSL certificate already exists"
fi

# Process nginx configuration
log_info "Processing nginx configuration template..."
envsubst '${WEBUI_AGENT_BACKEND_BASE_URL}' </etc/nginx/nginx.conf >/tmp/nginx.conf

# Validate nginx configuration
log_info "Validating nginx configuration..."
if nginx -t -c /tmp/nginx.conf; then
    log_success "Nginx configuration is valid"
    cp /tmp/nginx.conf /etc/nginx/nginx.conf
    log_success "Nginx configuration updated"
else
    log_error "Invalid nginx configuration!"
    exit 1
fi

# Show directory structure for debugging
log_info "Current directory structure:"
tree . -L 2

# Start nginx
log_info "Starting nginx..."
log_success "Webui is ready and running!"

# Forward nginx logs to stdout/stderr for container logging
nginx -g 'daemon off;'
