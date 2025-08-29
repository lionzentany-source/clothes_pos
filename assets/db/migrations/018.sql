-- Migration 018: Add manage_customers permission
-- Date: 2025-01-22
-- Description: Add new permission for customer management

-- Add the new permission
INSERT OR IGNORE INTO permissions(code, description) VALUES 
('manage_customers', 'إدارة العملاء');

-- Grant the permission to Admin role by default
INSERT OR IGNORE INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'Admin' AND p.code = 'manage_customers';
