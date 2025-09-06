-- Performance indexes for reports filters
-- Create composite indexes to support WHERE clauses used by reports

-- Sales by user/date
CREATE INDEX IF NOT EXISTS idx_sales_user_date ON sales(user_id, sale_date);

-- Parent products by category/supplier (used via JOIN from variants)
CREATE INDEX IF NOT EXISTS idx_parent_products_cat_supplier ON parent_products(category_id, supplier_id);

-- Purchases by supplier/date
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_date ON purchase_invoices(supplier_id, received_date);

