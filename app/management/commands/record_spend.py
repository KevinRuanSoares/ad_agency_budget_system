from django.core.management.base import BaseCommand
from django.utils import timezone
import random
from app.models import Campaign

class Command(BaseCommand):
    help = 'Simulates ad spend for all active campaigns'

    def add_arguments(self, parser):
        parser.add_argument('--min', type=float, default=1.0, help='Minimum spend amount')
        parser.add_argument('--max', type=float, default=100.0, help='Maximum spend amount')

    def handle(self, *args, **options):
        min_amount = options['min']
        max_amount = options['max']
        
        active_campaigns = Campaign.objects.filter(is_active=True)
        
        for campaign in active_campaigns:
            # Only record spend if campaign is within dayparting schedule
            if campaign.is_within_dayparting():
                amount = round(random.uniform(min_amount, max_amount), 2)
                campaign.record_spend(amount)
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Recorded ${amount} spend for campaign "{campaign.name}"'
                    )
                )
            else:
                self.stdout.write(
                    self.style.WARNING(
                        f'Campaign "{campaign.name}" is outside dayparting schedule, no spend recorded'
                    )
                )
        
        self.stdout.write(self.style.SUCCESS('Finished recording spend'))