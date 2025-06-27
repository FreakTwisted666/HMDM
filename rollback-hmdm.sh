#!/bin/bash

echo "=============================================="
echo "HMDM Rollback Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Stop and remove containers
print_status "Stopping HMDM containers..."
docker-compose down

if [ $? -eq 0 ]; then
    print_status "HMDM containers stopped successfully"
else
    print_warning "Some containers may not have stopped cleanly"
fi

# Step 2: Remove HMDM-related containers
print_status "Removing HMDM containers..."
docker rm $(docker ps -aq --filter name=hmdm) 2>/dev/null || print_warning "No HMDM containers to remove"

# Step 3: Clean up networks
print_status "Cleaning up Docker networks..."
docker network prune -f >/dev/null 2>&1

# Step 4: Optional: Clean up volumes (commented out by default to preserve data)
# Uncomment the following lines if you want to remove persistent data
# print_warning "Cleaning up volumes (this will remove persistent data)..."
# docker volume prune -f >/dev/null 2>&1

# Step 5: Clean up images (optional)
read -p "Do you want to remove HMDM images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing HMDM images..."
    docker rmi $(docker images --filter reference=*hmdm* -q) 2>/dev/null || print_warning "No HMDM images to remove"
    docker rmi headwindmdm/hmdm:0.1.5 2>/dev/null || print_warning "Base HMDM image not found"
fi

# Step 6: System cleanup
print_status "Performing system cleanup..."
docker system prune -f >/dev/null 2>&1

echo "=============================================="
print_status "Rollback completed!"
echo "=============================================="
echo "Current Docker status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
print_status "To redeploy HMDM, run: ./deploy-hmdm.sh"
echo "=============================================="