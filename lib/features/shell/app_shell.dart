import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../pos/pos_screen.dart';
import '../students/students_screen.dart';
import '../inventory/inventory_screen.dart';
import '../expenses/expenses_screen.dart';
import '../analytics/analytics_screen.dart';
import '../transactions/transactions_screen.dart';
import '../audit/audit_screen.dart';
import '../pos/widgets/pos_stats_bar.dart';
import '../../core/utils/exporter/csv_exporter_stub.dart'
    if (dart.library.html) '../../core/utils/exporter/csv_exporter_web.dart'
    if (dart.library.io) '../../core/utils/exporter/csv_exporter_mobile.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);

    return Scaffold(
      body: Row(
        children: [
          // ─── Sidebar Navigation ───
          _SideNav(
            currentPage: currentPage,
            onPageSelected: (page) {
              ref.read(currentPageProvider.notifier).state = page;
            },
          ),

          // ─── Page Content ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                // Fade + subtle vertical slide
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
      case AppPage.transactions:
        return const TransactionsScreen(key: ValueKey('transactions'));
      case AppPage.auditLog:
        return const AuditScreen(key: ValueKey('auditLog'));
    }
  }
}

class _SideNav extends ConsumerWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const _SideNav({
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
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
          // Large Title "Home"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Home',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // PosStatsBar integrated directly into sidebar
          if (currentPage == AppPage.pos) const PosStatsBar(),
          
          if (currentPage != AppPage.pos) const SizedBox(height: 24),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sales', // Match "Sales" from mockup instead of POS
                  isSelected: currentPage == AppPage.pos,
                  onTap: () => onPageSelected(AppPage.pos),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products', // Match "Products" from mockup
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
          // Settings
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? cs.onSurfaceVariant.withValues(alpha: 0.12) // Mockup has grey active background, not blue
                  : _isHovered
                      ? cs.onSurfaceVariant.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isSelected
                      ? cs.onSurface
                      : _isHovered
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected
                          ? cs.onSurface
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

/// Settings modal content — uses AppModalContent for consistent look.
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
                      ? const Color(0xFFFFD60A) // Apple yellow
                      : const Color(0xFFFF9500), // Apple orange
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

        // ─── Export All Data ───
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _exportAllData(context, ref),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pos.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_download_rounded, size: 22, color: cs.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Database',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Download DB as JSON',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── Export Images ───
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _exportImages(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pos.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 22, color: pos.info),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Images Backup',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Download images as ZIP',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),

        // ─── Import Images ───
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _importImages(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pos.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file_rounded, size: 22, color: pos.success),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Images Backup',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Restore images from ZIP',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // App version
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
        'products': products.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'students': students.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'transactions': transactions.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'expenses': expenses.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        'audit_logs': auditLogs.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final timestamp = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      await saveAndShareFile('CG_Store_Backup_$timestamp.json', jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Full backup exported successfully!')),
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
            const SnackBar(content: Text('Export cancelled or not supported for native web.')),
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
    Navigator.pop(context);
    try {
      final count = await LocalStorageService().importBackup();
      if (context.mounted) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully restored $count images.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images imported.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
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
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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
