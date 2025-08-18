-- Migration 008: Performance indexes for inventory queries
-- Adds indexes to speed up brand/category filtering and low-stock checks

CREATE INDEX IF NOT EXISTS idx_parent_brand ON parent_products(brand_id);
CREATE INDEX IF NOT EXISTS idx_parent_category ON parent_products(category_id);
-- Composite index to help low-stock ordering (reorder_point - quantity)
CREATE INDEX IF NOT EXISTS idx_variants_reorder_qty ON product_variants(reorder_point, quantity);
