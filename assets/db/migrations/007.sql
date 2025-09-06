-- Migration 007: Expenses module
CREATE TABLE IF NOT EXISTS expense_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  paid_via TEXT NOT NULL, -- 'cash' | 'bank' | 'other'
  cash_session_id INTEGER, -- nullable linkage to cash sessions
  date TEXT NOT NULL, -- ISO8601 date
  description TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY(category_id) REFERENCES expense_categories(id),
  FOREIGN KEY(cash_session_id) REFERENCES cash_sessions(id)
);

-- Indices to speed lookups
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_cash_session ON expenses(cash_session_id);
