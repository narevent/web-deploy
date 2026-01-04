#!/bin/bash
git pull origin main
docker-compose up -d --build
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py collectstatic --noinput
echo "Deployment Updated!"