-- v015: Add branch_id columns (default 1) and composite index for parent_products(brand_id, category_id)

-- Add branch_id to sales
ALTER TABLE sales ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_sales_branch_id ON sales(branch_id);

-- Add branch_id to purchase_invoices
ALTER TABLE purchase_invoices ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_purchases_branch_id ON purchase_invoices(branch_id);

-- Add branch_id to inventory_movements
ALTER TABLE inventory_movements ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch_id ON inventory_movements(branch_id);

-- Add branch_id to cash_sessions (for multi-branch reconciliation)
ALTER TABLE cash_sessions ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_cash_sessions_branch_id ON cash_sessions(branch_id);

BEGIN TRANSACTION;

-- v015: Add branch_id columns (default 1) and composite index for parent_products(brand_id, category_id)

-- Add branch_id to sales
ALTER TABLE sales ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_sales_branch_id ON sales(branch_id);

-- Add branch_id to purchase_invoices
ALTER TABLE purchase_invoices ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_purchases_branch_id ON purchase_invoices(branch_id);

-- Add branch_id to inventory_movements
ALTER TABLE inventory_movements ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch_id ON inventory_movements(branch_id);

-- Add branch_id to cash_sessions (for multi-branch reconciliation)
ALTER TABLE cash_sessions ADD COLUMN branch_id INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_cash_sessions_branch_id ON cash_sessions(branch_id);

-- Composite index for brand/category driven inventory filtering (if columns exist)
CREATE INDEX IF NOT EXISTS idx_parent_products_brand_category ON parent_products(brand_id, category_id);

COMMIT;
