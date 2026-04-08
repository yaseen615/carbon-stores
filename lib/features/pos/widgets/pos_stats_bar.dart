import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/transaction_providers.dart';
import '../../../providers/product_providers.dart';

class PosStatsBar extends ConsumerWidget {
  const PosStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySales = ref.watch(todaySalesProvider);
    final todayTxCount = ref.watch(todayTransactionCountProvider);
    // Since "Items Sold" isn't explicitly single-tracked, we show "Low Stock" instead, or just keep it simple.
    // Let's proxy items sold with stock alerts as logic hasn't changed.
    final lowStockCount = ref.watch(lowStockProductsProvider).length;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Level 1 soft shadow
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Sales",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(todaySales),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Orders",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$todayTxCount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Low Stock",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$lowStockCount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
