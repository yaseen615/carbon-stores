class AppConstants {
  AppConstants._();

  // ─── App Info ───
  static const String appName = 'CarbonGurukulam Store';
  static const String appShortName = 'CG Store';
  static const String appVersion = '1.0.0';

  // ─── Firestore Collections ───
  static const String productsCollection = 'products';
  static const String studentsCollection = 'students';
  static const String transactionsCollection = 'transactions';
  static const String expensesCollection = 'expenses';
  static const String auditLogsCollection = 'audit_logs';

  // ─── Payment Modes ───
  static const String paymentCash = 'cash';
  static const String paymentWallet = 'wallet';
  static const String paymentMixed = 'mixed';

  // ─── Audit Actions ───
  static const String auditSale = 'sale';
  static const String auditRecharge = 'recharge';
  static const String auditEdit = 'edit';
  static const String auditStockIn = 'stock_in';
  static const String auditExpense = 'expense';

  // ─── Stock Thresholds ───
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 3;

  // ─── UI ───
  static const double sidebarWidth = 80.0;
  static const double sidebarExpandedWidth = 220.0;
  static const double posLeftRatio = 0.70;
  static const double posRightRatio = 0.30;
  static const int productGridCrossAxisCount = 4;
  static const double productTileHeight = 120.0;

  // ─── Currency ───
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String currencyLocale = 'en_IN';

  // ─── Splash ───
  static const int splashDurationMs = 2000;
}
