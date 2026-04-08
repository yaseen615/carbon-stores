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

  // ─── External API ───
  static const String graphqlEndpoint =
      'https://dev.carbongurukulam.in/graphql/';

  // ─── Audit Actions ───
  static const String auditSale = 'sale';
  static const String auditRecharge = 'recharge';
  static const String auditEdit = 'edit';
  static const String auditStockIn = 'stock_in';
  static const String auditExpense = 'expense';
  static const String auditSync = 'sync';

  // ─── Stock Thresholds ───
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 3;

  // ═══════════════════════════════════════════════════════════════
  //  APPLE HIG SPACING SYSTEM (8pt grid)
  // ═══════════════════════════════════════════════════════════════
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ─── Corner Radii ───
  static const double radiusSmall = 10.0;
  static const double radius = 14.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;  // Pill shape

  // ─── UI Dimensions ───
  static const double sidebarWidth = 76.0;
  static const double sidebarExpandedWidth = 220.0;
  static const double posLeftRatio = 0.70;
  static const double posRightRatio = 0.30;
  static const int productGridCrossAxisCount = 3;  // Bigger touch targets
  static const double productTileHeight = 140.0;

  // ─── Animation Durations ───
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  // ─── Shadow System ───
  // Level 1: Subtle card shadow
  // Level 2: Raised panel shadow
  // Level 3: Modal/floating shadow

  // ─── Currency ───
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String currencyLocale = 'en_IN';

  // ─── Splash ───
  static const int splashDurationMs = 2000;
}
