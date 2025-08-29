-- Migration: Add parent_attributes linking table
CREATE TABLE IF NOT EXISTS parent_attributes (
  parent_id INTEGER NOT NULL,
  attribute_id INTEGER NOT NULL,
  PRIMARY KEY (parent_id, attribute_id),
  FOREIGN KEY (parent_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
);
