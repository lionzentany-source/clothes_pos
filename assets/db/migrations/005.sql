-- Migration 005: add brands table and brand_id to parent_products
BEGIN TRANSACTION;

-- 1) Create brands table
CREATE TABLE IF NOT EXISTS brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

-- 2) Rebuild parent_products to add brand_id column with FK
CREATE TABLE IF NOT EXISTS parent_products_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  category_id INTEGER NOT NULL,
  supplier_id INTEGER,
  brand_id INTEGER,
  image_path TEXT,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
  FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL
);

-- 3) Copy data from old table (brand_id will be NULL)
INSERT INTO parent_products_new (id, name, description, category_id, supplier_id, image_path)
SELECT id, name, description, category_id, supplier_id, image_path FROM parent_products;

-- 4) Drop old table and rename new
DROP TABLE parent_products;
ALTER TABLE parent_products_new RENAME TO parent_products;

-- 5) Indices as needed
CREATE INDEX IF NOT EXISTS idx_parent_products_brand_id ON parent_products(brand_id);

COMMIT;

