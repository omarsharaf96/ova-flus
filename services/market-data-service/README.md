# Market Data Service

Provides real-time and historical stock market data. Uses **Yahoo Finance (via yahoo-finance2)** — no API key required.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/stocks/:symbol/quote | Get real-time stock quote |
| GET | /api/v1/stocks/:symbol/history?timeframe=1M | Get historical price data |
| GET | /api/v1/stocks/search?q=query | Search stocks by name/symbol |
| GET | /api/v1/stocks/:symbol/news | Get stock-related news |

All endpoints require authentication via Bearer token.

## Timeframes

| Timeframe | Interval | Description |
|-----------|----------|-------------|
| 1D | 5m | Intraday (today) |
| 1W | 1h | Past 7 days |
| 1M | 1d | Past 30 days |
| 3M | 1d | Past 90 days |
| 1Y | 1wk | Past year |
| 5Y | 1mo | Past 5 years |
| ALL | 1mo | All available history |

## Caching Strategy

- **Redis** (hot cache): Short-lived cache for frequently accessed data
  - Quotes: 60s TTL
  - Search results: 1 hour TTL
  - News: 15 minutes TTL
- **DynamoDB** (warm cache): Persistent cache for historical data
  - Daily prices: 24 hour TTL
  - Weekly/monthly prices: 7 day TTL

## Yahoo Finance Notes

- **Free, no API key needed** — data pulled directly from Yahoo Finance
- Rate limit: be respectful, cache aggressively
- Data includes: real-time quotes, pre/post-market prices, historical OHLCV, search, news
- Covers: stocks, ETFs, mutual funds, crypto, indices

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3005 |
| JWT_SECRET | JWT signing secret | dev-secret |
| REDIS_URL | Redis connection URL | redis://localhost:6379 |
| AWS_REGION | AWS region for DynamoDB | us-east-1 |

## Running

```bash
npm install
npm run dev   # Development with hot reload
npm run build # Compile TypeScript
npm start     # Production
npm test      # Run tests
```
