-- Migration 016: ensure expense indices exist (defensive) and future tuning
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_cash_session ON expenses(cash_session_id);
