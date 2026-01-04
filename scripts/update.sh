#!/bin/bash
set -e

echo "================================"
echo "SSL Certificate Setup Script"
echo "================================"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
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

# Check if nginx is running
if ! docker-compose ps | grep -q "nginx.*Up"; then
    echo "Error: nginx container is not running"
    echo "Please run ./scripts/deploy.sh first"
    exit 1
fi

# Request certificate
echo "Requesting SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN \
    -d www.$DOMAIN

# Check if certificate was obtained successfully
if [ ! -d "./volumes/certbot/conf/live/$DOMAIN" ]; then
    echo "Error: Failed to obtain SSL certificate"
    echo "Please check:"
    echo "1. DNS records point to this server"
    echo "2. Ports 80 and 443 are open"
    echo "3. Domain is accessible from the internet"
    exit 1
fi

echo "Certificate obtained successfully!"

# Update nginx configuration with SSL
echo "Updating nginx configuration with SSL..."
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

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location /static/ {
        alias /app/staticfiles/;
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

# Reload nginx
echo "Reloading nginx..."
docker-compose exec nginx nginx -s reload

# Start certbot for auto-renewal
echo "Starting certbot for automatic renewal..."
docker-compose up -d certbot

echo ""
echo "================================"
echo "SSL Setup Complete!"
echo "================================"
echo ""
echo "Your site is now available at:"
echo "https://$DOMAIN"
echo "https://www.$DOMAIN"
echo ""
echo "Certificates will auto-renew every 12 hours."
echo ""