import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/navigation_provider.dart';
import '../pos/pos_screen.dart';
import '../students/students_screen.dart';
import '../inventory/inventory_screen.dart';
import '../expenses/expenses_screen.dart';
import '../analytics/analytics_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ─── Sidebar Navigation Rail ───
          _SideNav(
            currentPage: currentPage,
            onPageSelected: (page) {
              ref.read(currentPageProvider.notifier).state = page;
            },
          ),

          // ─── Divider ───
          Container(
            width: 1,
            color: AppColors.divider,
          ),

          // ─── Page Content ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildPage(currentPage),
            ),
          ),
        ],
      ),
    );
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
    }
  }
}

class _SideNav extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const _SideNav({
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          const AppLogo(size: 48),
          const SizedBox(height: 24),
          // Divider
          Container(
            width: 40,
            height: 1,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          // Nav Items
          Expanded(
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'POS',
                  page: AppPage.pos,
                  isSelected: currentPage == AppPage.pos,
                  onTap: () => onPageSelected(AppPage.pos),
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Students',
                  page: AppPage.students,
                  isSelected: currentPage == AppPage.students,
                  onTap: () => onPageSelected(AppPage.students),
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  page: AppPage.inventory,
                  isSelected: currentPage == AppPage.inventory,
                  onTap: () => onPageSelected(AppPage.inventory),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Expenses',
                  page: AppPage.expenses,
                  isSelected: currentPage == AppPage.expenses,
                  onTap: () => onPageSelected(AppPage.expenses),
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  page: AppPage.analytics,
                  isSelected: currentPage == AppPage.analytics,
                  onTap: () => onPageSelected(AppPage.analytics),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppPage page;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
