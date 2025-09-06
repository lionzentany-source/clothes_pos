-- Remove legacy rfid_tag column from product_variants (after migration complete)
-- Note: SQLite doesn't support DROP COLUMN; we recreate the table without the column.

PRAGMA foreign_keys=OFF;

BEGIN TRANSACTION;

-- 1) Create new table without rfid_tag
CREATE TABLE IF NOT EXISTS product_variants_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_product_id INTEGER NOT NULL,
  size TEXT,
  color TEXT,
  sku TEXT NOT NULL,
  barcode TEXT,
  cost_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0,
  reorder_point INTEGER NOT NULL DEFAULT 0,
  quantity INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (parent_product_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  UNIQUE(sku),
  UNIQUE(barcode)
);

-- 2) Copy data from old table (excluding rfid_tag)
INSERT INTO product_variants_new(
  id, parent_product_id, size, color, sku, barcode, cost_price, sale_price, reorder_point, quantity, created_at, updated_at
)
SELECT id, parent_product_id, size, color, sku, barcode, cost_price, sale_price, reorder_point, quantity, created_at, updated_at
FROM product_variants;

-- 3) Drop old table and rename new one
DROP TABLE product_variants;
ALTER TABLE product_variants_new RENAME TO product_variants;

-- 4) Recreate update trigger
CREATE TRIGGER IF NOT EXISTS trg_product_variants_updated
AFTER UPDATE ON product_variants FOR EACH ROW
BEGIN
  UPDATE product_variants SET updated_at = (strftime('%Y-%m-%dT%H:%M:%fZ','now')) WHERE id = NEW.id;
END;

COMMIT;

PRAGMA foreign_keys=ON;

