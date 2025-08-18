-- Migration 010: ensure brands table exists for legacy databases
BEGIN TRANSACTION;

-- Create brands table if missing
CREATE TABLE IF NOT EXISTS brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

COMMIT;

