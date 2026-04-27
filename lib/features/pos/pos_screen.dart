import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/search_field.dart';
import '../../core/constants/store_section.dart';
import '../../core/theme/pos_colors.dart';
import '../../providers/product_providers.dart';
import '../../providers/multi_cart_provider.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    final searchRow = Row(
      children: [
        Expanded(
          child: SearchField(
            hintText: 'Search Products',
            onChanged: (val) {
              ref.read(productSearchQueryProvider.notifier).state = val;
            },
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: cs.onSurfaceVariant,
            tooltip: 'Refresh Products',
            onPressed: () {
              ref.invalidate(productsStreamProvider);
            },
          ),
        ),
        const SizedBox(width: 12),
        Consumer(builder: (context, ref, child) {
          final isListView = ref.watch(isProductListViewProvider);
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: Icon(
                  isListView
                      ? Icons.grid_view_rounded
                      : Icons.list_alt_rounded,
                  size: 22),
              color: cs.onSurfaceVariant,
              tooltip: isListView ? 'Grid View' : 'List View',
              onPressed: () {
                ref.read(isProductListViewProvider.notifier).state =
                    !isListView;
              },
            ),
          );
        }),
      ],
    );

    // ─── Phone Layout: Portrait-first product browsing ───
    if (isPhone) {
      return Stack(
        children: [
          Padding(
            // Extra bottom padding for the bottom tab bar + cart button
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact page title for phone
                Text(
                  'Point of Sale',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                searchRow,
                const SizedBox(height: 12),
                const _PosSectionFilterRow(),
                const SizedBox(height: 12),
                const CategoryTabs(),
                const SizedBox(height: 12),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
          // Floating cart button
          Positioned(
            left: 16,
            right: 16,
            bottom: 88, // above bottom tab bar
            child: _MobileCartButton(),
          ),
        ],
      );
    }

    // ─── Tablet & Desktop: Side-by-side layout ───
    final isTablet = Responsive.isTablet(context);
    // For 10" tablet (~800px minus sidebar ~150px = ~650px usable),
    // give cart 45% flex for generous space

    return Row(
      children: [
        // ─── Left: Product browsing + Customer Tabs ───
        Expanded(
          flex: isTablet ? 55 : 65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Customer Session Tabs (moved here from cart) ───
                _CustomerSessionBar(),

                const SizedBox(height: 12),

                searchRow,
                const SizedBox(height: 12),
                const _PosSectionFilterRow(),
                const SizedBox(height: 12),
                const CategoryTabs(),
                const SizedBox(height: 12),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
        ),
        // ─── Right: Cart Panel ───
        Expanded(
          flex: isTablet ? 45 : 35,
          child: const CartPanel(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CUSTOMER SESSION TAB BAR — in the product area
// ═══════════════════════════════════════════════════════════════

class _CustomerSessionBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiCart = ref.watch(multiCartProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurfaceVariant.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Scrollable tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              itemCount: multiCart.sessions.length,
              itemBuilder: (context, index) {
                final session = multiCart.sessions[index];
                final isActive = session.id == multiCart.activeSessionId;
                return _SessionTab(
                  session: session,
                  isActive: isActive,
                  showClose:
                      multiCart.sessions.length > 1 || session.items.isNotEmpty,
                  onTap: () {
                    ref
                        .read(multiCartProvider.notifier)
                        .switchSession(session.id);
                  },
                  onClose: () {
                    _confirmRemoveSession(context, ref, session);
                  },
                );
              },
            ),
          ),
          // Add new session button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                ref.read(multiCartProvider.notifier).addSession();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveSession(
      BuildContext context, WidgetRef ref, CartSession session) {
    if (session.items.isEmpty) {
      ref.read(multiCartProvider.notifier).removeSession(session.id);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Close ${session.label}?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            'This will remove ${session.itemCount} item(s) from the cart.',
            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(multiCartProvider.notifier)
                    .removeSession(session.id);
              },
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              child: Text('Close',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Individual Session Tab ───

class _SessionTab extends StatefulWidget {
  final CartSession session;
  final bool isActive;
  final bool showClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SessionTab({
    required this.session,
    required this.isActive,
    required this.showClose,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_SessionTab> createState() => _SessionTabState();
}

class _SessionTabState extends State<_SessionTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasItems = widget.session.items.isNotEmpty;
    final hasStudent = widget.session.linkedStudent != null;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? cs.surface
                  : _isHovered
                      ? cs.onSurfaceVariant.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Student avatar or customer icon
                if (hasStudent)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.session.linkedStudent!.name.isNotEmpty
                            ? widget.session.linkedStudent!.name[0]
                                .toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: widget.isActive
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                const SizedBox(width: 8),
                // Label
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    widget.session.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isActive
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Item count badge
                if (hasItems) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.session.itemCount}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isActive
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                // Close button
                if (widget.showClose) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isHovered || widget.isActive
                            ? cs.onSurfaceVariant.withValues(alpha: 0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCartButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeSession = ref.watch(multiCartProvider).activeSession;
    final count = activeSession.itemCount;
    final total = activeSession.total;

    if (count == 0) return const SizedBox.shrink();

    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: cs.primary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Cart & Checkout',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: const CartPanel(),
              ),
              fullscreenDialog: true,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'View Cart',
                    style: GoogleFonts.inter(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  POS LOCAL SECTION FILTER — All | Cafe | Store
// ───────────────────────────────────────────────────────────────

class _PosSectionFilterRow extends ConsumerWidget {
  const _PosSectionFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(posSectionFilterProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    const options = [StoreSection.all, StoreSection.cafe, StoreSection.store];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((section) {
          final isSelected = section == current;

          Color activeColor;
          switch (section) {
            case StoreSection.cafe:
              activeColor = pos.info;
              break;
            case StoreSection.store:
              activeColor = pos.success;
              break;
            default:
              activeColor = cs.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(posSectionFilterProvider.notifier).state = section;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : activeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : activeColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      section.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      section.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
