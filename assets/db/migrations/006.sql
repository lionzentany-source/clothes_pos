-- Migration 006: add discount/tax/note columns to sale_items
BEGIN TRANSACTION;
ALTER TABLE sale_items ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0;
ALTER TABLE sale_items ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0;
ALTER TABLE sale_items ADD COLUMN note TEXT;
COMMIT;

