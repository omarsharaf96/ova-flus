# Portfolio Service

Manages stock portfolio holdings, tracks performance, and calculates portfolio metrics including gains/losses, allocation, and diversification.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/portfolios | List user portfolios |
| POST | /api/v1/portfolios | Create portfolio |
| GET | /api/v1/portfolios/:id | Get portfolio details |
| PUT | /api/v1/portfolios/:id | Update portfolio |
| DELETE | /api/v1/portfolios/:id | Delete portfolio |
| GET | /api/v1/portfolios/:id/holdings | List holdings |
| POST | /api/v1/portfolios/:id/holdings | Add holding |
| PUT | /api/v1/portfolios/:id/holdings/:holdingId | Update holding |
| DELETE | /api/v1/portfolios/:id/holdings/:holdingId | Remove holding |
| GET | /api/v1/portfolios/:id/performance | Portfolio performance metrics |
| GET | /api/v1/portfolios/:id/allocation | Asset allocation breakdown |
| GET | /api/v1/watchlists | List watchlists |
| POST | /api/v1/watchlists | Create watchlist |
| GET | /api/v1/watchlists/:id | Get watchlist |
| DELETE | /api/v1/watchlists/:id | Delete watchlist |
| POST | /api/v1/watchlists/:id/items | Add item to watchlist |
| DELETE | /api/v1/watchlists/:id/items/:symbol | Remove item from watchlist |

All endpoints require authentication via Bearer token.

## Features

- Portfolio CRUD with holdings management
- P&L calculations using current market prices
- Performance tracking over configurable timeframes
- Asset allocation analysis by sector
- Watchlist management for tracking stocks of interest

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3004 |
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
