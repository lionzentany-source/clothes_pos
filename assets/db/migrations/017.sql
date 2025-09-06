-- Migration 017: composite ordering index for expenses + legacy user management backfill
CREATE INDEX IF NOT EXISTS idx_expenses_date_id_desc ON expenses(date DESC, id DESC);

-- Legacy safety: ensure user/role/permission tables exist (older installs may have missed schema or earlier migrations)
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

-- Idempotent seeds
INSERT OR IGNORE INTO permissions(code, description) VALUES
 ('view_reports','عرض التقارير'),
 ('edit_products','إنشاء/تعديل المنتجات'),
 ('perform_sales','إجراء عمليات البيع'),
 ('perform_purchases','إنشاء فواتير الشراء'),
 ('adjust_stock','تعديل مستويات المخزون'),
 ('manage_users','إدارة المستخدمين والأدوار'),
 ('record_expenses','تسجيل مصروفات التشغيل');
INSERT OR IGNORE INTO roles(name) VALUES ('Admin');
INSERT OR IGNORE INTO roles(name) VALUES ('Cashier');
INSERT OR IGNORE INTO users(username, full_name, password_hash, is_active) VALUES ('admin','Administrator','SET_ME',1);
INSERT OR IGNORE INTO user_roles(user_id, role_id)
SELECT u.id, r.id FROM users u, roles r WHERE u.username='admin' AND r.name='Admin';
INSERT OR IGNORE INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.name='Admin';
