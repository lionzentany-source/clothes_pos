-- Migration 022: Add held_sales and held_sale_items tables

CREATE TABLE IF NOT EXISTS held_sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  ts TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS held_sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  held_sale_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (held_sale_id) REFERENCES held_sales(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_held_sales_ts ON held_sales(ts);
CREATE INDEX IF NOT EXISTS idx_held_sale_items_held ON held_sale_items(held_sale_id);
