-- 005_plaid_indexes.sql
-- Indexes for Plaid tables

CREATE INDEX idx_plaid_items_user_id ON plaid_items(user_id);
CREATE INDEX idx_bank_accounts_item_id ON bank_accounts(item_id);
CREATE INDEX idx_plaid_transactions_bank_account_id ON plaid_transactions(bank_account_id);
CREATE INDEX idx_plaid_transactions_date ON plaid_transactions(date);
