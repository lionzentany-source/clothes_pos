-- Migration 025: add attributes JSON column to sale_items so queued invoices can preserve attribute selections

ALTER TABLE sale_items RENAME TO sale_items_old;

CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price_per_unit REAL NOT NULL,
  cost_at_sale REAL NOT NULL DEFAULT 0,
  discount_amount REAL NOT NULL DEFAULT 0,
  tax_amount REAL NOT NULL DEFAULT 0,
  note TEXT,
  attributes TEXT,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

INSERT INTO sale_items (id, sale_id, variant_id, quantity, price_per_unit, cost_at_sale, discount_amount, tax_amount, note)
SELECT id, sale_id, variant_id, quantity, price_per_unit, cost_at_sale, discount_amount, tax_amount, note FROM sale_items_old;

DROP TABLE sale_items_old;

-- Recreate indices
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_variant ON sale_items(variant_id);
