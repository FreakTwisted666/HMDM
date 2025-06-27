# HMDM Auto-Deployment Guide

## Overview
This guide provides automated deployment scripts for Headwind Mobile Device Management (HMDM) using Docker.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- PostgreSQL client (psql) for database testing
- Network access to external Neon database

### Basic Deployment
```bash
# Clone or navigate to HMDM directory
cd hmdm-docker

# Run automated deployment
./deploy-hmdm.sh
```

### Rollback
```bash
# If deployment fails or needs to be undone
./rollback-hmdm.sh
```

## Files Structure
```
hmdm-docker/
├── docker-compose.yaml     # Main Docker configuration
├── .env                   # Environment variables
├── deploy-hmdm.sh         # Automated deployment script
├── rollback-hmdm.sh       # Rollback script
├── DEPLOYMENT_GUIDE.md    # This guide
├── volumes/               # Persistent data
│   ├── work/
│   ├── letsencrypt/
│   └── hmdm-config/
└── templates/             # Configuration templates
```

## Configuration

### Environment Variables (.env)
Key settings in `.env` file:

- `SQL_HOST`: Database hostname
- `SQL_USER/SQL_PASS`: Database credentials  
- `BASE_DOMAIN`: Application domain (localhost:8080 for local)
- `PROTOCOL`: http or https
- `FORCE_RECONFIGURE`: true/false for initial setup

### Docker Compose
The `docker-compose.yaml` configures:
- Port mappings (8080:8080, 31000:31000)
- Volume mounts for persistence
- Environment variable injection
- Health checks

## Known Issues & Solutions

### Issue 1: Default Tomcat Page
**Problem**: Application shows "It works!" Tomcat page instead of HMDM interface

**Causes**:
- Database migration conflicts
- WAR file deployment issues
- Existing ROOT directory conflicts

**Solutions**:
1. Check database connectivity
2. Verify WAR file integrity in `volumes/work/cache/`
3. Remove ROOT directory: `docker exec container rm -rf /usr/local/tomcat/webapps/ROOT`
4. Restart container

### Issue 2: Database Migration Errors
**Problem**: "relation already exists" errors in logs

**Causes**:
- Previous deployment left database schema
- Liquibase migration conflicts

**Solutions**:
1. Set `FORCE_RECONFIGURE=false` in .env
2. Add `LIQUIBASE_SKIP_MIGRATION=true` to environment
3. Reset database schema (if acceptable)

### Issue 3: SSL Certificate Errors
**Problem**: SSL certificate not found errors

**Causes**:
- Missing SSL certificates
- HTTPS configuration without certificates

**Solutions**:
1. Use HTTP-only: Set `PROTOCOL=http`
2. Disable HTTPS: Set `HTTPS_LETSENCRYPT=false`
3. Provide SSL certificates in `/usr/local/tomcat/ssl/`

## Troubleshooting Commands

### Check Container Status
```bash
docker ps --filter name=hmdm
```

### View Logs
```bash
docker logs hmdm-docker-hmdm-1
```

### Access Container
```bash
docker exec -it hmdm-docker-hmdm-1 bash
```

### Test Database Connection
```bash
psql -h ep-holy-mode-a8cj3e2b-pooler.eastus2.azure.neon.tech -U neondb_owner -d neondb -c "SELECT 1;"
```

### Check Application Response
```bash
curl -I http://localhost:8080
curl http://localhost:8080/rest/public/info
```

### Check WAR Deployment
```bash
docker exec hmdm-docker-hmdm-1 ls -la /usr/local/tomcat/webapps/
```

## Monitoring

### Health Check Endpoint
The application provides health checks at:
- `http://localhost:8080/rest/public/info`

### Automated Monitoring
Create a monitoring script:
```bash
#!/bin/bash
while true; do
  if ! curl -f http://localhost:8080/rest/public/info >/dev/null 2>&1; then
    echo "$(date): HMDM down - restarting..."
    docker-compose restart
  fi
  sleep 60
done
```

## Security Considerations

### Database Access
- Use strong passwords for database credentials
- Restrict database network access
- Enable SSL for database connections in production

### Application Security
- Change default admin credentials after first login
- Use HTTPS in production environments
- Regularly update HMDM version
- Monitor access logs

### Container Security
- Run containers as non-root when possible
- Limit container capabilities
- Use read-only filesystems where appropriate
- Regularly update base images

## Production Deployment

### SSL/HTTPS Setup
1. Obtain SSL certificates
2. Update `.env`: `PROTOCOL=https`, `HTTPS_LETSENCRYPT=true`
3. Configure reverse proxy (nginx) if needed
4. Update `BASE_DOMAIN` to actual domain

### Database Considerations
- Use dedicated database server
- Implement regular backups
- Monitor database performance
- Set up database replication if needed

### Scaling Considerations
- Use Docker Swarm or Kubernetes for orchestration
- Implement load balancing
- Use external session storage
- Monitor resource usage

## Support & Resources

### Logs Location
- Application logs: `/usr/local/tomcat/logs/`
- Docker logs: `docker logs hmdm-docker-hmdm-1`

### Configuration Files
- Tomcat config: `/usr/local/tomcat/conf/`
- Application config: `/usr/local/tomcat/work/`

### Official Resources
- HMDM Documentation: https://h-mdm.com/
- Docker Hub: https://hub.docker.com/u/headwindmdm
- GitHub: Search for "headwind-mdm"

## Changelog

- v1.0: Initial automated deployment scripts
- Database migration handling
- SSL configuration options
- Comprehensive troubleshooting guide