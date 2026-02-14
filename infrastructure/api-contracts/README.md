# OvaFlus API Contracts

This directory contains the API contract definitions for the OvaFlus personal finance platform. It serves as the single source of truth for API design and enables code generation for client SDKs.

## Files

| File | Description |
|------|-------------|
| `openapi.yaml` | OpenAPI 3.0 specification for the REST API |
| `schema.graphql` | GraphQL schema for AWS AppSync |

## API Strategy: REST + GraphQL

OvaFlus uses a dual API strategy to get the best of both worlds:

### REST API (OpenAPI)

Used for standard CRUD operations and server-to-server communication:

- **Auth** -- Registration, login, token refresh, MFA
- **Budgets** -- Create, read, update, delete budgets and categories
- **Transactions** -- Full transaction lifecycle, import/export, recurring
- **Portfolios** -- Investment portfolio and holdings management
- **Market Data** -- Stock quotes, history, search, news
- **Analytics** -- Spending summaries, trends, report generation
- **Notifications** -- Notification management and preferences

### GraphQL API (AppSync)

Used for flexible client queries and real-time features:

- **Flexible queries** -- Clients fetch exactly the data they need, reducing over-fetching on mobile
- **Nested resolution** -- e.g., fetch a portfolio with its holdings and performance in a single request
- **Real-time subscriptions** via AppSync WebSockets:
  - Live stock price updates
  - Budget threshold alerts
  - Push notifications

## Authentication

All authenticated endpoints require a JWT Bearer token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Token Flow

1. **Register** or **Login** to receive an `accessToken` and `refreshToken`
2. Use the `accessToken` for API requests (expires in 15 minutes)
3. Use `POST /auth/refresh` with the `refreshToken` to obtain a new access token
4. Optional: Enable MFA via `POST /auth/mfa/setup` and verify with `POST /auth/mfa/verify`

For the GraphQL API, pass the token as a connection parameter when establishing the AppSync WebSocket.

## Rate Limiting

| Tier | Limit | Window |
|------|-------|--------|
| Anonymous (login/register) | 10 requests | per minute |
| Authenticated | 100 requests | per minute |
| Market Data | 30 requests | per minute |
| Report Generation | 5 requests | per hour |

Rate limit headers are included in every response:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1700000000
```

Exceeding the limit returns `429 Too Many Requests`.

## Versioning

- The REST API is versioned via the URL path: `/api/v1/...`
- Breaking changes will increment the version (v2, v3, etc.)
- Non-breaking additions (new fields, new endpoints) are added to the current version
- Deprecated endpoints will include a `Sunset` header with the removal date
- The GraphQL schema evolves additively -- fields are deprecated with `@deprecated` before removal

## Error Responses

All errors follow a consistent format:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Human-readable description",
  "errors": [
    {
      "field": "email",
      "message": "Must be a valid email address",
      "code": "INVALID_FORMAT"
    }
  ]
}
```

Standard HTTP status codes:

| Code | Meaning |
|------|---------|
| 400 | Bad request (malformed input) |
| 401 | Authentication required or token expired |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 422 | Validation error (well-formed but invalid data) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

## Running a Mock Server

Use [Prism](https://github.com/stoplightio/prism) to run a local mock server from the OpenAPI spec:

```bash
# Install Prism
npm install -g @stoplight/prism-cli

# Start mock server on port 4010
prism mock openapi.yaml --port 4010

# Test it
curl http://localhost:4010/api/v1/auth/me \
  -H "Authorization: Bearer test-token"
```

Prism generates realistic responses based on the schema definitions, making it useful for frontend development before the backend is ready.
