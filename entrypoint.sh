#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

>&2 echo "PostgreSQL is up - executing command"

# Apply database migrations
echo "Applying migrations..."
python manage.py migrate

# Create superuser if not exists
echo "Creating superuser..."
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
"

# Start server
if [ "$1" = "web" ]; then
    echo "Starting Django server..."
    exec python manage.py runserver 0.0.0.0:8000
elif [ "$1" = "worker" ]; then
    echo "Starting Celery worker..."
    exec celery -A ad_agency worker -l info
elif [ "$1" = "beat" ]; then
    echo "Starting Celery beat..."
    exec celery -A ad_agency beat -l info
else
    exec "$@"
fi