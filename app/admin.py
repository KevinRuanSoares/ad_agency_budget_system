from django.contrib import admin
from .models import Brand, Campaign, Schedule, SpendRecord

class CampaignInline(admin.TabularInline):
    model = Campaign
    extra = 1

class ScheduleInline(admin.TabularInline):
    model = Schedule
    extra = 1

class SpendRecordInline(admin.TabularInline):
    model = SpendRecord
    extra = 0
    readonly_fields = ('timestamp',)
    can_delete = False

@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ('name', 'daily_budget', 'monthly_budget', 'get_daily_spend', 'get_monthly_spend', 'is_budget_exceeded')
    inlines = [CampaignInline]

@admin.register(Campaign)
class CampaignAdmin(admin.ModelAdmin):
    list_display = ('name', 'brand', 'is_active', 'is_within_dayparting')
    list_filter = ('is_active', 'brand')
    inlines = [ScheduleInline, SpendRecordInline]
    actions = ['activate_campaigns', 'deactivate_campaigns']
    
    def activate_campaigns(self, request, queryset):
        queryset.update(is_active=True)
    activate_campaigns.short_description = "Activate selected campaigns"
    
    def deactivate_campaigns(self, request, queryset):
        queryset.update(is_active=False)
    deactivate_campaigns.short_description = "Deactivate selected campaigns"

@admin.register(Schedule)
class ScheduleAdmin(admin.ModelAdmin):
    list_display = ('campaign', 'day_of_week', 'start_hour', 'end_hour')
    list_filter = ('day_of_week', 'campaign__brand')

@admin.register(SpendRecord)
class SpendRecordAdmin(admin.ModelAdmin):
    list_display = ('campaign', 'amount', 'timestamp')
    list_filter = ('campaign__brand', 'timestamp')
    date_hierarchy = 'timestamp'