# Ad Agency Budget Management System

A Django and Celery-based system for managing advertising budgets and campaign scheduling for an ad agency. This system tracks daily and monthly ad spend, automatically activates/deactivates campaigns based on budget limits, and enforces dayparting schedules.

## Features

- Tracks daily and monthly ad spend per brand
- Automatically turns campaigns on/off based on budget constraints
- Enforces dayparting schedules (campaigns only run during allowed hours)
- Resets budget tracking at the start of each day/month
- Django admin interface for easy management
- Docker containerization with Makefile for easy commands

## Data Models

### Brand
- Represents an advertiser with daily and monthly budgets
- Has multiple campaigns

### Campaign
- Represents an advertising campaign belonging to a brand
- Can be active or inactive
- Has dayparting schedules and spend records

### Schedule
- Defines when a campaign should be active (day of week, start hour, end hour)
- A campaign can have multiple schedules for different days/times

### SpendRecord
- Records ad spend for a campaign with amount and timestamp

## System Workflow

1. **Budget Tracking**: Spend is recorded for active campaigns with timestamps
2. **Budget Enforcement**: Every 5 minutes, campaigns are deactivated if budgets are exceeded
3. **Dayparting**: Every hour, campaigns are activated/deactivated based on schedules
4. **Daily Reset**: At midnight, daily budget tracking resets and eligible campaigns reactivate
5. **Monthly Reset**: At month start, monthly budget tracking resets and eligible campaigns reactivate

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Make (usually pre-installed on macOS/Linux)
- Git

### Installation and Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ad-agency-budget-system.git
   cd ad-agency-budget-system
   ```

2. **Complete setup in one command:**
   ```bash
   make setup
   ```
   This will build the containers, start services, run migrations, and setup test data.

3. **Access the application:**
   - Django admin: http://localhost:8000/admin/
   - Default credentials: admin/admin

## Makefile Commands

Run `make help` to see all available commands:

### Basic Operations

```bash
make setup          # Complete initial setup
make up             # Start all services
make down           # Stop all services
make restart        # Restart all services
make destroy        # Stop and remove all data
make status         # Show service status
make health         # Check health of all services
```

### Development

```bash
make migrate        # Run Django migrations
make makemigrations # Create new migrations
make superuser      # Create Django superuser
make shell          # Access Django shell
make bash           # Access bash in web container
make restart-web    # Restart only web service
make restart-celery # Restart only Celery services
```

### Database

```bash
make db-shell       # Access PostgreSQL shell
make db-reset       # Reset database completely
make wait-for-db    # Wait for database to be ready
```

### Testing

```bash
make setup-test-data # Create test brands and campaigns
make test-full       # Run comprehensive test suite
make test-dayparting # Test dayparting functionality
make simulate-spend  # Simulate ad spend
make quick-test      # Quick test flow
make demo           # Run demonstration
```

### Advanced Testing

```bash
# Test specific brand spending
make test-spend BRAND="Test Brand A" AMOUNT=150

# Simulate different times for dayparting
make simulate-time HOUR=9    # Test at 9 AM
make simulate-time DAY=5     # Test on Saturday

# Custom spend simulation
make simulate-spend MIN=20 MAX=100

# Load testing
make load-test
```

### Monitoring

```bash
make monitor        # Real-time system monitoring
make logs           # View all logs
make logs-web       # View web service logs
make logs-worker    # View Celery worker logs
make logs-beat      # View Celery beat logs
make top            # Show running processes
```

### Celery Management

```bash
make celery-inspect     # Inspect Celery workers
make celery-scheduled   # View scheduled tasks
make celery-events      # Monitor Celery events

# Manual task execution
make task-budget-check  # Run budget check
make task-dayparting    # Run dayparting check
make task-daily-reset   # Run daily reset
make task-monthly-reset # Run monthly reset
```

### Cleanup

```bash
make clean          # Remove unused Docker resources
make clean-all      # Remove all Docker resources
make dev-reset      # Complete development reset
```

## Testing the System

### Quick Demo

Run the complete demonstration:

```bash
make demo
```

This will:
1. Setup test data
2. Simulate normal spending
3. Test budget enforcement
4. Test dayparting functionality
5. Show results in admin interface

### Step-by-Step Testing

1. **Initial Setup:**
   ```bash
   make setup-test-data
   ```

2. **Test Normal Operations:**
   ```bash
   make simulate-spend MIN=20 MAX=40
   ```

3. **Test Budget Enforcement:**
   ```bash
   make test-spend BRAND="Test Brand A" AMOUNT=150
   ```

4. **Monitor Results:**
   ```bash
   make monitor
   ```

5. **Check Admin Interface:**
   Visit http://localhost:8000/admin/ to see campaigns automatically deactivated

### Advanced Testing Scenarios

```bash
# Test at different times of day
make simulate-time HOUR=9   # Business hours
make simulate-time HOUR=23  # Late night

# Test different days
make simulate-time DAY=0    # Monday
make simulate-time DAY=6    # Sunday

# Load testing
make load-test

# Test resets
make task-daily-reset
make task-monthly-reset
```

## Development Workflow

### Making Changes

1. **Code Changes:**
   ```bash
   # After modifying Django code
   make restart-web
   
   # After modifying Celery tasks
   make restart-celery
   ```

2. **Model Changes:**
   ```bash
   make makemigrations
   make migrate
   make restart-web
   ```

3. **Database Schema Changes:**
   ```bash
   make db-reset  # Reset database completely
   make setup-test-data  # Recreate test data
   ```

### Debugging

```bash
# View specific service logs
make logs-web
make logs-worker

# Access containers for debugging
make bash        # Web container
make db-shell    # Database
make shell       # Django shell

# Check service health
make health
make status
```

## Production Deployment

For production deployment:

1. **Environment Configuration:**
   - Create `.env` file with production settings
   - Set secure database passwords
   - Configure Redis settings
   - Set `DEBUG=False`

2. **Docker Compose Override:**
   ```bash
   # Create docker-compose.prod.yml
   # Run with: docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
   ```

3. **Security:**
   - Configure SSL/HTTPS
   - Set up proper firewall rules
   - Use secrets management

## Troubleshooting

### Common Issues

1. **Services won't start:**
   ```bash
   make health     # Check service health
   make logs       # Check error logs
   make destroy    # Nuclear option: reset everything
   make setup
   ```

2. **Database issues:**
   ```bash
   make db-reset   # Reset database
   ```

3. **Port conflicts:**
   ```bash
   make down       # Stop services
   # Edit docker-compose.yml to change ports
   make up
   ```

4. **Celery not working:**
   ```bash
   make logs-worker      # Check worker logs
   make logs-beat        # Check scheduler logs
   make restart-celery   # Restart Celery services
   ```

5. **Permission errors:**
   ```bash
   chmod +x entrypoint.sh
   make rebuild
   ```

### Debug Commands

```bash
# Full system status
make status
make health
make top

# Detailed logs
make logs-web
make logs-worker
make logs-beat
make logs-db

# System cleanup
make clean
make clean-all
```

## Project Structure

```
ad_agency_budget_system/
├── Makefile                   # Command shortcuts
├── docker-compose.yml         # Service definitions
├── Dockerfile                 # Web service container
├── entrypoint.sh             # Container startup script
├── requirements.txt          # Python dependencies
├── ad_agency/                # Django project
│   ├── settings.py
│   ├── celery.py
│   └── ...
├── app/                      # Main application
│   ├── models.py
│   ├── admin.py
│   ├── tasks.py
│   └── management/commands/
│       ├── record_spend.py
│       ├── test_budget_system.py
│       ├── simulate_time.py
│       └── monitor_system.py
└── README.md                 # This file
```

## Docker Services

- **db**: PostgreSQL database
- **redis**: Redis message broker
- **web**: Django application
- **celery_worker**: Background task processor
- **celery_beat**: Task scheduler

## Features in Detail

### Budget Management
- Real-time spend tracking
- Automatic campaign deactivation when budgets exceeded
- Daily and monthly budget limits
- Spend aggregation and reporting

### Dayparting
- Flexible schedule definition (day/hour granularity)
- Multiple schedules per campaign
- Automatic activation/deactivation
- Time-based campaign control

### Admin Interface
- User-friendly campaign management
- Real-time budget and spend visibility
- Bulk campaign operations
- Comprehensive reporting

## API Reference

While this system doesn't currently expose REST APIs, the core functionality is available through:

1. **Django Admin Interface** - Full CRUD operations
2. **Management Commands** - CLI automation
3. **Celery Tasks** - Background processing
4. **Django Shell** - Programmatic access

## Future Enhancements

- REST API development
- Real-time WebSocket notifications
- Advanced reporting and analytics
- Multi-timezone support
- Role-based access control
- API integration with ad platforms
- Advanced budget forecasting

---

This system provides enterprise-grade budget management with automatic campaign control, making it ideal for ad agencies managing multiple brands and campaigns with complex scheduling and budget requirements.