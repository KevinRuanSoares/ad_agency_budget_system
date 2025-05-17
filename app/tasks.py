from celery import shared_task
from django.utils import timezone

from .models import Brand, Campaign

@shared_task
def check_all_budgets():
    """Check all brands' budgets and update campaign statuses accordingly."""
    for brand in Brand.objects.all():
        if brand.is_budget_exceeded():
            brand.deactivate_campaigns()
        else:
            for campaign in brand.campaigns.all():
                campaign.update_active_status()

@shared_task
def check_dayparting():
    """Check if campaigns should be active based on dayparting schedules."""
    for campaign in Campaign.objects.all():
        campaign.update_active_status()

@shared_task
def reset_daily_spend():
    """Reset daily spend tracking and reactivate eligible campaigns."""
    for brand in Brand.objects.all():
        brand.activate_eligible_campaigns()

@shared_task
def reset_monthly_spend():
    """Reset monthly spend tracking and reactivate eligible campaigns."""
    for brand in Brand.objects.all():
        brand.activate_eligible_campaigns()