# Analytics Service

Generates financial insights, spending analytics, and portfolio performance reports. Provides data aggregation and trend analysis.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/analytics/spending-summary | Spending breakdown by category |
| GET | /api/v1/analytics/budget-vs-actual | Budget adherence comparison |
| GET | /api/v1/analytics/trends | Spending/income trends over time |
| GET | /api/v1/analytics/portfolio-performance | Portfolio return metrics |
| POST | /api/v1/reports/generate | Generate PDF or CSV report |

All endpoints require authentication via Bearer token.

## Features

- Spending summary with category breakdown and top merchants
- Budget vs actual comparison with overspend detection
- Multi-month trend analysis with moving averages
- Portfolio performance metrics with benchmark comparison
- Report generation in PDF and CSV formats

## Query Parameters

- `period`: Predefined period (e.g., "this-month", "last-quarter", "ytd")
- `startDate` / `endDate`: Custom date range (ISO 8601)
- `budgetId`: Specific budget for comparison
- `portfolioId`: Specific portfolio for performance
- `timeframe`: Performance timeframe (1M, 3M, 6M, 1Y, YTD)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3006 |
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
