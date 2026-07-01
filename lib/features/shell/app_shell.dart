import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/responsive_helper.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../pos/pos_screen.dart';
import '../students/students_screen.dart';
import '../inventory/inventory_screen.dart';
import '../expenses/expenses_screen.dart';
import '../analytics/analytics_screen.dart';
import '../transactions/transactions_screen.dart';
import '../audit/audit_screen.dart';
import '../accounts/accounts_screen.dart';
import '../debts/debts_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../pos/widgets/pos_stats_bar.dart';
import '../../core/utils/exporter/csv_exporter_stub.dart'
    if (dart.library.html) '../../core/utils/exporter/csv_exporter_web.dart'
    if (dart.library.io) '../../core/utils/exporter/csv_exporter_mobile.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final device = Responsive.of(context);
    final cs = Theme.of(context).colorScheme;

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.01),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildPage(currentPage),
    );

    // ─── Phone Layout: Bottom Tab Bar ───
    if (device == DeviceType.phone) {
      return _PhoneShell(
        currentPage: currentPage,
        content: content,
        onPageSelected: (page) {
          ref.read(currentPageProvider.notifier).state = page;
        },
        onShowSettings: () => _showSettingsModal(context, ref),
      );
    }

    // ─── Desktop & Tablet Layout: Drawer ───
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(currentPage),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      drawer: Drawer(
        width: 250,
        child: _SideNav(
          currentPage: currentPage,
          isMobile: true,
          onPageSelected: (page) {
            ref.read(currentPageProvider.notifier).state = page;
            Navigator.pop(context);
          },
        ),
      ),
      body: content,
    );
  }

  String _getPageTitle(AppPage page) {
    switch (page) {
      case AppPage.pos:
        return 'Point of Sale';
      case AppPage.students:
        return 'Students';
      case AppPage.inventory:
        return 'Inventory';
      case AppPage.expenses:
        return 'Expenses';
      case AppPage.analytics:
        return 'Analytics';
      case AppPage.transactions:
        return 'Transactions';
      case AppPage.auditLog:
        return 'Audit Log';
      case AppPage.accounts:
        return 'Accounts';
      case AppPage.debts:
        return 'Debts';
      case AppPage.suppliers:
        return 'Suppliers';
    }
  }

  Widget _buildPage(AppPage page) {
    switch (page) {
      case AppPage.pos:
        return const PosScreen(key: ValueKey('pos'));
      case AppPage.students:
        return const StudentsScreen(key: ValueKey('students'));
      case AppPage.inventory:
        return const InventoryScreen(key: ValueKey('inventory'));
      case AppPage.expenses:
        return const ExpensesScreen(key: ValueKey('expenses'));
      case AppPage.analytics:
        return const AnalyticsScreen(key: ValueKey('analytics'));
      case AppPage.transactions:
        return const TransactionsScreen(key: ValueKey('transactions'));
      case AppPage.auditLog:
        return const AuditScreen(key: ValueKey('auditLog'));
      case AppPage.accounts:
        return const AccountsScreen(key: ValueKey('accounts'));
      case AppPage.debts:
        return const DebtsScreen(key: ValueKey('debts'));
      case AppPage.suppliers:
        return const SuppliersScreen(key: ValueKey('suppliers'));
    }
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showAppModal(
      context: context,
      maxWidth: 400,
      builder: (ctx) => _SettingsModalContent(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Phone Shell — iOS-style bottom tab bar with translucent blur
// ═══════════════════════════════════════════════════════════════════════

class _PhoneShell extends StatelessWidget {
  final AppPage currentPage;
  final Widget content;
  final ValueChanged<AppPage> onPageSelected;
  final VoidCallback onShowSettings;

  const _PhoneShell({
    required this.currentPage,
    required this.content,
    required this.onPageSelected,
    required this.onShowSettings,
  });

  /// The 5 bottom tab items. "More" is handled separately.
  static const _primaryTabs = [
    (page: AppPage.pos, icon: Icons.point_of_sale_rounded, activeIcon: Icons.point_of_sale_rounded, label: 'Sales'),
    (page: AppPage.inventory, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Products'),
    (page: AppPage.students, icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Students'),
    (page: AppPage.analytics, icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Analytics'),
  ];

  /// Pages accessible under the "More" tab
  static const _morePages = [
    (page: AppPage.expenses, icon: Icons.receipt_long_outlined, label: 'Expenses'),
    (page: AppPage.accounts, icon: Icons.account_balance_outlined, label: 'Accounts'),
    (page: AppPage.debts, icon: Icons.money_off_csred_outlined, label: 'Debts'),
    (page: AppPage.suppliers, icon: Icons.local_shipping_outlined, label: 'Suppliers'),
    (page: AppPage.transactions, icon: Icons.history_rounded, label: 'History'),
    (page: AppPage.auditLog, icon: Icons.fact_check_outlined, label: 'Audit Log'),
  ];

  bool get _isMorePage =>
      _morePages.any((m) => m.page == currentPage);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: content,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surface.withValues(alpha: 0.85)
                  : cs.surface.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ..._primaryTabs.map((tab) => _BottomTabItem(
                          icon: tab.icon,
                          activeIcon: tab.activeIcon,
                          label: tab.label,
                          isSelected: currentPage == tab.page,
                          onTap: () => onPageSelected(tab.page),
                        )),
                    _BottomTabItem(
                      icon: Icons.more_horiz_rounded,
                      activeIcon: Icons.more_horiz_rounded,
                      label: 'More',
                      isSelected: _isMorePage,
                      onTap: () => _showMoreSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'More',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ..._morePages.map((item) => _MoreSheetItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: currentPage == item.page,
                      onTap: () {
                        Navigator.pop(ctx);
                        onPageSelected(item.page);
                      },
                    )),
                _MoreSheetItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(ctx);
                    onShowSettings();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoreSheetItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.onSurfaceVariant.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Sidebar Navigation (Desktop + Tablet Drawer — unchanged)
// ═══════════════════════════════════════════════════════════════════════

class _SideNav extends ConsumerWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;
  final bool isMobile;

  const _SideNav({
    required this.currentPage,
    required this.onPageSelected,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: isMobile ? double.infinity : 150,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          if (!isMobile)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 16,
              offset: const Offset(4, 0),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 16),
            child: Text(
              'Home',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 28 : 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (currentPage == AppPage.pos)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0),
              child: const PosStatsBar(),
            ),

          if (currentPage != AppPage.pos) SizedBox(height: isMobile ? 32 : 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sales',
                  isSelected: currentPage == AppPage.pos,
                  onTap: () => onPageSelected(AppPage.pos),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  isSelected: currentPage == AppPage.inventory,
                  onTap: () => onPageSelected(AppPage.inventory),
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Students',
                  isSelected: currentPage == AppPage.students,
                  onTap: () => onPageSelected(AppPage.students),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Expenses',
                  isSelected: currentPage == AppPage.expenses,
                  onTap: () => onPageSelected(AppPage.expenses),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  isSelected: currentPage == AppPage.analytics,
                  onTap: () => onPageSelected(AppPage.analytics),
                ),
                _NavItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Accounts',
                  isSelected: currentPage == AppPage.accounts,
                  onTap: () => onPageSelected(AppPage.accounts),
                ),
                _NavItem(
                  icon: Icons.money_off_csred_outlined,
                  label: 'Debts',
                  isSelected: currentPage == AppPage.debts,
                  onTap: () => onPageSelected(AppPage.debts),
                ),
                _NavItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Suppliers',
                  isSelected: currentPage == AppPage.suppliers,
                  onTap: () => onPageSelected(AppPage.suppliers),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isSelected: currentPage == AppPage.transactions,
                  onTap: () => onPageSelected(AppPage.transactions),
                ),
                _NavItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Audit',
                  isSelected: currentPage == AppPage.auditLog,
                  onTap: () => onPageSelected(AppPage.auditLog),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _NavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: false,
              onTap: () => _showSettingsModal(context, ref),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showAppModal(
      context: context,
      maxWidth: 400,
      builder: (ctx) => _SettingsModalContent(),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWide ? 4 : 6),
      child: MouseRegion(
        onEnter: (_) => isWide ? setState(() => _isHovered = true) : null,
        onExit: (_) => isWide ? setState(() => _isHovered = false) : null,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              vertical: isWide ? 14 : 18,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? cs.primary.withValues(alpha: isWide ? 0.12 : 0.08)
                  : _isHovered
                      ? cs.onSurfaceVariant.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: isWide ? 22 : 24,
                  color: widget.isSelected
                      ? cs.primary
                      : _isHovered
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: isWide ? 14 : 16,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected
                          ? cs.primary
                          : _isHovered
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Settings Modal (shared by all layouts)
// ═══════════════════════════════════════════════════════════════════════

class _SettingsModalContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return AppModalContent(
      title: 'Settings',
      titleIcon: Icons.settings_rounded,
      maxWidth: 400,
      children: [
        // ─── Theme Toggle ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pos.fill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  return RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  size: 26,
                  color: isDark
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Dark theme active' : 'Light theme active',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (_) {
                  ref.read(themeProvider.notifier).toggle();
                },
                activeTrackColor: cs.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── Theme Preview Chips ───
        Row(
          children: [
            Expanded(
              child: _ThemePreviewChip(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                isSelected: !isDark,
                bgPreview: const Color(0xFFF2F2F7),
                fgPreview: const Color(0xFF007AFF),
                onTap: () {
                  if (isDark) ref.read(themeProvider.notifier).toggle();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemePreviewChip(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                isSelected: isDark,
                bgPreview: const Color(0xFF1C1C1E),
                fgPreview: const Color(0xFF0A84FF),
                onTap: () {
                  if (!isDark) ref.read(themeProvider.notifier).toggle();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildSettingTile(
          context,
          icon: Icons.cloud_download_rounded,
          title: 'Export Database',
          subtitle: 'Download DB as JSON',
          color: cs.primary,
          onTap: () => _exportAllData(context, ref),
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          context,
          icon: Icons.image_outlined,
          title: 'Export Images Backup',
          subtitle: 'Download images as ZIP',
          color: pos.info,
          onTap: () => _exportImages(context),
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          context,
          icon: Icons.upload_file_rounded,
          title: 'Import Images Backup',
          subtitle: 'Restore images from ZIP',
          color: pos.success,
          onTap: () => _importImages(context),
        ),

        const SizedBox(height: 24),

        Center(
          child: Text(
            'CarbonGurukulam Store v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 16 : 18),
          decoration: BoxDecoration(
            color: pos.fill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: isDesktop ? 22 : 24, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 13 : 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _exportAllData(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing full data export...')),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      final products = await firestore.collection('products').get();
      final students = await firestore.collection('students').get();
      final transactions = await firestore.collection('transactions').get();
      final expenses = await firestore.collection('expenses').get();
      final auditLogs = await firestore.collection('audit_logs').get();

      final backup = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'products':
            products.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'students':
            students.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'transactions':
            transactions.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'expenses':
            expenses.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'audit_logs':
            auditLogs.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final timestamp = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      await saveAndShareFile('CG_Store_Backup_$timestamp.json', jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Full backup exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _exportImages(BuildContext context) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing images backup...')),
    );
    try {
      final path = await LocalStorageService().exportBackup();
      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved to $path')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Export cancelled or not supported for native web.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _importImages(BuildContext context) async {
    Navigator.pop(context); // Close drawer

    final progressNotifier = ValueNotifier<String>('Waiting for file...');
    final progressValueNotifier = ValueNotifier<double>(0.0);
    bool dialogShown = false;

    // Show initial picker snackbar just to acknowledge click
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Picking backup file...'),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await LocalStorageService().importBackup(
      onProgress: (current, total, status) {
        if (!dialogShown && status != 'Waiting for file selection...') {
          dialogShown = true;
          // As soon as file is picked, show blocking progress dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final cs = Theme.of(ctx).colorScheme;
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                backgroundColor: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: cs.primary),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<String>(
                        valueListenable: progressNotifier,
                        builder: (context, val, _) => Text(
                          val,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<double>(
                        valueListenable: progressValueNotifier,
                        builder: (context, val, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: val > 0 ? val : null,
                            minHeight: 8,
                            backgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(cs.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Update values
        progressNotifier.value = status;
        if (total > 0) {
          progressValueNotifier.value = current / total;
        }
      },
    );

    if (!context.mounted) return;

    if (dialogShown) {
      Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
    }

    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    // Show result dialog
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: cs.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (result.isError ? pos.error : pos.success)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.isError
                        ? Icons.error_outline_rounded
                        : result.count > 0
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                    color: result.isError ? pos.error : pos.success,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  result.isError
                      ? 'Import Failed'
                      : result.count > 0
                          ? 'Import Successful'
                          : 'No Images Found',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          result.isError ? pos.error : cs.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color bgPreview;
  final Color fgPreview;
  final VoidCallback onTap;

  const _ThemePreviewChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.bgPreview,
    required this.fgPreview,
    required this.onTap,
  });

  @override
  State<_ThemePreviewChip> createState() => _ThemePreviewChipState();
}

class _ThemePreviewChipState extends State<_ThemePreviewChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.bgPreview,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.fgPreview
                  : _isHovered
                      ? widget.fgPreview.withValues(alpha: 0.4)
                      : Colors.transparent,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 20, color: widget.fgPreview),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.fgPreview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
