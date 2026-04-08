import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/pos_colors.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/audit_repository.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final AuditRepository _repo = AuditRepository();

  @override
  Widget build(BuildContext context) {
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
              Text('Audit Logs',
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Filter'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Logs Stream ───
          Expanded(
            child: StreamBuilder<List<AuditLog>>(
              stream: _repo.getRecentLogs(limit: 100),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: pos.error)));
                }
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: cs.primary, strokeWidth: 2.5));
                }

                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No audit logs found',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _AuditLogTile(
                        log: logs[index], isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;
  final bool isDark;

  const _AuditLogTile({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    IconData icon;
    Color color;

    switch (log.action) {
      case 'sale':
        icon = Icons.shopping_cart_checkout_rounded;
        color = pos.success;
        break;
      case 'recharge':
        icon = Icons.account_balance_wallet_rounded;
        color = pos.success;
        break;
      case 'edit':
        icon = Icons.edit_note_rounded;
        color = pos.warning;
        break;
      case 'stock_in':
        icon = Icons.add_box_rounded;
        color = cs.primary;
        break;
      case 'expense':
        icon = Icons.receipt_long_rounded;
        color = pos.error;
        break;
      case 'void':
        icon = Icons.cancel_rounded;
        color = pos.error;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = pos.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        (log.action == 'void'
                                ? 'CANCEL PURCHASE'
                                : log.action)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      DateFormatter.formatDateTime(log.timestamp),
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(log.description,
                    style: GoogleFonts.inter(
                        color: cs.onSurface, fontSize: 14)),
                if (log.userId != null) ...[
                  const SizedBox(height: 4),
                  Text('User: ${log.userId}',
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
