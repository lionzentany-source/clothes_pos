import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n_clean/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Clothes POS'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginEnterPassword;

  /// No description provided for @loginCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loginCancel;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// No description provided for @loginInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get loginInvalid;

  /// No description provided for @loginNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No active users'**
  String get loginNoUsers;

  /// No description provided for @posTab.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get posTab;

  /// No description provided for @inventoryTab.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTab;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @posTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posTotal;

  /// No description provided for @posCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get posCart;

  /// No description provided for @sessionNone.
  ///
  /// In en, this message translates to:
  /// **'No session'**
  String get sessionNone;

  /// No description provided for @sessionOpen.
  ///
  /// In en, this message translates to:
  /// **'Session #'**
  String get sessionOpen;

  /// No description provided for @cashSession.
  ///
  /// In en, this message translates to:
  /// **'Cash Session'**
  String get cashSession;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @xReport.
  ///
  /// In en, this message translates to:
  /// **'X Report'**
  String get xReport;

  /// No description provided for @zReport.
  ///
  /// In en, this message translates to:
  /// **'Z Report'**
  String get zReport;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @storeInfo.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInfo;

  /// No description provided for @languageCurrency.
  ///
  /// In en, this message translates to:
  /// **'Language & Currency'**
  String get languageCurrency;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @databaseSection.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get databaseSection;

  /// No description provided for @dbBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup / Restore Database'**
  String get dbBackupRestore;

  /// No description provided for @inventoryPrintRfidSection.
  ///
  /// In en, this message translates to:
  /// **'Inventory, Printing & RFID'**
  String get inventoryPrintRfidSection;

  /// No description provided for @inventorySettings.
  ///
  /// In en, this message translates to:
  /// **'Inventory Settings'**
  String get inventorySettings;

  /// No description provided for @printingSettings.
  ///
  /// In en, this message translates to:
  /// **'Printing Settings'**
  String get printingSettings;

  /// No description provided for @rfidSettings.
  ///
  /// In en, this message translates to:
  /// **'RFID Settings'**
  String get rfidSettings;

  /// No description provided for @userAccountSection.
  ///
  /// In en, this message translates to:
  /// **'User Account'**
  String get userAccountSection;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmCloseSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Session'**
  String get logoutConfirmCloseSessionTitle;

  /// No description provided for @logoutConfirmCloseSessionAmount.
  ///
  /// In en, this message translates to:
  /// **'Closing amount'**
  String get logoutConfirmCloseSessionAmount;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @posSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get posSales;

  /// No description provided for @posScanError.
  ///
  /// In en, this message translates to:
  /// **'Scan Error'**
  String get posScanError;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @noProductForBarcode.
  ///
  /// In en, this message translates to:
  /// **'No product found for that barcode'**
  String get noProductForBarcode;

  /// No description provided for @permissionDeniedSale.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to sell'**
  String get permissionDeniedSale;

  /// No description provided for @noOpenSession.
  ///
  /// In en, this message translates to:
  /// **'No open cash session'**
  String get noOpenSession;

  /// No description provided for @openSessionFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a session before selling'**
  String get openSessionFirst;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get openAction;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @multiPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Payment'**
  String get multiPaymentTitle;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get totalLabel;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @remainingCashDue.
  ///
  /// In en, this message translates to:
  /// **'Remaining Cash:'**
  String get remainingCashDue;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change:'**
  String get changeDue;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get posTitle;

  /// No description provided for @quickItems.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get quickItems;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price:'**
  String get priceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get quantityLabel;

  /// No description provided for @basket.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get basket;

  /// No description provided for @editLine.
  ///
  /// In en, this message translates to:
  /// **'Edit line'**
  String get editLine;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount (amount)'**
  String get discountAmount;

  /// No description provided for @taxAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax (amount)'**
  String get taxAmount;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @scanRfid.
  ///
  /// In en, this message translates to:
  /// **'Scan RFID'**
  String get scanRfid;

  /// No description provided for @rfidCardsOptional.
  ///
  /// In en, this message translates to:
  /// **'RFID Tags (Optional)'**
  String get rfidCardsOptional;

  /// No description provided for @addRfidCard.
  ///
  /// In en, this message translates to:
  /// **'+ Add Tag'**
  String get addRfidCard;

  /// No description provided for @addRfidTitle.
  ///
  /// In en, this message translates to:
  /// **'Add RFID Tag'**
  String get addRfidTitle;

  /// No description provided for @epcPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'EPC'**
  String get epcPlaceholder;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @pressStop.
  ///
  /// In en, this message translates to:
  /// **'Press stop when finished'**
  String get pressStop;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @addedIgnored.
  ///
  /// In en, this message translates to:
  /// **'Added {added} and ignored {ignored} (exceeded quantity)'**
  String addedIgnored(Object added, Object ignored);

  /// No description provided for @notEnabled.
  ///
  /// In en, this message translates to:
  /// **'Not Enabled'**
  String get notEnabled;

  /// No description provided for @enableRfidFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable RFID from settings first'**
  String get enableRfidFirst;

  /// No description provided for @scanError.
  ///
  /// In en, this message translates to:
  /// **'Scan Error'**
  String get scanError;

  /// No description provided for @selectVariant.
  ///
  /// In en, this message translates to:
  /// **'Select Variant'**
  String get selectVariant;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @rfiCardsLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Cannot add more: reached quantity'**
  String get rfiCardsLimitReached;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @receivedDate.
  ///
  /// In en, this message translates to:
  /// **'Received Date'**
  String get receivedDate;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @purchaseInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoice'**
  String get purchaseInvoiceTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @referenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (Optional)'**
  String get referenceOptional;

  /// No description provided for @pickVariant.
  ///
  /// In en, this message translates to:
  /// **'Pick a variant for each item'**
  String get pickVariant;

  /// No description provided for @qtyMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a number > 0'**
  String get qtyMustBePositive;

  /// No description provided for @costMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Cost must be a number >= 0'**
  String get costMustBePositive;

  /// No description provided for @rfidExceedsQty.
  ///
  /// In en, this message translates to:
  /// **'RFID tags count ({count}) exceeds quantity ({qty})'**
  String rfidExceedsQty(Object count, Object qty);

  /// No description provided for @addAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get addAtLeastOne;

  /// No description provided for @supplierIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Supplier ID required'**
  String get supplierIdRequired;

  /// No description provided for @invoiceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save invoice: {error}'**
  String invoiceSaveFailed(Object error);

  /// No description provided for @saleSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get saleSuccessTitle;

  /// No description provided for @saleNumber.
  ///
  /// In en, this message translates to:
  /// **'Sale ID: {id}'**
  String saleNumber(Object id);

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Pay Cash'**
  String get payCash;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Allowed'**
  String get permissionDeniedTitle;

  /// No description provided for @openSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get openSessionTitle;

  /// No description provided for @openingFloat.
  ///
  /// In en, this message translates to:
  /// **'Opening Float'**
  String get openingFloat;

  /// No description provided for @actualDrawerAmount.
  ///
  /// In en, this message translates to:
  /// **'Actual cash in drawer'**
  String get actualDrawerAmount;

  /// No description provided for @closedTitle.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedTitle;

  /// No description provided for @variance.
  ///
  /// In en, this message translates to:
  /// **'Variance: {value}'**
  String variance(Object value);

  /// No description provided for @cashDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Deposit'**
  String get cashDepositTitle;

  /// No description provided for @cashWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Withdrawal'**
  String get cashWithdrawTitle;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (Optional)'**
  String get reasonOptional;

  /// No description provided for @openingFloatLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening Float: {value}'**
  String openingFloatLabel(Object value);

  /// No description provided for @cashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales: {value}'**
  String cashSales(Object value);

  /// No description provided for @depositsLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposits: {value}'**
  String depositsLabel(Object value);

  /// No description provided for @withdrawalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals: {value}'**
  String withdrawalsLabel(Object value);

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash: {value}'**
  String expectedCash(Object value);

  /// No description provided for @cashSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Session'**
  String get cashSessionTitle;

  /// No description provided for @depositAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositAction;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @dailySales90.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales (last 90 days)'**
  String get dailySales90;

  /// No description provided for @monthlySales24.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales (last 24 months)'**
  String get monthlySales24;

  /// No description provided for @topProductsQty.
  ///
  /// In en, this message translates to:
  /// **'Top Products (by quantity)'**
  String get topProductsQty;

  /// No description provided for @staffPerformance.
  ///
  /// In en, this message translates to:
  /// **'Staff Performance'**
  String get staffPerformance;

  /// No description provided for @purchasesTotalPeriod.
  ///
  /// In en, this message translates to:
  /// **'Purchases Total (period)'**
  String get purchasesTotalPeriod;

  /// No description provided for @stockStatusLowFirst.
  ///
  /// In en, this message translates to:
  /// **'Stock Status (lowest qty first)'**
  String get stockStatusLowFirst;

  /// No description provided for @pickEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get pickEmployee;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get pickCategory;

  /// No description provided for @pickSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get pickSupplier;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectAction;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @stockLowIndicator.
  ///
  /// In en, this message translates to:
  /// **'SKU {sku}: {qty} - RP {rp}'**
  String stockLowIndicator(Object qty, Object rp, Object sku);

  /// No description provided for @datePickerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get datePickerSelect;

  /// No description provided for @datePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick Date'**
  String get datePickerTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search product or scan barcode'**
  String get searchPlaceholder;

  /// No description provided for @searchProductPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductPlaceholder;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size:'**
  String get sizeLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color:'**
  String get colorLabel;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU:'**
  String get skuLabel;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode:'**
  String get barcodeLabel;

  /// No description provided for @stocktakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Stocktake'**
  String get stocktakeTitle;

  /// No description provided for @countedUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get countedUnitsLabel;

  /// No description provided for @uncountedUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Uncounted'**
  String get uncountedUnitsLabel;

  /// No description provided for @countedCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Counted cost'**
  String get countedCostLabel;

  /// No description provided for @countedProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get countedProfitLabel;

  /// No description provided for @startRfid.
  ///
  /// In en, this message translates to:
  /// **'Start RFID'**
  String get startRfid;

  /// No description provided for @stopReading.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get stopReading;

  /// No description provided for @addByBarcode.
  ///
  /// In en, this message translates to:
  /// **'Add by barcode'**
  String get addByBarcode;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @returnLabel.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnLabel;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @saleReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale Receipt'**
  String get saleReceiptLabel;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @paymentMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsLabel;

  /// No description provided for @thanksLabel.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping!'**
  String get thanksLabel;

  /// No description provided for @xReportInterim.
  ///
  /// In en, this message translates to:
  /// **'X Report (Interim Summary)'**
  String get xReportInterim;

  /// No description provided for @zReportClosing.
  ///
  /// In en, this message translates to:
  /// **'Z Report (Closing)'**
  String get zReportClosing;

  /// No description provided for @sessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session: {id}'**
  String sessionLabel(Object id);

  /// No description provided for @actualAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual Amount: {value}'**
  String actualAmountLabel(Object value);

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @enableRfidReader.
  ///
  /// In en, this message translates to:
  /// **'Enable RFID Reader'**
  String get enableRfidReader;

  /// No description provided for @debounceWindowMs.
  ///
  /// In en, this message translates to:
  /// **'Debounce window (ms)'**
  String get debounceWindowMs;

  /// No description provided for @ignoreSameTagWithinDuration.
  ///
  /// In en, this message translates to:
  /// **'Ignore same tag within this duration'**
  String get ignoreSameTagWithinDuration;

  /// No description provided for @rfParamsMayRequireRestart.
  ///
  /// In en, this message translates to:
  /// **'RF parameters (may require reader restart)'**
  String get rfParamsMayRequireRestart;

  /// No description provided for @transmitPower.
  ///
  /// In en, this message translates to:
  /// **'Transmit Power (RF Power)'**
  String get transmitPower;

  /// No description provided for @numericValuePerReader.
  ///
  /// In en, this message translates to:
  /// **'Numeric value per reader'**
  String get numericValuePerReader;

  /// No description provided for @regionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionLabel;

  /// No description provided for @rfidSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'RFID settings saved successfully'**
  String get rfidSettingsSaved;

  /// No description provided for @pageSizeMm.
  ///
  /// In en, this message translates to:
  /// **'Page size (mm)'**
  String get pageSizeMm;

  /// No description provided for @widthPlaceholder58.
  ///
  /// In en, this message translates to:
  /// **'Width (58)'**
  String get widthPlaceholder58;

  /// No description provided for @heightPlaceholder200.
  ///
  /// In en, this message translates to:
  /// **'Height (200)'**
  String get heightPlaceholder200;

  /// No description provided for @marginMm.
  ///
  /// In en, this message translates to:
  /// **'Margin (mm)'**
  String get marginMm;

  /// No description provided for @marginPlaceholder6.
  ///
  /// In en, this message translates to:
  /// **'Margin (6)'**
  String get marginPlaceholder6;

  /// No description provided for @fontSizePt.
  ///
  /// In en, this message translates to:
  /// **'Font size (pt)'**
  String get fontSizePt;

  /// No description provided for @fontSizePlaceholder10.
  ///
  /// In en, this message translates to:
  /// **'Font size (10)'**
  String get fontSizePlaceholder10;

  /// No description provided for @printingSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Printing settings saved'**
  String get printingSettingsSaved;

  /// No description provided for @lowStockWarningThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low stock warning threshold (quantity)'**
  String get lowStockWarningThreshold;

  /// No description provided for @example5Placeholder.
  ///
  /// In en, this message translates to:
  /// **'Example: 5'**
  String get example5Placeholder;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @storeNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeNamePlaceholder;

  /// No description provided for @addressPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressPlaceholder;

  /// No description provided for @currencyPlaceholderLyd.
  ///
  /// In en, this message translates to:
  /// **'Currency (LYD)'**
  String get currencyPlaceholderLyd;

  /// No description provided for @infoSaved.
  ///
  /// In en, this message translates to:
  /// **'Information saved'**
  String get infoSaved;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupNow;

  /// No description provided for @restoreNow.
  ///
  /// In en, this message translates to:
  /// **'Restore Now'**
  String get restoreNow;

  /// No description provided for @dbFilePathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DB file path'**
  String get dbFilePathPlaceholder;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @backupCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Backup created at:\n{path}'**
  String backupCreatedAt(Object path);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup Failed'**
  String get backupFailed;

  /// No description provided for @clearCartConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get clearCartConfirmation;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @saleHeld.
  ///
  /// In en, this message translates to:
  /// **'Sale held'**
  String get saleHeld;

  /// No description provided for @heldSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Held sales'**
  String get heldSalesTitle;

  /// No description provided for @noHeldSales.
  ///
  /// In en, this message translates to:
  /// **'No held sales'**
  String get noHeldSales;

  /// No description provided for @holdNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Hold name (optional)'**
  String get holdNamePlaceholder;

  /// No description provided for @restoreSale.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSale;

  /// No description provided for @holdSaved.
  ///
  /// In en, this message translates to:
  /// **'Sale held'**
  String get holdSaved;

  /// No description provided for @enterDbPathFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter .db file path first'**
  String get enterDbPathFirst;

  /// No description provided for @fileDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get fileDoesNotExist;

  /// No description provided for @schemaVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'Schema version mismatch (current: {current}, backup: {backup})'**
  String schemaVersionMismatch(Object backup, Object current);

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore completed successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore Failed'**
  String get restoreFailed;

  /// No description provided for @backupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSection;

  /// No description provided for @restoreSection.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSection;

  /// No description provided for @restoreVersionPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Version Mismatch'**
  String get restoreVersionPromptTitle;

  /// No description provided for @restoreVersionPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Current schema {current} vs backup {backup}. Proceed anyway? (App may crash if incompatible)'**
  String restoreVersionPromptMessage(Object backup, Object current);

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @sameVersion.
  ///
  /// In en, this message translates to:
  /// **'Versions match ({version})'**
  String sameVersion(Object version);

  /// No description provided for @openPrintDialog.
  ///
  /// In en, this message translates to:
  /// **'Open print dialog'**
  String get openPrintDialog;

  /// No description provided for @defaultPrinter.
  ///
  /// In en, this message translates to:
  /// **'Default printer'**
  String get defaultPrinter;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @choosePrinter.
  ///
  /// In en, this message translates to:
  /// **'Choose Printer'**
  String get choosePrinter;

  /// No description provided for @clearDefault.
  ///
  /// In en, this message translates to:
  /// **'Clear Default'**
  String get clearDefault;

  /// No description provided for @testPrinter.
  ///
  /// In en, this message translates to:
  /// **'Test Printer'**
  String get testPrinter;

  /// No description provided for @manageAttributesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Attributes'**
  String get manageAttributesTitle;

  /// No description provided for @attributeNoun.
  ///
  /// In en, this message translates to:
  /// **'Attribute'**
  String get attributeNoun;

  /// No description provided for @noValuesYet.
  ///
  /// In en, this message translates to:
  /// **'No values yet'**
  String get noValuesYet;

  /// No description provided for @valueNoun.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueNoun;

  /// No description provided for @noAttributesLoaded.
  ///
  /// In en, this message translates to:
  /// **'No attributes loaded'**
  String get noAttributesLoaded;

  /// No description provided for @addNewAttribute.
  ///
  /// In en, this message translates to:
  /// **'Add attribute'**
  String get addNewAttribute;

  /// No description provided for @attributeNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Attribute name'**
  String get attributeNamePlaceholder;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @attributeExists.
  ///
  /// In en, this message translates to:
  /// **'An attribute with that name already exists'**
  String get attributeExists;

  /// No description provided for @attributeAdded.
  ///
  /// In en, this message translates to:
  /// **'Attribute added'**
  String get attributeAdded;

  /// No description provided for @editAttribute.
  ///
  /// In en, this message translates to:
  /// **'Edit attribute'**
  String get editAttribute;

  /// No description provided for @attributeSaved.
  ///
  /// In en, this message translates to:
  /// **'Attribute saved'**
  String get attributeSaved;

  /// No description provided for @addNewValue.
  ///
  /// In en, this message translates to:
  /// **'Add value'**
  String get addNewValue;

  /// No description provided for @valuePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valuePlaceholder;

  /// No description provided for @valueRequired.
  ///
  /// In en, this message translates to:
  /// **'Value is required'**
  String get valueRequired;

  /// No description provided for @valueAdded.
  ///
  /// In en, this message translates to:
  /// **'Value added'**
  String get valueAdded;

  /// No description provided for @editValue.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get editValue;

  /// No description provided for @valueSaved.
  ///
  /// In en, this message translates to:
  /// **'Value saved'**
  String get valueSaved;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// No description provided for @deleteAttributePrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete attribute {name}?'**
  String deleteAttributePrompt(Object name);

  /// No description provided for @deleteValuePrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete value {value}?'**
  String deleteValuePrompt(Object value);

  /// No description provided for @attributeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Attribute deleted'**
  String get attributeDeleted;

  /// No description provided for @valueDeleted.
  ///
  /// In en, this message translates to:
  /// **'Value deleted'**
  String get valueDeleted;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCart;

  /// No description provided for @holdCart.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get holdCart;

  /// No description provided for @waitingSales.
  ///
  /// In en, this message translates to:
  /// **'Waiting Sales'**
  String get waitingSales;

  /// No description provided for @returnService.
  ///
  /// In en, this message translates to:
  /// **'Return Service'**
  String get returnService;

  /// No description provided for @returnProduct.
  ///
  /// In en, this message translates to:
  /// **'Return Product'**
  String get returnProduct;

  /// No description provided for @returnFullInvoice.
  ///
  /// In en, this message translates to:
  /// **'Return Full Invoice'**
  String get returnFullInvoice;

  /// No description provided for @returnType.
  ///
  /// In en, this message translates to:
  /// **'Return Type'**
  String get returnType;

  /// No description provided for @selectReturnType.
  ///
  /// In en, this message translates to:
  /// **'Select return type'**
  String get selectReturnType;

  /// No description provided for @saleIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale ID'**
  String get saleIdLabel;

  /// No description provided for @returnReason.
  ///
  /// In en, this message translates to:
  /// **'Return reason'**
  String get returnReason;

  /// No description provided for @returnReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Return reason (optional)'**
  String get returnReasonOptional;

  /// No description provided for @returnSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Completed'**
  String get returnSuccessTitle;

  /// No description provided for @returnSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Return has been processed successfully'**
  String get returnSuccessMessage;

  /// No description provided for @returnItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Items'**
  String get returnItemsTitle;

  /// No description provided for @noReturnableItems.
  ///
  /// In en, this message translates to:
  /// **'No returnable items found'**
  String get noReturnableItems;

  /// No description provided for @returnQty.
  ///
  /// In en, this message translates to:
  /// **'Return Qty'**
  String get returnQty;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @totalRefund.
  ///
  /// In en, this message translates to:
  /// **'Total Refund'**
  String get totalRefund;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process Return'**
  String get processReturn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
