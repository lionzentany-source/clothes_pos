PRAGMA foreign_keys=OFF;

-- Make SKU optional (nullable) and drop UNIQUE(sku) constraint
-- This migration recreates product_variants with sku nullable and no unique constraint
-- and copies data.

BEGIN TRANSACTION;

-- Create new table with sku nullable and without UNIQUE(sku)
CREATE TABLE product_variants_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_product_id INTEGER NOT NULL,
  size TEXT,
  color TEXT,
  sku TEXT,
  barcode TEXT,
  rfid_tag TEXT,
  cost_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0,
  reorder_point INTEGER NOT NULL DEFAULT 0,
  quantity INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (parent_product_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  UNIQUE(barcode)
);

-- Copy data from old table
INSERT INTO product_variants_new (
  id, parent_product_id, size, color, sku, barcode, rfid_tag, cost_price, sale_price, reorder_point, quantity, created_at, updated_at
)
SELECT 
  id, parent_product_id, size, color, sku, barcode, rfid_tag, cost_price, sale_price, reorder_point, quantity, created_at, updated_at
FROM product_variants;

-- Drop old table and rename new one
DROP TABLE product_variants;
ALTER TABLE product_variants_new RENAME TO product_variants;

COMMIT;

PRAGMA foreign_keys=ON;
