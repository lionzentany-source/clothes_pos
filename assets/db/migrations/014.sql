-- Add indexes for common queries and enforce unique non-null SKU
BEGIN TRANSACTION;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_variants_rfid ON product_variants(rfid_tag);
CREATE INDEX IF NOT EXISTS idx_sale_items_variant ON sale_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_payments_session ON payments(cash_session_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_variant ON purchase_invoice_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_purchases_received ON purchase_invoices(received_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id);

-- Trigger to prevent duplicate non-null SKU
DROP TRIGGER IF EXISTS trg_variants_sku_unique_insert;
DROP TRIGGER IF EXISTS trg_variants_sku_unique_update;

CREATE TRIGGER trg_variants_sku_unique_insert
BEFORE INSERT ON product_variants
FOR EACH ROW
WHEN NEW.sku IS NOT NULL AND EXISTS (
  SELECT 1 FROM product_variants pv WHERE pv.sku = NEW.sku LIMIT 1
)
BEGIN
  SELECT RAISE(ABORT, 'Duplicate SKU not allowed when provided');
END;

CREATE TRIGGER trg_variants_sku_unique_update
BEFORE UPDATE OF sku ON product_variants
FOR EACH ROW
WHEN NEW.sku IS NOT NULL AND EXISTS (
  SELECT 1 FROM product_variants pv WHERE pv.sku = NEW.sku AND pv.id != OLD.id LIMIT 1
)
BEGIN
  SELECT RAISE(ABORT, 'Duplicate SKU not allowed when provided');
END;

COMMIT;
