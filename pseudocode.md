# Ad Agency Budget Management System - Pseudo-code

## Data Models

```
Model Brand:
    Fields:
        - id: Primary Key
        - name: String (unique)
        - daily_budget: Decimal (positive)
        - monthly_budget: Decimal (positive)
        - created_at: DateTime
        - updated_at: DateTime
    
    Methods:
        - get_daily_spend() -> Decimal
        - get_monthly_spend() -> Decimal
        - is_budget_exceeded() -> Boolean
        - deactivate_campaigns() -> Void
        - activate_eligible_campaigns() -> Void
    
    Relationships:
        - One-to-many with Campaign

Model Campaign:
    Fields:
        - id: Primary Key
        - name: String
        - brand_id: Foreign Key to Brand
        - is_active: Boolean (default: True)
        - created_at: DateTime
        - updated_at: DateTime
    
    Methods:
        - is_within_dayparting() -> Boolean
        - update_active_status() -> Void
        - record_spend(amount: Decimal) -> Void
    
    Relationships:
        - Many-to-one with Brand
        - One-to-many with Schedule
        - One-to-many with SpendRecord

Model Schedule:
    Fields:
        - id: Primary Key
        - campaign_id: Foreign Key to Campaign
        - day_of_week: Integer (0-6, Monday=0)
        - start_hour: Integer (0-23)
        - end_hour: Integer (0-23)
        - created_at: DateTime
    
    Constraints:
        - Unique together: (campaign_id, day_of_week, start_hour, end_hour)
        - start_hour < end_hour
        - day_of_week in range 0-6
        - start_hour, end_hour in range 0-23
    
    Relationships:
        - Many-to-one with Campaign

Model SpendRecord:
    Fields:
        - id: Primary Key
        - campaign_id: Foreign Key to Campaign
        - amount: Decimal (positive)
        - timestamp: DateTime
        - created_at: DateTime
    
    Relationships:
        - Many-to-one with Campaign
```

## Core Logic Algorithms

### 1. Spend Tracking Algorithm

```
Function record_spend(campaign_id: Integer, amount: Decimal):
    Input: campaign_id, spend amount
    Output: Updated spend record, possibly deactivated campaigns
    
    BEGIN
        // Validate inputs
        IF amount <= 0 THEN
            RAISE ValidationError("Amount must be positive")
        END IF
        
        campaign = GET Campaign WHERE id = campaign_id
        IF campaign IS NULL THEN
            RAISE NotFoundError("Campaign not found")
        END IF
        
        // Record the spend
        spend_record = CREATE SpendRecord{
            campaign_id: campaign_id,
            amount: amount,
            timestamp: current_timestamp()
        }
        
        // Check if this spend pushed brand over budget
        brand = campaign.brand
        daily_spend = brand.get_daily_spend()
        monthly_spend = brand.get_monthly_spend()
        
        // Deactivate campaigns if budget exceeded
        IF daily_spend > brand.daily_budget OR monthly_spend > brand.monthly_budget THEN
            brand.deactivate_campaigns()
            LOG("Brand {} exceeded budget - campaigns deactivated", brand.name)
        END IF
        
        RETURN spend_record
    END
```

### 2. Budget Enforcement Algorithm

```
Function check_all_brand_budgets():
    Input: None
    Output: Updated campaign statuses
    
    BEGIN
        brands = GET ALL Brand
        
        FOR EACH brand IN brands DO
            daily_spend = brand.get_daily_spend()
            monthly_spend = brand.get_monthly_spend()
            
            // Check if budget is exceeded
            IF daily_spend > brand.daily_budget OR monthly_spend > brand.monthly_budget THEN
                // Deactivate all campaigns for this brand
                campaigns = GET Campaign WHERE brand_id = brand.id
                FOR EACH campaign IN campaigns DO
                    campaign.is_active = FALSE
                    SAVE campaign
                END FOR
                LOG("Budget exceeded for brand: {}", brand.name)
            ELSE
                // Budget is OK, check each campaign individually
                campaigns = GET Campaign WHERE brand_id = brand.id
                FOR EACH campaign IN campaigns DO
                    campaign.update_active_status()
                END FOR
            END IF
        END FOR
    END
```

### 3. Dayparting Check Algorithm

```
Function is_within_dayparting(campaign_id: Integer) -> Boolean:
    Input: campaign_id
    Output: Boolean indicating if campaign should be active
    
    BEGIN
        current_time = GET current_datetime()
        current_day = current_time.weekday()  // 0-6
        current_hour = current_time.hour      // 0-23
        
        schedules = GET Schedule WHERE campaign_id = campaign_id
        
        FOR EACH schedule IN schedules DO
            IF schedule.day_of_week = current_day AND
               schedule.start_hour <= current_hour AND
               schedule.end_hour > current_hour THEN
                RETURN TRUE
            END IF
        END FOR
        
        RETURN FALSE
    END

Function check_all_campaign_dayparting():
    Input: None
    Output: Updated campaign statuses
    
    BEGIN
        campaigns = GET ALL Campaign
        
        FOR EACH campaign IN campaigns DO
            should_be_active = is_within_dayparting(campaign.id)
            budget_ok = NOT campaign.brand.is_budget_exceeded()
            
            new_status = should_be_active AND budget_ok
            
            IF campaign.is_active != new_status THEN
                campaign.is_active = new_status
                SAVE campaign
                LOG("Campaign {} status changed to {}", campaign.name, new_status)
            END IF
        END FOR
    END
```

### 4. Daily Reset Algorithm

```
Function reset_daily_spend():
    Input: None
    Output: Reactivated eligible campaigns
    
    BEGIN
        LOG("Starting daily reset process")
        
        brands = GET ALL Brand
        
        FOR EACH brand IN brands DO
            // No need to delete spend records - we filter by date
            // Just recheck all campaigns for this brand
            campaigns = GET Campaign WHERE brand_id = brand.id
            
            FOR EACH campaign IN campaigns DO
                // Check if campaign should be active based on:
                // 1. Monthly budget (daily budget resets automatically)
                // 2. Current dayparting schedule
                monthly_spend = brand.get_monthly_spend()
                within_schedule = is_within_dayparting(campaign.id)
                
                should_be_active = (monthly_spend <= brand.monthly_budget) AND within_schedule
                
                IF campaign.is_active != should_be_active THEN
                    campaign.is_active = should_be_active
                    SAVE campaign
                    LOG("Daily reset - Campaign {} set to {}", campaign.name, should_be_active)
                END IF
            END FOR
        END FOR
        
        LOG("Daily reset process completed")
    END
```

### 5. Monthly Reset Algorithm

```
Function reset_monthly_spend():
    Input: None
    Output: Reactivated eligible campaigns
    
    BEGIN
        LOG("Starting monthly reset process")
        
        brands = GET ALL Brand
        
        FOR EACH brand IN brands DO
            // No need to delete spend records - we filter by date
            // Just recheck all campaigns for this brand
            campaigns = GET Campaign WHERE brand_id = brand.id
            
            FOR EACH campaign IN campaigns DO
                // Check if campaign should be active based on:
                // 1. Fresh daily budget (monthly budget resets automatically)
                // 2. Current dayparting schedule
                within_schedule = is_within_dayparting(campaign.id)
                
                // Both budgets reset, so only check dayparting
                should_be_active = within_schedule
                
                IF campaign.is_active != should_be_active THEN
                    campaign.is_active = should_be_active
                    SAVE campaign
                    LOG("Monthly reset - Campaign {} set to {}", campaign.name, should_be_active)
                END IF
            END FOR
        END FOR
        
        LOG("Monthly reset process completed")
    END
```

## Celery Task Scheduling

```
// Periodic task definitions
SCHEDULED_TASKS = {
    "check_budgets": {
        task: "check_all_brand_budgets",
        schedule: every 5 minutes
    },
    "check_dayparting": {
        task: "check_all_campaign_dayparting", 
        schedule: every 1 hour at minute 0
    },
    "daily_reset": {
        task: "reset_daily_spend",
        schedule: every day at 00:00
    },
    "monthly_reset": {
        task: "reset_monthly_spend",
        schedule: every month at 00:00 on day 1
    }
}
```

## System Workflow

```
Daily System Workflow:

1. CONTINUOUS (Every 5 minutes):
   - Execute check_all_brand_budgets()
   - Deactivate campaigns if budgets exceeded
   
2. HOURLY (Every hour at :00):
   - Execute check_all_campaign_dayparting()
   - Activate/deactivate campaigns based on schedules
   
3. DAILY (Every day at midnight):
   - Execute reset_daily_spend()
   - Reactivate eligible campaigns for new day
   
4. MONTHLY (First day of month at midnight):
   - Execute reset_monthly_spend()  
   - Reactivate eligible campaigns for new month

5. ON-DEMAND (When spend is recorded):
   - Execute record_spend()
   - Immediately check if budget exceeded
   - Deactivate campaigns if necessary
```

## Data Flow

```
Spend Recording Flow:
User/System -> record_spend() -> Create SpendRecord -> Check Budget -> 
Possibly Deactivate Campaigns -> Log Activity

Budget Enforcement Flow:
Celery Scheduler -> check_all_brand_budgets() -> Calculate Spends -> 
Compare with Budgets -> Update Campaign Status -> Log Changes

Dayparting Flow:
Celery Scheduler -> check_all_campaign_dayparting() -> Get Current Time -> 
Check Schedule Matches -> Update Campaign Status -> Log Changes

Reset Flow:
Celery Scheduler -> reset_daily/monthly_spend() -> Recheck All Campaigns ->
Update Campaign Status -> Log Reactivations
```

## Error Handling

```
Error Handling Strategy:

1. Database Errors:
   - Retry failed operations up to 3 times
   - Log errors with full context
   - Send alerts for critical failures

2. Validation Errors:
   - Validate all inputs before processing
   - Return clear error messages
   - Log validation failures

3. Celery Task Failures:
   - Configure automatic retries
   - Implement dead letter queue
   - Monitor task failure rates

4. Performance Issues:
   - Use database indexes on frequently queried fields
   - Implement query optimization
   - Add monitoring for slow queries
```
