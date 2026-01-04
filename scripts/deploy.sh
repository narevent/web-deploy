#!/bin/bash
set -e

echo "================================"
echo "Django Deployment Script"
echo "================================"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Source environment variables
source .env

# Validate required variables
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Error: DOMAIN and EMAIL must be set in .env file"
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Generate SECRET_KEY if not set
if [ -z "$SECRET_KEY" ]; then
    echo "Generating SECRET_KEY..."
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    echo "SECRET_KEY=$SECRET_KEY" >> .env
    echo "✓ SECRET_KEY generated and saved to .env"
fi

# Update ALLOWED_HOSTS if not properly configured
if [[ ! "$ALLOWED_HOSTS" =~ "$DOMAIN" ]]; then
    echo "Updating ALLOWED_HOSTS in .env..."
    sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN/" .env
    source .env
fi

# Create necessary directories
mkdir -p nginx

# Update nginx configuration with domain
echo "Configuring nginx for domain: $DOMAIN"
sed "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/default.conf > nginx/default.conf.tmp
mv nginx/default.conf.tmp nginx/default.conf

# Build and start containers (without SSL initially)
echo "Building Docker images..."
docker-compose build

echo "Starting containers..."
docker-compose up -d web

# Wait for web service to be ready
echo "Waiting for Django to be ready..."
sleep 10

# Check if certificates exist
CERT_EXISTS=false
if [ -d "/etc/letsencrypt/live/$DOMAIN" ] || [ -d "./volumes/certbot/conf/live/$DOMAIN" ]; then
    CERT_EXISTS=true
fi

if [ "$CERT_EXISTS" = false ]; then
    echo ""
    echo "================================"
    echo "SSL certificates not found."
    echo "Creating HTTP-only configuration..."
    echo "================================"
    echo ""
    
    # Create HTTP-only nginx config (no redirect to HTTPS)
    cat > nginx/default.conf << EOF
upstream django {
    server web:8000;
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location /static/ {
        alias /core/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://django;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        proxy_buffering off;
    }
}
EOF
fi

# Start nginx
docker-compose up -d nginx

echo ""
echo "================================"
echo "Deployment Complete!"
echo "================================"
echo ""
echo "Your application is now running at:"
echo "http://$DOMAIN"
echo ""
echo "Admin credentials:"
echo "Username: admin"
echo "Password: admin"
echo "URL: http://$DOMAIN/admin"
echo ""
echo "⚠️  IMPORTANT: Change the admin password immediately!"
echo ""
if [ "$CERT_EXISTS" = false ]; then
    echo "⚠️  Running in HTTP mode (no SSL)"
    echo "To enable HTTPS, run:"
    echo "./scripts/setup-ssl.sh"
    echo ""
fi
echo ""