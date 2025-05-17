#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

>&2 echo "PostgreSQL is up - executing command"

# Check if migrations are needed
if [ "$1" = "web" ]; then
    # Check if the django_migrations table exists
    TABLE_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='django_migrations';")
    
    if [ "$TABLE_EXISTS" = "1" ]; then
        echo "Migrations table exists, checking for unapplied migrations..."
        python manage.py migrate --check || {
            echo "Applying new migrations..."
            python manage.py migrate
        }
    else
        echo "No migrations table found, applying initial migrations..."
        python manage.py migrate
    fi

    # Create superuser if not exists
    echo "Creating superuser if not exists..."
    python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser created successfully')
else:
    print('Superuser already exists')
"
fi

# Start the appropriate service
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