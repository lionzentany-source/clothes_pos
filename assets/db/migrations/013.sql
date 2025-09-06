-- Update existing permissions descriptions to Arabic

BEGIN TRANSACTION;

UPDATE permissions SET description = 'عرض التقارير' WHERE code = 'view_reports';
UPDATE permissions SET description = 'إنشاء/تعديل المنتجات' WHERE code = 'edit_products';
UPDATE permissions SET description = 'إجراء عمليات البيع' WHERE code = 'perform_sales';
UPDATE permissions SET description = 'إنشاء فواتير الشراء' WHERE code = 'perform_purchases';
UPDATE permissions SET description = 'تعديل مستويات المخزون' WHERE code = 'adjust_stock';
UPDATE permissions SET description = 'إدارة المستخدمين والأدوار' WHERE code = 'manage_users';
UPDATE permissions SET description = 'تسجيل مصروفات التشغيل' WHERE code = 'record_expenses';

COMMIT;
