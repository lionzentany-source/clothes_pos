# Repository Adapters Report — clothes_pos

Generated: 2025-08-31

Purpose: quick scan of existing `lib/data/repositories` to identify interface differences and recommend adapter targets for unifying `Invoice/Item/Customer` repository contracts used by the SyncService and offline queue.

---

## Key findings (summary)

- Repositories use idiomatic, repository-specific APIs (e.g. `SalesRepository.createSale`, `PurchaseRepository.createInvoice`, `ProductRepository.createParent`), not a single shared `InvoiceRepository` interface.
- Many repositories expose both domain-model based APIs (accepting `Sale`, `SaleItem`, `PurchaseInvoice`, etc.) and Result-wrapped helper variants (e.g. `createSaleResult`) for safer error handling.
- To integrate a SyncService cleanly, we should define a small `InvoiceRepository` interface (create/list/get) and adapt `SalesRepository`/`PurchaseRepository` to that interface using thin adapters.

---

## Scanned repositories (selected)

### SalesRepository (`lib/data/repositories/sales_repository.dart`)

- Primary methods:
  - `Future<int> createSale({required Sale sale, required List<SaleItem> items, required List<Payment> payments})`
  - `Future<Result<int>> createSaleResult({...})`
  - `Future<List<SaleItem>> itemsForSale(int saleId)`
  - `Future<Sale> getSale(int saleId)`
  - `Future<List<Map<String, Object?>>> listSales({int limit = 20, int offset = 0, String? searchQuery})`
- Notes: domain-model first; suitable as backend for invoice sync. Adapter should map generic payload -> `Sale`/`SaleItem`.

### PurchaseRepository (`lib/data/repositories/purchase_repository.dart`)

- Primary methods:
  - `Future<int> createInvoice(PurchaseInvoice invoice, List<PurchaseInvoiceItem> items)`
  - `Future<int> createInvoiceWithRfids(...)`
  - `Future<List<PurchaseInvoice>> listInvoices({int limit = 50, int offset = 0})`
- Notes: similar pattern to SalesRepository but specific to purchases.

### ProductRepository (`lib/data/repositories/product_repository.dart`)

- Selected public methods (CRUD + search helpers):
  - `createParent`, `updateParent`, `deleteParent`, `getParentById`
  - `addVariant`, `updateVariant`, `deleteVariant`, `getVariantsByParent`
  - `searchVariants(...)`, `searchInventoryRows(...)`, `getVariantDisplayName(int)`
- Notes: focused on product domain; useful for item-cache operations in offline sync.

### CustomerRepository (`lib/data/repositories/customer_repository.dart`)

- Selected public methods:
  - `listAll({limit, offset})`, `search(String q)`, `getById(int)`, `getByPhoneNumber(String)`
  - `create(Customer)`, `createResult(Customer)`, `update(Customer)`, `delete(int)`
  - `findOrCreateByPhone(String, String)` — handy for sync-friendly upserts.
- Notes: ready to back customer cache and sync flows; adapter mostly thin.

### HeldSalesRepository (`lib/data/repositories/held_sales_repository.dart`)

- Methods:
  - `Future<int> saveHeldSale(String name, List<Map<String, Object?>> items)`
  - `Future<List<Map<String, Object?>>> listHeldSales()`
  - `Future<List<Map<String, Object?>>> getItemsForHeldSale(int id)`
  - `Future<void> deleteHeldSale(int id)`
- Notes: already matches a simple CRUD shape; can be used by SyncService if desired (e.g., to sync held carts to server).

### SettingsRepository (`lib/data/repositories/settings_repository.dart`)

- Methods:
  - `Future<String?> get(String key)`
  - `Future<void> set(String key, String? value)`
- Notes: minimal; already usable to persist flags.

---

## Recommended adapter strategy

1. Define small interfaces in `lib/data/repositories/interfaces/`:

   - `InvoiceRepository` (createInvoice, listPending, getById)
   - `CustomerRepositoryInterface` if needed (but `CustomerRepository` already has good shape)
   - `ItemRepository` (getVariantRow, search, upsert)

2. Implement thin adapters that wrap existing repos:

   - `SalesInvoiceAdapter implements InvoiceRepository` — maps generic payload (Map/JSON) -> domain `Sale` + `SaleItem` and calls `SalesRepository.createSale`.
   - `PurchaseInvoiceAdapter` similarly for purchase invoices when relevant.

3. Update DI to register `InvoiceRepository` binding to the appropriate adapter depending on runtime config (e.g., POS-only build uses `SalesInvoiceAdapter`).

4. Update `SyncService` to depend on `InvoiceRepository` instead of `SalesRepository` directly.

---

## Next artifacts I can produce for you

- (A) `lib/data/repositories/interfaces/invoice_repository.dart` + `lib/data/repositories/adapters/sales_invoice_adapter.dart` (thin adapter) and DI registration.
- (B) Full machine-readable matrix of repository methods (CSV) — helpful for automated adapter generation.

Which next artifact do you want? I can implement adapter (A) now and wire it into DI and `SyncService` quickly.
