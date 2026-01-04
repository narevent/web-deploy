#!/bin/bash
DOMAIN="vumgames.com"
EMAIL="admin@$DOMAIN"

# 1. Start containers (Nginx will fail at first because no SSL cert exists)
docker-compose up -d

# 2. Obtain SSL Certificate (Staging first to avoid rate limits, then real)
docker-compose run --rm certbot certonly --webroot --webroot-path=/app/static \
    --email $EMAIL --agree-tos --no-eff-email \
    -d $DOMAIN

# 3. Reload Nginx to pick up the new certs
docker-compose restart nginx