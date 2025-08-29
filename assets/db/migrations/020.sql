-- Migration: Add dynamic attributes tables
CREATE TABLE IF NOT EXISTS attributes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS attribute_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  attribute_id INTEGER NOT NULL,
  value TEXT NOT NULL,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE,
  UNIQUE(attribute_id, value)
);

CREATE TABLE IF NOT EXISTS variant_attributes (
  variant_id INTEGER NOT NULL,
  attribute_value_id INTEGER NOT NULL,
  PRIMARY KEY (variant_id, attribute_value_id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
  FOREIGN KEY (attribute_value_id) REFERENCES attribute_values(id) ON DELETE CASCADE
);

-- Mapping table to attach attributes to parent (product) records
CREATE TABLE IF NOT EXISTS parent_attributes (
  parent_id INTEGER NOT NULL,
  attribute_id INTEGER NOT NULL,
  PRIMARY KEY (parent_id, attribute_id),
  FOREIGN KEY (parent_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
);
