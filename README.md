# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create a superuser for the admin interface
python manage.py createsuperuser

# Start Django development server
python manage.py runserver

# In a new terminal, start Celery worker
celery -A ad_agency worker -l info

# In a third terminal, start Celery beat scheduler
celery -A ad_agency beat -l info


python manage.py record_spend --min 10 --max 50
