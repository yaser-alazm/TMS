# 🌱 Database Seeding Guide

## Overview
Database seeding automatically populates your databases with initial data for development and testing.

## What Gets Seeded

### User Service (`apps/user-service/prisma/seed.ts`)
- **Roles**: admin, moderator, user
- **Users**:
  - `admin` / `admin@tms.dev` (admin role)
  - `testuser` / `test@tms.dev` (user role)  
  - `yaser-az` / `yaser@tms.dev` (admin role)
  - `yaser-hotmail` / `yaser-hotmail@tms.dev` (admin role)
- **Password**: `Password123!` (for all users)

### Vehicle Service (`apps/vehicle-service/prisma/seed.ts`)
- **Demo Vehicles**: Various vehicle types with realistic data
- **Maintenance Records**: Sample maintenance history
- **Shadow Users**: Users matching the User Service IDs

## How Seeding Works

### Automatic Seeding
Seeding runs automatically when you start the microservices development environment:

```bash
npm run dev:microservices
```

This will:
1. Start infrastructure (PostgreSQL, Redis, Kafka)
2. Run database migrations
3. **Run database seeding** ← This is new!
4. Start all microservices

### Manual Seeding
You can also seed databases manually:

```bash
# Seed all databases
npm run dev:seed

# Or seed individual services
cd apps/user-service && npm run db:seed
cd apps/vehicle-service && npm run db:seed
```

### Reset and Reseed
To completely reset and reseed a database:

```bash
# User Service
cd apps/user-service && npm run db:reset

# Vehicle Service  
cd apps/vehicle-service && npm run db:reset
```

## Verification

### Check Seeded Data
1. **Via Adminer**: http://localhost:8080
   - Login with: `postgres` / `password`
   - Check `tms_user` database for users and roles
   - Check `tms_vehicle` database for vehicles

2. **Via API**:
   ```bash
   # Test user login
   curl -X POST http://localhost:4001/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@tms.dev","password":"Password123!"}'
   
   # Get vehicles
   curl http://localhost:4002/vehicles
   ```

### Expected Results
- **4 users** in User Service database
- **3 roles** in User Service database  
- **Multiple vehicles** in Vehicle Service database
- **Maintenance records** for vehicles

## Troubleshooting

### Seeding Fails
If seeding fails, check:
1. **Database connectivity**: `npm run dev:test-db`
2. **Migrations completed**: Check migration status
3. **Environment variables**: Ensure `.env` files are correct

### Duplicate Data
Seeding scripts are **idempotent** - they won't create duplicates:
- User Service: Checks if users exist before creating
- Vehicle Service: Uses `skipDuplicates: true`

### Reset Everything
To start fresh:
```bash
npm run dev:reset  # Stops and removes all Docker containers/volumes
npm run dev:microservices  # Starts fresh with seeding
```

## Development Workflow

1. **First Time Setup**:
   ```bash
   npm run dev:microservices  # Includes seeding
   ```

2. **Daily Development**:
   ```bash
   npm run dev  # Quick start (no seeding)
   ```

3. **Need Fresh Data**:
   ```bash
   npm run dev:seed  # Reseed existing databases
   ```

4. **Complete Reset**:
   ```bash
   npm run dev:reset && npm run dev:microservices
   ```

## Production Notes

- **Never run seeding in production**
- Seeding scripts are development-only
- Production databases should be populated via proper data migration scripts

