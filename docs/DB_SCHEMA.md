# Database Schema (SQLite) — Clothes POS

This document provides an ERD overview and the initial DDL (in docs/db/schema.sql). It follows best practices for POS: variants, movements, purchases, sales, payments, users/roles, cash sessions, settings, and auditing.

## ERD Overview (Mermaid)
```mermaid
erDiagram
  CATEGORIES ||--o{ PARENT_PRODUCTS : has
  SUPPLIERS ||--o{ PARENT_PRODUCTS : supplies
  PARENT_PRODUCTS ||--o{ PRODUCT_VARIANTS : has
  PRODUCT_VARIANTS ||--o{ INVENTORY_MOVEMENTS : affects
  CUSTOMERS ||--o{ SALES : buys
  USERS ||--o{ SALES : created_by
  SALES ||--o{ SALE_ITEMS : contains
  SALES ||--o{ PAYMENTS : paid_by
  PURCHASE_INVOICES ||--o{ PURCHASE_INVOICE_ITEMS : contains
  SUPPLIERS ||--o{ PURCHASE_INVOICES : issues
  USERS ||--o{ CASH_SESSIONS : opens
  CASH_SESSIONS ||--o{ PAYMENTS : records
  USERS ||--o{ INVENTORY_MOVEMENTS : records
  ROLES ||--o{ USER_ROLES : includes
  PERMISSIONS ||--o{ ROLE_PERMISSIONS : grants
```

Key rules:
- All stock changes are captured in INVENTORY_MOVEMENTS, never direct edits without a reason.
- Negative stock is disallowed at the service layer.
- SKUs and barcodes are unique per variant.
- Returns are modeled as movements and linked records, never in-place edits of completed sales.

## DDL
See docs/db/schema.sql for full SQL with indices and constraints.

