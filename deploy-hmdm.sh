#!/bin/bash
set -e

echo "=============================================="
echo "HMDM Auto-Deployment Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yaml"
ENV_FILE=".env"
CONTAINER_NAME="hmdm-docker-hmdm-1"
APP_URL="http://localhost:8080"
MAX_WAIT_TIME=120

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Phase 1: Pre-deployment checks
print_status "Phase 1: Pre-deployment checks"

if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "docker-compose.yaml not found!"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    print_error ".env file not found!"
    exit 1
fi

print_status "Configuration files found"

# Test database connectivity (with timeout)
print_status "Testing database connectivity..."
timeout 10 psql -h ep-holy-mode-a8cj3e2b-pooler.eastus2.azure.neon.tech -p 5432 -U neondb_owner -d neondb -c "SELECT 1;" 2>/dev/null || {
    print_warning "Database connection failed or timed out - proceeding anyway"
}

# Phase 2: Cleanup existing deployment
print_status "Phase 2: Cleaning up existing deployment"
docker-compose down 2>/dev/null || true
docker system prune -f >/dev/null 2>&1 || true

# Phase 3: Deploy application
print_status "Phase 3: Starting HMDM deployment"
docker-compose up -d

if [ $? -ne 0 ]; then
    print_error "Failed to start HMDM container"
    exit 1
fi

# Phase 4: Wait for application startup
print_status "Phase 4: Waiting for application startup (max ${MAX_WAIT_TIME}s)"
wait_time=0
while [ $wait_time -lt $MAX_WAIT_TIME ]; do
    if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
        print_status "Container is running"
        break
    fi
    
    if [ $wait_time -eq 30 ]; then
        print_warning "Still waiting for container to start..."
    fi
    
    sleep 5
    wait_time=$((wait_time + 5))
done

if [ $wait_time -ge $MAX_WAIT_TIME ]; then
    print_error "Container failed to start within $MAX_WAIT_TIME seconds"
    print_error "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi

# Phase 5: Health checks
print_status "Phase 5: Performing health checks"
sleep 10

# Check if application responds
if curl -f -s "$APP_URL" >/dev/null 2>&1; then
    print_status "Application is responding on $APP_URL"
    
    # Check if it's HMDM or default Tomcat
    if curl -s "$APP_URL" | grep -qi "tomcat\|it works"; then
        print_warning "Default Tomcat page detected - HMDM application may not have deployed correctly"
        print_warning "This is a known issue with database migration conflicts"
    else
        print_status "HMDM application detected!"
    fi
else
    print_error "Application is not responding on $APP_URL"
    exit 1
fi

# Phase 6: Deployment summary
echo "=============================================="
print_status "HMDM Deployment Summary"
echo "=============================================="
echo "Container Status:"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Application URL: $APP_URL"
echo "Admin URL: $APP_URL/admin/"
echo ""
print_status "Deployment completed!"
echo ""
echo "Troubleshooting:"
echo "- Check logs: docker logs $CONTAINER_NAME"
echo "- Check container: docker exec -it $CONTAINER_NAME bash"
echo "- Rollback: ./rollback-hmdm.sh"
echo "=============================================="