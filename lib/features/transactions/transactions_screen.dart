import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_providers.dart';
import '../pos/widgets/receipt_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              Text('Transactions',
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search receipt or student...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── List ───
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final query = _searchQuery.toLowerCase();
                final filtered = transactions.where((t) {
                  final matchReceipt =
                      t.receiptId.toLowerCase().contains(query);
                  final matchName =
                      t.studentName?.toLowerCase().contains(query) ?? false;
                  final matchId =
                      t.studentId?.toLowerCase().contains(query) ?? false;
                  return matchReceipt || matchName || matchId;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No transactions found',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _TransactionCard(
                        transaction: filtered[index], isDark: isDark);
                  },
                );
              },
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: cs.primary, strokeWidth: 2.5)),
              error: (err, _) => Center(
                  child: Text('Error: $err',
                      style: TextStyle(color: pos.error))),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final StoreTransaction transaction;
  final bool isDark;

  const _TransactionCard({required this.transaction, required this.isDark});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final txn = widget.transaction;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        showDialog(
          context: context,
          builder: (context) => ReceiptDialog(
            receiptId: txn.receiptId,
            items: txn.items,
            totalAmount: txn.totalAmount,
            paymentMode: txn.paymentMode,
            walletDeducted: txn.paidAmount -
                (txn.paymentMode == 'cash' ? txn.paidAmount : 0),
            cashAmount: txn.paymentMode == 'cash' ||
                    txn.paymentMode == 'mixed'
                ? txn.paidAmount
                : 0,
            debtAmount: txn.debtAmount,
            studentName: txn.studentName,
            transaction: txn,
          ),
        );
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: txn.isVoided
                ? pos.error.withValues(alpha: 0.04)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: widget.isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.06), width: 0.5)
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (txn.isVoided ? pos.error : cs.primary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  txn.isVoided
                      ? Icons.cancel_rounded
                      : Icons.receipt_long_rounded,
                  size: 20,
                  color: txn.isVoided ? pos.error : cs.primary,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(txn.receiptId,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        if (txn.isVoided) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: pos.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('CANCELLED',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: pos.error,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatDateTime(txn.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    if (txn.studentName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(txn.studentName!,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Payment Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(txn.totalAmount),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: txn.isVoided ? pos.error : cs.onSurface,
                      decoration: txn.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pos.fill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      txn.paymentMode.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
