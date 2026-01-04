#!/bin/bash

echo "================================"
echo "Django Docker Troubleshooting"
echo "================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    exit 1
fi

source .env

echo "📋 Configuration:"
echo "   Domain: $DOMAIN"
echo "   Debug: ${DEBUG:-False}"
echo ""

echo "🐳 Docker Status:"
docker-compose ps
echo ""

echo "🔍 Container Health:"
for container in $(docker-compose ps -q); do
    name=$(docker inspect --format='{{.Name}}' $container | sed 's/\///')
    status=$(docker inspect --format='{{.State.Status}}' $container)
    echo "   $name: $status"
done
echo ""

echo "🌐 Port Status:"
echo "   Port 80 (HTTP):"
if sudo netstat -tlnp | grep -q ":80 "; then
    sudo netstat -tlnp | grep ":80 "
else
    echo "   ❌ Not listening"
fi
echo ""
echo "   Port 443 (HTTPS):"
if sudo netstat -tlnp | grep -q ":443 "; then
    sudo netstat -tlnp | grep ":443 "
else
    echo "   ❌ Not listening"
fi
echo ""

echo "📜 SSL Certificate Status:"
if [ -d "./volumes/certbot/conf/live/$DOMAIN" ]; then
    echo "   ✅ Certificates exist for $DOMAIN"
    docker-compose run --rm certbot certificates 2>/dev/null | grep -A 5 "$DOMAIN" || echo "   Run: docker-compose run --rm certbot certificates"
else
    echo "   ❌ No certificates found"
    echo "   Run: ./scripts/setup-ssl.sh"
fi
echo ""

echo "🔥 Firewall Status:"
sudo ufw status | grep -E "(80|443|Status)"
echo ""

echo "📝 Recent Nginx Logs (last 10 lines):"
docker-compose logs --tail=10 nginx 2>/dev/null || echo "   Nginx not running"
echo ""

echo "📝 Recent Web Logs (last 10 lines):"
docker-compose logs --tail=10 web 2>/dev/null || echo "   Web not running"
echo ""

echo "🧪 Testing Nginx Configuration:"
docker-compose exec nginx nginx -t 2>/dev/null || echo "   ❌ Nginx not running or config error"
echo ""

echo "🌍 DNS Check:"
echo "   Resolving $DOMAIN..."
host $DOMAIN 2>/dev/null || echo "   ❌ DNS resolution failed"
echo ""

echo "================================"
echo "Quick Fixes:"
echo "================================"
echo ""
echo "If site not accessible:"
echo "  1. Check DNS: host $DOMAIN"
echo "  2. Check firewall: sudo ufw status"
echo "  3. Restart services: docker-compose restart"
echo ""
echo "If HTTPS not working:"
echo "  1. Verify HTTP works first"
echo "  2. Run: ./scripts/setup-ssl.sh"
echo "  3. Check logs: docker-compose logs nginx"
echo ""
echo "To view live logs:"
echo "  docker-compose logs -f"
echo ""