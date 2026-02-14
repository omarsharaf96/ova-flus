-- 006_plaid_rls.sql
-- Row-Level Security policies for Plaid tables

ALTER TABLE plaid_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid_transactions ENABLE ROW LEVEL SECURITY;

-- plaid_items: direct user_id check
CREATE POLICY plaid_items_user_policy ON plaid_items
    USING (user_id = current_setting('app.current_user_id')::UUID);

-- bank_accounts: join through plaid_items to check user_id
CREATE POLICY bank_accounts_user_policy ON bank_accounts
    USING (item_id IN (
        SELECT id FROM plaid_items
        WHERE user_id = current_setting('app.current_user_id')::UUID
    ));

-- plaid_transactions: join through bank_accounts -> plaid_items to check user_id
CREATE POLICY plaid_transactions_user_policy ON plaid_transactions
    USING (bank_account_id IN (
        SELECT ba.id FROM bank_accounts ba
        JOIN plaid_items pi ON ba.item_id = pi.id
        WHERE pi.user_id = current_setting('app.current_user_id')::UUID
    ));
