# Django Docker Deployment Template

A production-ready Django application template with Docker, Nginx, and automated SSL setup using Let's Encrypt.

## Features

- 🚀 One-command deployment
- 🔒 Automatic HTTPS with Let's Encrypt
- 🐳 Docker containerization
- 🗄️ SQLite database (upgrade to PostgreSQL if needed)
- 🔄 Automatic SSL certificate renewal
- 📦 Static file serving with Nginx
- 🛡️ Production-ready security settings
- 🔧 Easy updates and rollbacks

## Prerequisites

- A VPS (Ubuntu 20.04+ recommended)
- A domain name pointing to your VPS IP
- Root or sudo access

## Quick Start

### 1. Initialize VPS

SSH into your VPS and run:

```bash
wget https://raw.githubusercontent.com/yourusername/yourrepo/main/scripts/init-vps.sh
chmod +x init-vps.sh
sudo ./init-vps.sh
```

Or manually:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose git -y
```

### 2. Clone Repository

```bash
cd /opt
git clone https://github.com/yourusername/yourrepo.git app
cd app
```

### 3. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update these values:
- `DOMAIN=yourdomain.com`
- `EMAIL=your-email@example.com`
- `SECRET_KEY` will be auto-generated if not set

### 4. Deploy Application

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### 5. Setup SSL

```bash
./scripts/setup-ssl.sh
```

Your site is now live at `https://yourdomain.com`! 🎉

## Project Structure

```
django-template/
├── app/                    # Django application
│   ├── core/              # Project settings
│   ├── web/               # Main app
│   ├── manage.py
│   └── requirements.txt
├── nginx/                 # Nginx configuration
│   ├── nginx.conf
│   └── default.conf
├── scripts/               # Deployment scripts
│   ├── init-vps.sh       # VPS initialization
│   ├── deploy.sh         # Deploy application
│   ├── setup-ssl.sh      # SSL certificate setup
│   └── update.sh         # Update application
├── .env.example          # Environment template
├── Dockerfile            # Django container
├── docker-compose.yml    # Service orchestration
└── README.md
```

## Management Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f nginx
```

### Django Commands

```bash
# Access Django shell
docker-compose exec web python manage.py shell

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Run migrations
docker-compose exec web python manage.py migrate

# Collect static files
docker-compose exec web python manage.py collectstatic
```

### Update Application

```bash
./scripts/update.sh
```

This will:
- Pull latest code (if using git)
- Backup database
- Rebuild containers
- Run migrations
- Collect static files

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart web
docker-compose restart nginx
```

### Stop Application

```bash
docker-compose down
```

### Start Application

```bash
docker-compose up -d
```

## Security Notes

1. **Change Admin Password**: Default is `admin/admin` - change immediately at `/admin`
2. **SECRET_KEY**: Auto-generated on first deploy, stored in `.env`
3. **Firewall**: Script configures UFW to allow only SSH, HTTP, HTTPS
4. **SSL**: Automatic renewal configured, runs every 12 hours
5. **HTTPS**: All HTTP traffic redirected to HTTPS

## Database Backups

### Manual Backup

```bash
docker-compose exec web python manage.py dumpdata > backup.json
```

### Restore Backup

```bash
docker-compose exec web python manage.py loaddata backup.json
```

### Automated Backups

Add to crontab:

```bash
0 2 * * * cd /opt/app && docker-compose exec -T web python manage.py dumpdata > backups/db_$(date +\%Y\%m\%d).json
```

## Troubleshooting

### Quick Diagnostics

Run the troubleshooting script:
```bash
chmod +x scripts/troubleshoot.sh
./scripts/troubleshoot.sh
```

### HTTP redirects to HTTPS but HTTPS doesn't work

This happens when nginx is configured for HTTPS but certificates aren't set up yet.

**Solution:**

1. Stop all services:
   ```bash
   docker-compose down
   ```

2. Redeploy (will create HTTP-only config):
   ```bash
   ./scripts/deploy.sh
   ```

3. Verify HTTP works:
   ```bash
   curl http://vumgames.com
   ```

4. Then setup SSL:
   ```bash
   ./scripts/setup-ssl.sh
   ```

### SSL Certificate Issues

1. Verify DNS points to your server:
   ```bash
   nslookup yourdomain.com
   ```

2. Check ports are open:
   ```bash
   sudo ufw status
   ```

3. Test certificate request:
   ```bash
   docker-compose run --rm certbot certificates
   ```

### Application Not Starting

1. Check logs:
   ```bash
   docker-compose logs web
   ```

2. Verify environment variables:
   ```bash
   docker-compose exec web env
   ```

3. Check database:
   ```bash
   docker-compose exec web python manage.py check
   ```

### Nginx Issues

1. Test configuration:
   ```bash
   docker-compose exec nginx nginx -t
   ```

2. Reload configuration:
   ```bash
   docker-compose exec nginx nginx -s reload
   ```

## Upgrading to PostgreSQL

To use PostgreSQL instead of SQLite:

1. Uncomment PostgreSQL service in `docker-compose.yml`
2. Update `app/core/settings.py` database configuration
3. Add `psycopg2-binary` to `requirements.txt`
4. Run `./scripts/update.sh`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Django secret key | Auto-generated |
| `DEBUG` | Debug mode | False |
| `ALLOWED_HOSTS` | Allowed hostnames | domain from DOMAIN |
| `DOMAIN` | Your domain name | Required |
| `EMAIL` | Email for SSL certificates | Required |

## Performance Tuning

### Gunicorn Workers

Edit `Dockerfile` to adjust workers:
```bash
gunicorn --workers 4  # Change based on CPU cores
```

### Nginx Caching

Add to `nginx/default.conf`:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g;
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - feel free to use this template for any project!

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review Docker logs

---

**Note**: This template is designed for small to medium projects. For high-traffic applications, consider additional optimizations and monitoring solutions.