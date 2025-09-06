-- Migration 019: Add image_path column to product_variants table
-- Date: 2025-08-23
-- Description: Add image_path column to support variant-level images in POS

BEGIN TRANSACTION;

-- Add image_path column to product_variants table
ALTER TABLE product_variants ADD COLUMN image_path TEXT;

COMMIT;