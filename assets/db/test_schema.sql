-- GENERATED FINAL SCHEMA FOR TESTS --

-- Core Tables --

CREATE TABLE IF NOT EXISTS categories (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS suppliers (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	contact_info TEXT,
	UNIQUE(name)
);

CREATE TABLE IF NOT EXISTS brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS parent_products (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	description TEXT,
	category_id INTEGER NOT NULL,
	supplier_id INTEGER,
    brand_id INTEGER,
	image_path TEXT,
	FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
	FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS product_variants (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	parent_product_id INTEGER NOT NULL,
	size TEXT,
	color TEXT,
	sku TEXT,
	barcode TEXT,
	rfid_tag TEXT,
	cost_price REAL NOT NULL DEFAULT 0,
	sale_price REAL NOT NULL DEFAULT 0,
	reorder_point INTEGER NOT NULL DEFAULT 0,
	quantity INTEGER NOT NULL DEFAULT 0,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	FOREIGN KEY (parent_product_id) REFERENCES parent_products(id) ON DELETE CASCADE,
	UNIQUE(barcode)
);

CREATE TABLE IF NOT EXISTS product_variant_rfids (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variant_id INTEGER NOT NULL,
  epc TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customers (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	phone_number TEXT,
	UNIQUE(phone_number)
);

CREATE TABLE IF NOT EXISTS users (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	username TEXT NOT NULL UNIQUE,
	full_name TEXT,
	password_hash TEXT NOT NULL,
	is_active INTEGER NOT NULL DEFAULT 1,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS roles (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS permissions (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	code TEXT NOT NULL UNIQUE,
	description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
	role_id INTEGER NOT NULL,
	permission_id INTEGER NOT NULL,
	PRIMARY KEY (role_id, permission_id),
	FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
	FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_roles (
	user_id INTEGER NOT NULL,
	role_id INTEGER NOT NULL,
	PRIMARY KEY (user_id, role_id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
	FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sales (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	user_id INTEGER NOT NULL,
	customer_id INTEGER,
	total_amount REAL NOT NULL,
	sale_date TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	reference TEXT,
    branch_id INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
	FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sale_items (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sale_id INTEGER NOT NULL,
	variant_id INTEGER NOT NULL,
	quantity INTEGER NOT NULL,
	price_per_unit REAL NOT NULL,
	cost_at_sale REAL NOT NULL DEFAULT 0,
    discount_amount REAL NOT NULL DEFAULT 0,
    tax_amount REAL NOT NULL DEFAULT 0,
    note TEXT,
	FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
	FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS payments (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sale_id INTEGER,
	amount REAL NOT NULL,
	method TEXT NOT NULL,
	cash_session_id INTEGER,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_invoices (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	supplier_id INTEGER NOT NULL,
	reference TEXT,
	received_date TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	total_cost REAL NOT NULL DEFAULT 0,
	created_by INTEGER,
    branch_id INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
	FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS purchase_invoice_items (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	purchase_invoice_id INTEGER NOT NULL,
	variant_id INTEGER NOT NULL,
	quantity INTEGER NOT NULL,
	cost_price REAL NOT NULL,
	FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id) ON DELETE CASCADE,
	FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS inventory_movements (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	variant_id INTEGER NOT NULL,
	qty_change INTEGER NOT NULL,
	movement_type TEXT NOT NULL,
	reference_type TEXT,
	reference_id INTEGER,
	reason TEXT,
	user_id INTEGER,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    branch_id INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_returns (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sale_id INTEGER NOT NULL,
	user_id INTEGER,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	reason TEXT,
	FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE RESTRICT,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_return_items (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sales_return_id INTEGER NOT NULL,
	sale_item_id INTEGER,
	variant_id INTEGER NOT NULL,
	quantity INTEGER NOT NULL,
	refund_amount REAL NOT NULL DEFAULT 0,
	FOREIGN KEY (sales_return_id) REFERENCES sales_returns(id) ON DELETE CASCADE,
	FOREIGN KEY (sale_item_id) REFERENCES sale_items(id) ON DELETE SET NULL,
	FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS cash_sessions (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	opened_by INTEGER NOT NULL,
	opened_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	opening_float REAL NOT NULL DEFAULT 0,
	closed_by INTEGER,
	closed_at TEXT,
	closing_amount REAL,
	variance REAL,
    branch_id INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY (opened_by) REFERENCES users(id) ON DELETE RESTRICT,
	FOREIGN KEY (closed_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cash_movements (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	cash_session_id INTEGER NOT NULL,
	amount REAL NOT NULL,
	movement_type TEXT NOT NULL,
	reason TEXT,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	FOREIGN KEY (cash_session_id) REFERENCES cash_sessions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS settings (
	key TEXT PRIMARY KEY,
	value TEXT,
	updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS audit_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	user_id INTEGER,
	action TEXT NOT NULL,
	entity TEXT,
	entity_id INTEGER,
	reason TEXT,
	created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS expense_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  paid_via TEXT NOT NULL,
  cash_session_id INTEGER,
  date TEXT NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY(category_id) REFERENCES expense_categories(id),
  FOREIGN KEY(cash_session_id) REFERENCES cash_sessions(id)
);

CREATE TABLE IF NOT EXISTS audit_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  entity TEXT NOT NULL,
  field TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Triggers --

CREATE TRIGGER IF NOT EXISTS trg_product_variants_updated
AFTER UPDATE ON product_variants FOR EACH ROW
BEGIN
	UPDATE product_variants SET updated_at = (strftime('%Y-%m-%dT%H:%M:%fZ','now')) WHERE id = NEW.id;
END;

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

-- Indexes --

CREATE INDEX IF NOT EXISTS idx_variants_parent ON product_variants(parent_product_id);
CREATE INDEX IF NOT EXISTS idx_variants_sku ON product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_variants_barcode ON product_variants(barcode);
CREATE INDEX IF NOT EXISTS idx_variants_rfid ON product_variants(rfid_tag);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_user ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_variant ON sale_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_movements_variant ON inventory_movements(variant_id);
CREATE INDEX IF NOT EXISTS idx_movements_created ON inventory_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchase_invoices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchases_received ON purchase_invoices(received_date);
CREATE INDEX IF NOT EXISTS idx_purchase_items_invoice ON purchase_invoice_items(purchase_invoice_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_variant ON purchase_invoice_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_payments_sale ON payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_payments_session ON payments(cash_session_id);
CREATE INDEX IF NOT EXISTS idx_cash_session_opened ON cash_sessions(opened_at);
CREATE INDEX IF NOT EXISTS idx_sales_user_date ON sales(user_id, sale_date);
CREATE INDEX IF NOT EXISTS idx_parent_products_cat_supplier ON parent_products(category_id, supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_date ON purchase_invoices(supplier_id, received_date);
CREATE INDEX IF NOT EXISTS idx_pvr_variant ON product_variant_rfids(variant_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_cash_session ON expenses(cash_session_id);
CREATE INDEX IF NOT EXISTS idx_parent_brand ON parent_products(brand_id);
CREATE INDEX IF NOT EXISTS idx_parent_category ON parent_products(category_id);
CREATE INDEX IF NOT EXISTS idx_variants_reorder_qty ON product_variants(reorder_point, quantity);
CREATE INDEX IF NOT EXISTS idx_sales_returns_sale ON sales_returns(sale_id);
CREATE INDEX IF NOT EXISTS idx_sales_return_items_return ON sales_return_items(sales_return_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_created ON audit_events(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_events_entity ON audit_events(entity);
CREATE INDEX IF NOT EXISTS idx_sales_branch_id ON sales(branch_id);
CREATE INDEX IF NOT EXISTS idx_purchases_branch_id ON purchase_invoices(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch_id ON inventory_movements(branch_id);
CREATE INDEX IF NOT EXISTS idx_cash_sessions_branch_id ON cash_sessions(branch_id);
CREATE INDEX IF NOT EXISTS idx_parent_products_brand_category ON parent_products(brand_id, category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date_id_desc ON expenses(date DESC, id DESC);

-- Data Seeding --

INSERT OR IGNORE INTO permissions(code, description) VALUES
 ('view_reports','عرض التقارير'),
 ('edit_products','إنشاء/تعديل المنتجات'),
 ('perform_sales','إجراء عمليات البيع'),
 ('perform_purchases','إنشاء فواتير الشراء'),
 ('adjust_stock','تعديل مستويات المخزون'),
 ('manage_users','إدارة المستخدمين والأدوار'),
 ('record_expenses','تسجيل مصروفات التشغيل');

UPDATE permissions SET description = 'عرض التقارير' WHERE code = 'view_reports';
UPDATE permissions SET description = 'إنشاء/تعديل المنتجات' WHERE code = 'edit_products';
UPDATE permissions SET description = 'إجراء عمليات البيع' WHERE code = 'perform_sales';
UPDATE permissions SET description = 'إنشاء فواتير الشراء' WHERE code = 'perform_purchases';
UPDATE permissions SET description = 'تعديل مستويات المخزون' WHERE code = 'adjust_stock';
UPDATE permissions SET description = 'إدارة المستخدمين والأدوار' WHERE code = 'manage_users';
UPDATE permissions SET description = 'تسجيل مصروفات التشغيل' WHERE code = 'record_expenses';

INSERT OR IGNORE INTO roles(name) VALUES ('Admin');
INSERT OR IGNORE INTO roles(name) VALUES ('Cashier');
INSERT OR IGNORE INTO users(username, full_name, password_hash, is_active) VALUES ('admin','Administrator','SET_ME',1);
INSERT OR IGNORE INTO user_roles(user_id, role_id)
SELECT u.id, r.id FROM users u, roles r WHERE u.username='admin' AND r.name='Admin';
INSERT OR IGNORE INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.name='Admin';

INSERT OR IGNORE INTO categories(name) VALUES ('قمصان');
INSERT OR IGNORE INTO categories(name) VALUES ('سراويل');
INSERT OR IGNORE INTO categories(name) VALUES ('أحذية');
INSERT OR IGNORE INTO categories(name) VALUES ('معاطف');
INSERT OR IGNORE INTO categories(name) VALUES ('إكسسوارات');