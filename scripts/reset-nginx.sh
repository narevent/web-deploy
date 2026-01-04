#!/bin/bash
set -e

echo "================================"
echo "Reset Nginx Configuration"
echo "================================"
echo ""
echo "This will reset nginx to HTTP-only mode"
echo "Press Ctrl+C to cancel, Enter to continue..."
read

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    exit 1
fi

source .env

if [ -z "$DOMAIN" ]; then
    echo "Error: DOMAIN not set in .env"
    exit 1
fi

echo "Stopping nginx..."
docker-compose stop nginx

echo "Creating HTTP-only configuration for $DOMAIN..."
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

echo "Starting nginx..."
docker-compose up -d nginx

echo ""
echo "================================"
echo "Nginx Reset Complete!"
echo "================================"
echo ""
echo "Your site is now running in HTTP-only mode:"
echo "http://$DOMAIN"
echo ""
echo "To enable HTTPS, run:"
echo "./scripts/setup-ssl.sh"
echo ""