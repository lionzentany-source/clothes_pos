class AppPermissions {
  static const viewReports = 'view_reports';
  static const editProducts = 'edit_products';
  static const performSales = 'perform_sales';
  static const performPurchases = 'perform_purchases';
  static const adjustStock = 'adjust_stock';
  static const manageUsers = 'manage_users';
  static const manageCustomers = 'manage_customers';
  static const recordExpenses = 'record_expenses';
  static const all = <String>{
    viewReports,
    editProducts,
    performSales,
    performPurchases,
    adjustStock,
    manageUsers,
    manageCustomers,
    recordExpenses,
  };
}
