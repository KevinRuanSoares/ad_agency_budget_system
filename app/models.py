from django.db import models
from django.utils import timezone

class Brand(models.Model):
    name = models.CharField(max_length=255)
    daily_budget = models.DecimalField(max_digits=10, decimal_places=2)
    monthly_budget = models.DecimalField(max_digits=10, decimal_places=2)
    
    def __str__(self):
        return self.name
    
    def get_daily_spend(self):
        today = timezone.now().date()
        return sum(
            record.amount
            for campaign in self.campaigns.all()
            for record in campaign.spendrecords.filter(
                timestamp__date=today
            )
        )
    
    def get_monthly_spend(self):
        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return sum(
            record.amount
            for campaign in self.campaigns.all()
            for record in campaign.spendrecords.filter(
                timestamp__gte=start_of_month
            )
        )
    
    def is_budget_exceeded(self):
        return (
            self.get_daily_spend() > self.daily_budget or 
            self.get_monthly_spend() > self.monthly_budget
        )
    
    def deactivate_campaigns(self):
        self.campaigns.update(is_active=False)
    
    def activate_eligible_campaigns(self):
        if not self.is_budget_exceeded():
            for campaign in self.campaigns.all():
                campaign.update_active_status()


class Campaign(models.Model):
    name = models.CharField(max_length=255)
    brand = models.ForeignKey(Brand, on_delete=models.CASCADE, related_name='campaigns')
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name
    
    def is_within_dayparting(self):
        now = timezone.now()
        current_day = now.weekday()  # 0-6 (Monday-Sunday)
        current_hour = now.hour
        
        return self.schedules.filter(
            day_of_week=current_day,
            start_hour__lte=current_hour,
            end_hour__gt=current_hour
        ).exists()
    
    def update_active_status(self):
        should_be_active = (
            not self.brand.is_budget_exceeded() and 
            self.is_within_dayparting()
        )
        
        if self.is_active != should_be_active:
            self.is_active = should_be_active
            self.save()
    
    def record_spend(self, amount):
        SpendRecord.objects.create(
            campaign=self,
            amount=amount,
            timestamp=timezone.now()
        )
        # Check if this spend pushed the brand over budget
        self.brand.activate_eligible_campaigns()


class Schedule(models.Model):
    DAY_CHOICES = [
        (0, 'Monday'),
        (1, 'Tuesday'),
        (2, 'Wednesday'),
        (3, 'Thursday'),
        (4, 'Friday'),
        (5, 'Saturday'),
        (6, 'Sunday'),
    ]
    
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE, related_name='schedules')
    day_of_week = models.IntegerField(choices=DAY_CHOICES)
    start_hour = models.IntegerField()  # 0-23
    end_hour = models.IntegerField()  # 0-23
    
    def __str__(self):
        return f"{self.campaign.name} - {self.get_day_of_week_display()} ({self.start_hour}:00-{self.end_hour}:00)"
    
    class Meta:
        unique_together = ('campaign', 'day_of_week', 'start_hour', 'end_hour')


class SpendRecord(models.Model):
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE, related_name='spendrecords')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    timestamp = models.DateTimeField()
    
    def __str__(self):
        return f"{self.campaign.name} - ${self.amount} at {self.timestamp}"