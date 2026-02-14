# Ova Flus Database Schema

## Overview

The Ova Flus finance app uses a hybrid database approach:
- **PostgreSQL (RDS)** for relational data: users, budgets, transactions, portfolios
- **DynamoDB** for high-throughput, low-latency data: sessions, market cache, real-time alerts

## Entity-Relationship Diagram

```
users
  |-- 1:1 -- user_settings
  |-- 1:N -- budgets
  |             |-- 1:N -- budget_categories (self-referencing via parent_id)
  |             |-- 1:N -- budget_alerts
  |-- 1:N -- transactions
  |             |-- 1:N -- split_transactions
  |-- 1:N -- recurring_transactions
  |-- 1:N -- portfolios
  |             |-- 1:N -- holdings
  |                         |-- 1:N -- tax_lots
  |-- 1:N -- watchlists
  |             |-- 1:N -- watchlist_items
  |-- 1:N -- plaid_items
  |             |-- 1:N -- bank_accounts
  |-- 1:N -- notifications
  |-- 1:N -- audit_logs
```

## Tables

### Users & Auth

| Table | Purpose |
|-------|---------|
| `users` | Core user identity. Links to Cognito via `cognito_sub`. Supports free/premium/family tiers and family grouping via `family_id`. |
| `user_settings` | Per-user preferences: currency, locale, theme, notification toggles, biometric auth. One-to-one with users. |

### Budgets

| Table | Purpose |
|-------|---------|
| `budgets` | User-defined budgets with weekly/monthly/custom timeframes and spending limits. Can be templates. |
| `budget_categories` | Hierarchical categories within a budget. Self-referencing `parent_id` for subcategories. Includes color/icon for UI. |
| `budget_alerts` | Threshold-based alerts per budget or category (e.g., notify at 80% spent). |

### Transactions

| Table | Purpose |
|-------|---------|
| `transactions` | All financial transactions (expense/income/transfer). Supports multi-currency with exchange rates, receipt uploads (S3), tags, and JSONB metadata. |
| `split_transactions` | Splitting a single transaction across multiple categories. |
| `recurring_transactions` | Templates for auto-generated transactions (daily/weekly/biweekly/monthly/yearly). |

### Portfolios

| Table | Purpose |
|-------|---------|
| `portfolios` | Investment portfolios grouped by type (retirement, personal, taxable). |
| `holdings` | Individual securities within a portfolio. Unique per (portfolio, symbol). Supports stocks, ETFs, mutual funds, bonds, crypto. |
| `tax_lots` | Per-lot cost basis tracking for tax reporting (FIFO/specific lot). |
| `watchlists` | Named lists for tracking securities of interest. |
| `watchlist_items` | Individual symbols on a watchlist with optional price alerts. |

### Plaid (Bank Linking)

| Table | Purpose |
|-------|---------|
| `plaid_items` | Plaid Item records linking a user to a financial institution via Plaid. Stores encrypted access tokens, institution info, consent expiration, and sync cursors. |
| `bank_accounts` | Individual bank accounts retrieved from Plaid. Linked to a `plaid_item`. Stores account type, balances, mask, and official name. |

### System

| Table | Purpose |
|-------|---------|
| `notifications` | In-app notifications with type, title, body, optional JSONB data, and read status. |
| `audit_logs` | Immutable audit trail tracking user actions, resource changes, IP, and user agent. |

## Design Decisions

### UUIDs as Primary Keys
All tables use `UUID` primary keys generated via `uuid_generate_v4()`. This provides:
- Safe distributed ID generation without coordination
- No sequential ID enumeration attacks
- Consistent ID format across PostgreSQL and DynamoDB

### Row-Level Security (RLS)
User-scoped tables enforce RLS via PostgreSQL policies. The application sets `app.current_user_id` per transaction using `SET LOCAL`, ensuring users can only access their own data regardless of query construction. Enabled on: budgets, budget_categories, transactions, portfolios, holdings, notifications.

### JSONB for Flexible Metadata
`transactions.metadata` and `notifications.data` use JSONB for schema-flexible data that varies by type (e.g., import source info, notification payloads). This avoids over-normalization for rarely queried attributes.

### Indexing Strategy
- **Composite indexes** on frequently filtered combinations: `(user_id, transaction_date DESC)` for transaction listing
- **Partial indexes** for common filters: `notifications(user_id) WHERE is_read = false` for unread count
- **Foreign key indexes** on all FK columns for join performance
- **Descending indexes** on date columns for reverse-chronological queries

### Auto-Updated Timestamps
A shared `update_updated_at_column()` trigger function automatically sets `updated_at = NOW()` on every UPDATE for all tables with that column.

### Multi-Currency Support
Transactions store both converted (`amount`/`currency`) and original values (`original_amount`/`original_currency`/`exchange_rate`) for accurate multi-currency accounting.

## DynamoDB Tables

| Table | Partition Key | Sort Key | Purpose |
|-------|--------------|----------|---------|
| `ova-flus-sessions` | `userId` | `sessionId` | Auth sessions with TTL-based expiry |
| `ova-flus-market-cache` | `symbol` | `timestamp` | Cached market data with TTL |
| `ova-flus-alerts` | `userId` | `alertId` | Real-time price/budget alerts with PITR |

All DynamoDB tables use PAY_PER_REQUEST billing for automatic scaling.

## Migration Order

1. `001_initial_schema.sql` - Extensions, tables, triggers
2. `002_indexes.sql` - Performance indexes
3. `003_rls_policies.sql` - Row-Level Security policies
4. `004_plaid_tables.sql` - Plaid items and bank accounts tables, indexes, and RLS policies
