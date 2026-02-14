# Transaction Service

Processes and manages financial transactions. Handles transaction ingestion, categorization, and reconciliation across user accounts.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/transactions | List transactions (with pagination/filters) |
| POST | /api/v1/transactions | Create a transaction |
| GET | /api/v1/transactions/:id | Get transaction by ID |
| PUT | /api/v1/transactions/:id | Update transaction |
| DELETE | /api/v1/transactions/:id | Delete transaction |
| GET | /api/v1/transactions/recurring | List recurring transactions |
| POST | /api/v1/transactions/recurring | Create recurring transaction |
| GET | /api/v1/income | List income entries |
| POST | /api/v1/income | Create income entry |
| GET | /api/v1/transactions/summary | Spending summary by date range |
| POST | /api/v1/transactions/import | Import transactions from CSV |

All endpoints require authentication via Bearer token.

## Features

- Expense and income tracking with categories
- Recurring transaction scheduling
- CSV import with validation and error reporting
- Date-range summaries with category breakdown
- Pagination and filtering support

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3003 |
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
