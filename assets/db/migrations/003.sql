-- RFID multi-tag support
-- New table to store multiple RFID EPCs per product variant

CREATE TABLE IF NOT EXISTS product_variant_rfids (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variant_id INTEGER NOT NULL,
  epc TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pvr_variant ON product_variant_rfids(variant_id);

-- Backfill existing single-tag data from product_variants.rfid_tag
INSERT OR IGNORE INTO product_variant_rfids(variant_id, epc)
SELECT id AS variant_id, rfid_tag AS epc
FROM product_variants
WHERE rfid_tag IS NOT NULL AND rfid_tag <> '';

