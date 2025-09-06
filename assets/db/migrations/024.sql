-- Migration 024: Add attributes and price_override to held_sale_items
-- This migration preserves existing data by recreating the table with the
-- new columns and copying existing rows across.

PRAGMA foreign_keys=off;
BEGIN TRANSACTION;

-- Rename existing table
ALTER TABLE held_sale_items RENAME TO held_sale_items_old;

-- Create new table with attributes (TEXT) and price_override (REAL NULLABLE)
CREATE TABLE held_sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  held_sale_id INTEGER NOT NULL,
  variant_id INTEGER,
  quantity INTEGER NOT NULL DEFAULT 1,
  price REAL NOT NULL DEFAULT 0.0,
  attributes TEXT,
  price_override REAL,
  FOREIGN KEY (held_sale_id) REFERENCES held_sales(id) ON DELETE CASCADE
);

-- Copy old data into new table (attributes and price_override will be NULL)
INSERT INTO held_sale_items (id, held_sale_id, variant_id, quantity, price)
SELECT id, held_sale_id, variant_id, quantity, price FROM held_sale_items_old;

-- Drop old table
DROP TABLE held_sale_items_old;

COMMIT;
PRAGMA foreign_keys=on;
