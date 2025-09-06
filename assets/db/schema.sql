-- SQLite POS schema v1 — Clothes POS
-- Use with WAL mode for performance: PRAGMA journal_mode=WAL;
-- Ensure foreign keys: PRAGMA foreign_keys=ON;

-- Core dictionaries
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

-- Brands
CREATE TABLE IF NOT EXISTS brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

-- Products
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
  image_path TEXT,
  FOREIGN KEY (parent_product_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  -- UNIQUE(sku) -- removed to allow nullable/duplicate SKUs
  UNIQUE(barcode)
);

-- Mapping table to attach attributes to parent (product) records
CREATE TABLE IF NOT EXISTS parent_attributes (
  parent_id INTEGER NOT NULL,
  attribute_id INTEGER NOT NULL,
  PRIMARY KEY (parent_id, attribute_id),
  FOREIGN KEY (parent_id) REFERENCES parent_products(id) ON DELETE CASCADE,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS trg_product_variants_updated
AFTER UPDATE ON product_variants FOR EACH ROW
BEGIN
  UPDATE product_variants SET updated_at = (strftime('%Y-%m-%dT%H:%M:%fZ','now')) WHERE id = NEW.id;
END;

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone_number TEXT,
  UNIQUE(phone_number)
);

-- Users & Roles
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

-- Sales & Payments
CREATE TABLE IF NOT EXISTS sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  customer_id INTEGER,
  total_amount REAL NOT NULL,
  sale_date TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  reference TEXT,
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
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER,
  amount REAL NOT NULL,
  method TEXT NOT NULL, -- CASH, CARD, MOBILE, REFUND
  cash_session_id INTEGER,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
);

-- Purchases
CREATE TABLE IF NOT EXISTS purchase_invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier_id INTEGER NOT NULL,
  reference TEXT,
  received_date TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  total_cost REAL NOT NULL DEFAULT 0,
  created_by INTEGER,
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

-- Inventory movements
CREATE TABLE IF NOT EXISTS inventory_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variant_id INTEGER NOT NULL,
  qty_change INTEGER NOT NULL, -- +IN / -OUT
  movement_type TEXT NOT NULL, -- IN, OUT, ADJUST, RETURN
  reference_type TEXT, -- SALE, PURCHASE, RETURN, ADJUSTMENT
  reference_id INTEGER,
  reason TEXT,
  user_id INTEGER,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Returns
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

-- Cash sessions
CREATE TABLE IF NOT EXISTS cash_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  opened_by INTEGER NOT NULL,
  opened_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  opening_float REAL NOT NULL DEFAULT 0,
  closed_by INTEGER,
  closed_at TEXT,
  closing_amount REAL,
  variance REAL,
  FOREIGN KEY (opened_by) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (closed_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cash_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cash_session_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  movement_type TEXT NOT NULL, -- IN, OUT
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (cash_session_id) REFERENCES cash_sessions(id) ON DELETE CASCADE
);

-- Settings & audit
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

-- Indices
CREATE INDEX IF NOT EXISTS idx_variants_parent ON product_variants(parent_product_id);
CREATE INDEX IF NOT EXISTS idx_variants_sku ON product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_variants_barcode ON product_variants(barcode);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_user ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_movements_variant ON inventory_movements(variant_id);
CREATE INDEX IF NOT EXISTS idx_movements_created ON inventory_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchase_invoices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_invoice ON purchase_invoice_items(purchase_invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_sale ON payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_cash_session_opened ON cash_sessions(opened_at);

-- Held sales (persisted multi-slot held/parked carts)
CREATE TABLE IF NOT EXISTS held_sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  ts TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS held_sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  held_sale_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (held_sale_id) REFERENCES held_sales(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_held_sales_ts ON held_sales(ts);
CREATE INDEX IF NOT EXISTS idx_held_sale_items_held ON held_sale_items(held_sale_id);
-- Additional tables and indexes from migrations
CREATE TABLE IF NOT EXISTS product_variant_rfids (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variant_id INTEGER NOT NULL,
  epc TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

-- Expenses module tables
CREATE TABLE IF NOT EXISTS expense_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  paid_via TEXT NOT NULL, -- 'cash' | 'bank' | 'other'
  cash_session_id INTEGER, -- nullable linkage to cash sessions
  date TEXT NOT NULL, -- ISO8601 date
  description TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY(category_id) REFERENCES expense_categories(id),
  FOREIGN KEY(cash_session_id) REFERENCES cash_sessions(id)
);

CREATE INDEX IF NOT EXISTS idx_pvr_variant ON product_variant_rfids(variant_id);
CREATE INDEX IF NOT EXISTS idx_parent_brand ON parent_products(brand_id);
CREATE INDEX IF NOT EXISTS idx_parent_category ON parent_products(category_id);
CREATE INDEX IF NOT EXISTS idx_variants_reorder_qty ON product_variants(reorder_point, quantity);
CREATE INDEX IF NOT EXISTS idx_parent_products_brand_category ON parent_products(brand_id, category_id);


-- Audit log table
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

-- Usage Logs table
CREATE TABLE IF NOT EXISTS usage_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  event_type TEXT NOT NULL,
  event_details TEXT, -- JSON string
  user_id INTEGER,
  session_id TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_usage_logs_timestamp ON usage_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_usage_logs_event_type ON usage_logs(event_type);

-- Pending invoices queue for offline sync
CREATE TABLE IF NOT EXISTS pending_invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  attempts INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending'
);
CREATE INDEX IF NOT EXISTS idx_pending_invoices_status ON pending_invoices(status);

