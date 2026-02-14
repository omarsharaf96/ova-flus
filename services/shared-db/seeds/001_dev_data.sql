-- 001_dev_data.sql
-- Sample development data for Ova Flus Finance App

-- ============================================================================
-- Users
-- ============================================================================

INSERT INTO users (id, email, display_name, tier, email_verified, cognito_sub) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'alice@example.com', 'Alice Johnson', 'premium', true, 'cognito-sub-alice-001'),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'bob@example.com', 'Bob Smith', 'free', true, 'cognito-sub-bob-002'),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'carol@example.com', 'Carol Williams', 'family', true, 'cognito-sub-carol-003');

INSERT INTO user_settings (user_id, currency, locale, theme, biometric_enabled) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'USD', 'en-US', 'dark', true),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'EUR', 'en-GB', 'light', false),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'USD', 'en-US', 'auto', true);

-- ============================================================================
-- Budgets & Categories (Alice)
-- ============================================================================

INSERT INTO budgets (id, user_id, name, timeframe, start_date, total_limit, currency) VALUES
  ('d4e5f6a7-b8c9-0123-defa-234567890123', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Monthly Budget', 'monthly', '2026-02-01', 5000.00, 'USD'),
  ('e5f6a7b8-c9d0-1234-efab-345678901234', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Weekly Groceries', 'weekly', '2026-02-10', 200.00, 'EUR');

INSERT INTO budget_categories (id, budget_id, name, color, icon, spending_limit, sort_order) VALUES
  ('f6a7b8c9-d0e1-2345-fabc-456789012345', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Housing', '#4A90D9', 'home', 1800.00, 1),
  ('a7b8c9d0-e1f2-3456-abcd-567890123456', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Food & Dining', '#E8913A', 'restaurant', 800.00, 2),
  ('b8c9d0e1-f2a3-4567-bcde-678901234567', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Transportation', '#7BC67E', 'car', 400.00, 3),
  ('c9d0e1f2-a3b4-5678-cdef-789012345678', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Entertainment', '#D64545', 'movie', 300.00, 4);

INSERT INTO budget_alerts (budget_id, category_id, threshold_percent) VALUES
  ('d4e5f6a7-b8c9-0123-defa-234567890123', NULL, 90.00),
  ('d4e5f6a7-b8c9-0123-defa-234567890123', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 80.00);

-- ============================================================================
-- Transactions (Alice)
-- ============================================================================

INSERT INTO transactions (user_id, type, amount, currency, category_id, merchant_name, description, transaction_date, tags) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 1500.00, 'USD', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'Landlord', 'Monthly rent', '2026-02-01', ARRAY['rent', 'housing']),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 85.50, 'USD', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'Whole Foods', 'Weekly groceries', '2026-02-03', ARRAY['groceries']),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 45.00, 'USD', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'Shell Gas', 'Gas fill-up', '2026-02-05', ARRAY['gas', 'auto']),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'income', 4200.00, 'USD', NULL, 'Employer Inc', 'Bi-weekly paycheck', '2026-02-01', ARRAY['salary']),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 15.99, 'USD', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'Netflix', 'Monthly subscription', '2026-02-01', ARRAY['subscription', 'streaming']);

-- Transactions (Bob)
INSERT INTO transactions (user_id, type, amount, currency, category_id, merchant_name, description, transaction_date) VALUES
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'expense', 42.30, 'EUR', NULL, 'Lidl', 'Weekly shopping', '2026-02-10'),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'income', 3200.00, 'EUR', NULL, 'Arbeitgeber GmbH', 'Monthly salary', '2026-02-01');

-- ============================================================================
-- Recurring Transactions
-- ============================================================================

INSERT INTO recurring_transactions (user_id, type, amount, currency, description, frequency, start_date, next_date) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 1500.00, 'USD', 'Monthly rent', 'monthly', '2026-01-01', '2026-03-01'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'expense', 15.99, 'USD', 'Netflix subscription', 'monthly', '2026-01-01', '2026-03-01'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'income', 4200.00, 'USD', 'Bi-weekly paycheck', 'biweekly', '2026-01-15', '2026-02-26');

-- ============================================================================
-- Portfolios & Holdings (Alice)
-- ============================================================================

INSERT INTO portfolios (id, user_id, name, portfolio_type, currency) VALUES
  ('d0e1f2a3-b4c5-6789-defa-890123456789', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Retirement 401k', 'retirement', 'USD'),
  ('e1f2a3b4-c5d6-7890-efab-901234567890', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Personal Brokerage', 'personal', 'USD');

INSERT INTO holdings (id, portfolio_id, symbol, name, asset_type, quantity, average_cost) VALUES
  ('f2a3b4c5-d6e7-8901-fabc-012345678901', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'VTI', 'Vanguard Total Stock Market ETF', 'etf', 50.00000000, 220.5000),
  ('a3b4c5d6-e7f8-9012-abcd-123456789012', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'BND', 'Vanguard Total Bond Market ETF', 'etf', 30.00000000, 72.3000),
  ('b4c5d6e7-f8a9-0123-bcde-234567890123', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'AAPL', 'Apple Inc.', 'stock', 25.00000000, 178.5000),
  ('c5d6e7f8-a9b0-1234-cdef-345678901234', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'BTC', 'Bitcoin', 'crypto', 0.15000000, 42000.0000);

INSERT INTO tax_lots (holding_id, quantity, purchase_price, purchase_date) VALUES
  ('b4c5d6e7-f8a9-0123-bcde-234567890123', 15.00000000, 165.2500, '2025-06-15'),
  ('b4c5d6e7-f8a9-0123-bcde-234567890123', 10.00000000, 198.3800, '2025-11-20');

-- ============================================================================
-- Watchlists (Alice)
-- ============================================================================

INSERT INTO watchlists (id, user_id, name) VALUES
  ('d6e7f8a9-b0c1-2345-defa-456789012345', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Tech Stocks');

INSERT INTO watchlist_items (watchlist_id, symbol, name, asset_type, target_price, alert_enabled) VALUES
  ('d6e7f8a9-b0c1-2345-defa-456789012345', 'MSFT', 'Microsoft Corporation', 'stock', 400.00, true),
  ('d6e7f8a9-b0c1-2345-defa-456789012345', 'GOOGL', 'Alphabet Inc.', 'stock', 150.00, false),
  ('d6e7f8a9-b0c1-2345-defa-456789012345', 'NVDA', 'NVIDIA Corporation', 'stock', 800.00, true);

-- ============================================================================
-- Notifications
-- ============================================================================

INSERT INTO notifications (user_id, type, title, body, data, is_read) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'budget_alert', 'Budget Alert', 'You have spent 80% of your Food & Dining budget.', '{"budget_id": "d4e5f6a7-b8c9-0123-defa-234567890123", "category_id": "a7b8c9d0-e1f2-3456-abcd-567890123456", "percent": 80}', false),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'stock_alert', 'Price Alert: NVDA', 'NVIDIA has reached your target price of $800.00.', '{"symbol": "NVDA", "price": 800.50}', false),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'welcome', 'Welcome to Ova Flus!', 'Get started by setting up your first budget.', NULL, true);
