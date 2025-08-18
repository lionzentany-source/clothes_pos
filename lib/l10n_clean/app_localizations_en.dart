// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clothes POS';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginEnterPassword => 'Enter password';

  @override
  String get loginCancel => 'Cancel';

  @override
  String get loginContinue => 'Continue';

  @override
  String get loginInvalid => 'Invalid credentials';

  @override
  String get loginNoUsers => 'No active users';

  @override
  String get posTab => 'Sales';

  @override
  String get inventoryTab => 'Inventory';

  @override
  String get reportsTab => 'Reports';

  @override
  String get settingsTab => 'Settings';

  @override
  String get posTotal => 'Total';

  @override
  String get posCart => 'Cart';

  @override
  String get sessionNone => 'No session';

  @override
  String get sessionOpen => 'Session #';

  @override
  String get cashSession => 'Cash Session';

  @override
  String get open => 'Open';

  @override
  String get close => 'Close';

  @override
  String get deposit => 'Deposit';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get xReport => 'X Report';

  @override
  String get zReport => 'Z Report';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get generalSection => 'General';

  @override
  String get storeInfo => 'Store Information';

  @override
  String get languageCurrency => 'Language & Currency';

  @override
  String get changePassword => 'Change Password';

  @override
  String get databaseSection => 'Database';

  @override
  String get dbBackupRestore => 'Backup / Restore Database';

  @override
  String get inventoryPrintRfidSection => 'Inventory, Printing & RFID';

  @override
  String get inventorySettings => 'Inventory Settings';

  @override
  String get printingSettings => 'Printing Settings';

  @override
  String get rfidSettings => 'RFID Settings';

  @override
  String get userAccountSection => 'User Account';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmCloseSessionTitle => 'Close Session';

  @override
  String get logoutConfirmCloseSessionAmount => 'Closing amount';

  @override
  String get error => 'Error';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get endSession => 'End Session';

  @override
  String get cancel => 'Cancel';

  @override
  String get posSales => 'Sales';

  @override
  String get posScanError => 'Scan Error';

  @override
  String get notFound => 'Not Found';

  @override
  String get noProductForBarcode => 'No product found for that barcode';

  @override
  String get permissionDeniedSale => 'You do not have permission to sell';

  @override
  String get noOpenSession => 'No open cash session';

  @override
  String get openSessionFirst => 'Open a session before selling';

  @override
  String get ok => 'OK';

  @override
  String get closeAction => 'Close';

  @override
  String get openAction => 'Start Session';

  @override
  String get confirm => 'Confirm';

  @override
  String get multiPaymentTitle => 'Multiple Payment';

  @override
  String get totalLabel => 'Total:';

  @override
  String get card => 'Card';

  @override
  String get mobile => 'Mobile';

  @override
  String get cash => 'Cash';

  @override
  String get remainingCashDue => 'Remaining Cash:';

  @override
  String get changeDue => 'Change:';

  @override
  String get posTitle => 'Point of Sale';

  @override
  String get quickItems => 'Quick';

  @override
  String get priceLabel => 'Price:';

  @override
  String get quantityLabel => 'Qty:';

  @override
  String get basket => 'Cart';

  @override
  String get editLine => 'Edit line';

  @override
  String get discountAmount => 'Discount (amount)';

  @override
  String get taxAmount => 'Tax (amount)';

  @override
  String get noteLabel => 'Note';

  @override
  String get exact => 'Exact';

  @override
  String get item => 'Item';

  @override
  String get delete => 'Delete';

  @override
  String get addItem => 'Add Item';

  @override
  String get scanRfid => 'Scan RFID';

  @override
  String get rfidCardsOptional => 'RFID Tags (Optional)';

  @override
  String get addRfidCard => '+ Add Tag';

  @override
  String get addRfidTitle => 'Add RFID Tag';

  @override
  String get epcPlaceholder => 'EPC';

  @override
  String get stop => 'Stop';

  @override
  String get scanning => 'Scanning...';

  @override
  String get pressStop => 'Press stop when finished';

  @override
  String get warning => 'Warning';

  @override
  String addedIgnored(Object added, Object ignored) {
    return 'Added $added and ignored $ignored (exceeded quantity)';
  }

  @override
  String get notEnabled => 'Not Enabled';

  @override
  String get enableRfidFirst => 'Enable RFID from settings first';

  @override
  String get scanError => 'Scan Error';

  @override
  String get selectVariant => 'Select Variant';

  @override
  String get quantity => 'Quantity';

  @override
  String get cost => 'Cost';

  @override
  String get rfiCardsLimitReached => 'Cannot add more: reached quantity';

  @override
  String get choose => 'Choose';

  @override
  String get receivedDate => 'Received Date';

  @override
  String get change => 'Change';

  @override
  String get done => 'Done';

  @override
  String get items => 'Items';

  @override
  String get purchaseInvoiceTitle => 'Purchase Invoice';

  @override
  String get save => 'Save';

  @override
  String get supplier => 'Supplier';

  @override
  String get select => 'Select';

  @override
  String get referenceOptional => 'Reference (Optional)';

  @override
  String get pickVariant => 'Pick a variant for each item';

  @override
  String get qtyMustBePositive => 'Quantity must be a number > 0';

  @override
  String get costMustBePositive => 'Cost must be a number >= 0';

  @override
  String rfidExceedsQty(Object count, Object qty) {
    return 'RFID tags count ($count) exceeds quantity ($qty)';
  }

  @override
  String get addAtLeastOne => 'Add at least one item';

  @override
  String get supplierIdRequired => 'Supplier ID required';

  @override
  String invoiceSaveFailed(Object error) {
    return 'Failed to save invoice: $error';
  }

  @override
  String get saleSuccessTitle => 'Success';

  @override
  String saleNumber(Object id) {
    return 'Sale ID: $id';
  }

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get payCash => 'Pay Cash';

  @override
  String get permissionDeniedTitle => 'Not Allowed';

  @override
  String get openSessionTitle => 'Start Session';

  @override
  String get openingFloat => 'Opening Float';

  @override
  String get actualDrawerAmount => 'Actual cash in drawer';

  @override
  String get closedTitle => 'Closed';

  @override
  String variance(Object value) {
    return 'Variance: $value';
  }

  @override
  String get cashDepositTitle => 'Cash Deposit';

  @override
  String get cashWithdrawTitle => 'Cash Withdrawal';

  @override
  String get amount => 'Amount';

  @override
  String get reasonOptional => 'Reason (Optional)';

  @override
  String openingFloatLabel(Object value) {
    return 'Opening Float: $value';
  }

  @override
  String cashSales(Object value) {
    return 'Cash Sales: $value';
  }

  @override
  String depositsLabel(Object value) {
    return 'Deposits: $value';
  }

  @override
  String withdrawalsLabel(Object value) {
    return 'Withdrawals: $value';
  }

  @override
  String expectedCash(Object value) {
    return 'Expected Cash: $value';
  }

  @override
  String get cashSessionTitle => 'Cash Session';

  @override
  String get depositAction => 'Deposit';

  @override
  String get withdrawAction => 'Withdraw';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get dailySales90 => 'Daily Sales (last 90 days)';

  @override
  String get monthlySales24 => 'Monthly Sales (last 24 months)';

  @override
  String get topProductsQty => 'Top Products (by quantity)';

  @override
  String get staffPerformance => 'Staff Performance';

  @override
  String get purchasesTotalPeriod => 'Purchases Total (period)';

  @override
  String get stockStatusLowFirst => 'Stock Status (lowest qty first)';

  @override
  String get pickEmployee => 'Select Employee';

  @override
  String get pickCategory => 'Select Category';

  @override
  String get pickSupplier => 'Select Supplier';

  @override
  String get selectAction => 'Select';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String stockLowIndicator(Object qty, Object rp, Object sku) {
    return 'SKU $sku: $qty — RP $rp';
  }

  @override
  String get datePickerSelect => 'Select';

  @override
  String get datePickerTitle => 'Pick Date';

  @override
  String get searchPlaceholder => 'Search product or scan barcode';

  @override
  String get searchProductPlaceholder => 'Search products...';

  @override
  String get sizeLabel => 'Size:';

  @override
  String get colorLabel => 'Color:';

  @override
  String get skuLabel => 'SKU:';

  @override
  String get barcodeLabel => 'Barcode:';

  @override
  String get stocktakeTitle => 'Stocktake';

  @override
  String get countedUnitsLabel => 'Counted';

  @override
  String get uncountedUnitsLabel => 'Uncounted';

  @override
  String get countedCostLabel => 'Counted cost';

  @override
  String get countedProfitLabel => 'Profit';

  @override
  String get startRfid => 'Start RFID';

  @override
  String get stopReading => 'Stop reading';

  @override
  String get addByBarcode => 'Add by barcode';

  @override
  String get categories => 'Categories';

  @override
  String get checkout => 'Checkout';

  @override
  String get addAction => 'Add';

  @override
  String get returnLabel => 'Return';

  @override
  String get currency => 'Currency';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get saleReceiptLabel => 'Sale Receipt';

  @override
  String get userLabel => 'User';

  @override
  String get paymentMethodsLabel => 'Payment Methods';

  @override
  String get thanksLabel => 'Thank you for shopping!';

  @override
  String get xReportInterim => 'X Report (Interim Summary)';

  @override
  String get zReportClosing => 'Z Report (Closing)';

  @override
  String sessionLabel(Object id) {
    return 'Session: $id';
  }

  @override
  String actualAmountLabel(Object value) {
    return 'Actual Amount: $value';
  }

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get enableRfidReader => 'Enable RFID Reader';

  @override
  String get debounceWindowMs => 'Debounce window (ms)';

  @override
  String get ignoreSameTagWithinDuration =>
      'Ignore same tag within this duration';

  @override
  String get rfParamsMayRequireRestart =>
      'RF parameters (may require reader restart)';

  @override
  String get transmitPower => 'Transmit Power (RF Power)';

  @override
  String get numericValuePerReader => 'Numeric value per reader';

  @override
  String get regionLabel => 'Region';

  @override
  String get rfidSettingsSaved => 'RFID settings saved successfully';

  @override
  String get pageSizeMm => 'Page size (mm)';

  @override
  String get widthPlaceholder58 => 'Width (58)';

  @override
  String get heightPlaceholder200 => 'Height (200)';

  @override
  String get marginMm => 'Margin (mm)';

  @override
  String get marginPlaceholder6 => 'Margin (6)';

  @override
  String get fontSizePt => 'Font size (pt)';

  @override
  String get fontSizePlaceholder10 => 'Font size (10)';

  @override
  String get printingSettingsSaved => 'Printing settings saved';

  @override
  String get lowStockWarningThreshold =>
      'Low stock warning threshold (quantity)';

  @override
  String get example5Placeholder => 'Example: 5';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get storeNamePlaceholder => 'Store Name';

  @override
  String get addressPlaceholder => 'Address';

  @override
  String get currencyPlaceholderLyd => 'Currency (LYD)';

  @override
  String get infoSaved => 'Information saved';

  @override
  String get backupNow => 'Backup Now';

  @override
  String get restoreNow => 'Restore Now';

  @override
  String get dbFilePathPlaceholder => 'DB file path';

  @override
  String get chooseFile => 'Choose File';

  @override
  String backupCreatedAt(Object path) {
    return 'Backup created at:\n$path';
  }

  @override
  String get backupFailed => 'Backup Failed';

  @override
  String get enterDbPathFirst => 'Enter .db file path first';

  @override
  String get fileDoesNotExist => 'File does not exist';

  @override
  String schemaVersionMismatch(Object backup, Object current) {
    return 'Schema version mismatch (current: $current, backup: $backup)';
  }

  @override
  String get restoreSuccess => 'Restore completed successfully';

  @override
  String get restoreFailed => 'Restore Failed';

  @override
  String get backupSection => 'Backup';

  @override
  String get restoreSection => 'Restore';

  @override
  String get restoreVersionPromptTitle => 'Version Mismatch';

  @override
  String restoreVersionPromptMessage(Object backup, Object current) {
    return 'Current schema $current vs backup $backup. Proceed anyway? (App may crash if incompatible)';
  }

  @override
  String get proceed => 'Proceed';

  @override
  String get skip => 'Skip';

  @override
  String sameVersion(Object version) {
    return 'Versions match ($version)';
  }

  @override
  String get openPrintDialog => 'Open print dialog';

  @override
  String get defaultPrinter => 'Default printer';

  @override
  String get none => 'None';

  @override
  String get choosePrinter => 'Choose Printer';

  @override
  String get clearDefault => 'Clear Default';

  @override
  String get testPrinter => 'Test Printer';
}
