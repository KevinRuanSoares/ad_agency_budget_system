from __future__ import absolute_import, unicode_literals
import os
from celery import Celery
from celery.schedules import crontab

# Set the default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ad_agency.settings')

app = Celery('ad_agency')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()

# Schedule periodic tasks
app.conf.beat_schedule = {
    'check-budgets-every-5-minutes': {
        'task': 'app.tasks.check_all_budgets',
        'schedule': 5 * 60,  # Every 5 minutes
    },
    'check-dayparting-every-hour': {
        'task': 'app.tasks.check_dayparting',
        'schedule': crontab(minute=0),  # Every hour at minute 0
    },
    'reset-daily-spend-at-midnight': {
        'task': 'app.tasks.reset_daily_spend',
        'schedule': crontab(hour=0, minute=0),  # Every day at midnight
    },
    'reset-monthly-spend-at-month-start': {
        'task': 'app.tasks.reset_monthly_spend',
        'schedule': crontab(day_of_month=1, hour=0, minute=0),  # First day of month
    },
}