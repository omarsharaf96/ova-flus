# Budget Service

Manages user budgets, spending categories, and budget tracking. Provides CRUD operations for budgets and calculates spending against budget limits.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/budgets | List all budgets for user |
| POST | /api/v1/budgets | Create a new budget |
| GET | /api/v1/budgets/:id | Get budget by ID |
| PUT | /api/v1/budgets/:id | Update budget |
| DELETE | /api/v1/budgets/:id | Delete budget |
| GET | /api/v1/budgets/:id/categories | List budget categories |
| POST | /api/v1/budgets/:id/categories | Add category to budget |
| PUT | /api/v1/budgets/:id/categories/:catId | Update category |
| DELETE | /api/v1/budgets/:id/categories/:catId | Remove category |
| GET | /api/v1/budgets/templates | List budget templates |
| POST | /api/v1/budgets/templates | Create budget from template |

All endpoints require authentication via Bearer token.

## Features

- Budget CRUD with period support (weekly, monthly, yearly)
- Category management with allocated/spent tracking
- Pre-built budget templates (e.g., "50/30/20 Rule", "Zero-based")
- Budget vs. actual spending calculations

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3002 |
| JWT_SECRET | JWT signing secret | dev-secret |
| DB_HOST | PostgreSQL host | localhost |
| DB_NAME | Database name | ova_flus |

## Running

```bash
npm run dev   # Development with hot reload
npm run build # Compile TypeScript
npm start     # Production
npm test      # Run tests
```
