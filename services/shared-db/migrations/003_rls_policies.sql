-- 003_rls_policies.sql
-- Row-Level Security policies for Ova Flus Finance App

-- Enable RLS on all user-scoped tables
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies (assumes app sets app.current_user_id via SET LOCAL)
CREATE POLICY budgets_user_policy ON budgets USING (user_id = current_setting('app.current_user_id')::UUID);
CREATE POLICY transactions_user_policy ON transactions USING (user_id = current_setting('app.current_user_id')::UUID);
CREATE POLICY portfolios_user_policy ON portfolios USING (user_id = current_setting('app.current_user_id')::UUID);
CREATE POLICY notifications_user_policy ON notifications USING (user_id = current_setting('app.current_user_id')::UUID);
