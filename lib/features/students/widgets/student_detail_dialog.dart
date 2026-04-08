import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class StudentDetailDialog extends ConsumerStatefulWidget {
  final Student student;

  const StudentDetailDialog({super.key, required this.student});

  @override
  ConsumerState<StudentDetailDialog> createState() => _StudentDetailDialogState();
}

class _StudentDetailDialogState extends ConsumerState<StudentDetailDialog> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Left Side: Student Info ───
            Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Circular avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.student.name.isNotEmpty
                            ? widget.student.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Edit
                  if (_isEditingName)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Student Name',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.check_rounded,
                              color: pos.success, size: 20),
                          onPressed: () async {
                            final newName = _nameController.text.trim();
                            if (newName.isNotEmpty &&
                                newName != widget.student.name) {
                              await StudentRepository()
                                  .updateStudent(widget.student.id, {'name': newName});
                              await AuditRepository().log(
                                action: AppConstants.auditEdit,
                                description:
                                    'Renamed student ${widget.student.id} to $newName',
                              );
                            }
                            setState(() => _isEditingName = false);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: pos.error, size: 20),
                          onPressed: () =>
                              setState(() => _isEditingName = false),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.student.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isEditingName = true),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_rounded,
                                size: 14, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),
                  Text('ID: ${widget.student.id}',
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 32),

                  // Balances — borderless
                  _StatBox(
                    label: 'Wallet Balance',
                    value: CurrencyFormatter.format(widget.student.balance),
                    color: pos.info,
                  ),
                  const SizedBox(height: 12),
                  _StatBox(
                    label: 'Pending Debt',
                    value: CurrencyFormatter.format(widget.student.debt),
                    color: pos.error,
                  ),

                  const Spacer(),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: pos.error),
                      label: Text('Delete Student',
                          style: GoogleFonts.inter(
                              color: pos.error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pos.error,
                        side: BorderSide(color: pos.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Right Side: Purchase History ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Purchase History',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: StreamBuilder(
                        stream: TransactionRepository()
                            .getStudentTransactions(widget.student.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}',
                                    style: GoogleFonts.inter(
                                        color: pos.error)));
                          }
                          if (!snapshot.hasData) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: cs.primary, strokeWidth: 2.5));
                          }

                          final txns = snapshot.data!;
                          if (txns.isEmpty) {
                            return Center(
                              child: Text('No purchase history',
                                  style: GoogleFonts.inter(
                                      color: cs.onSurfaceVariant)),
                            );
                          }

                          return ListView.separated(
                            itemCount: txns.length,
                            separatorBuilder: (_, __) => Divider(
                                height: 1, color: pos.divider),
                            itemBuilder: (context, index) {
                              final txn = txns[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: (txn.isVoided
                                                ? pos.error
                                                : cs.primary)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        txn.isVoided
                                            ? Icons.cancel_rounded
                                            : Icons.receipt_long_rounded,
                                        size: 18,
                                        color: txn.isVoided
                                            ? pos.error
                                            : cs.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(txn.receiptId,
                                                  style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13)),
                                              if (txn.isVoided) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: pos.error
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(999),
                                                  ),
                                                  child: Text('VOID',
                                                      style:
                                                          GoogleFonts.inter(
                                                              color: pos
                                                                  .error,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormatter.formatDateTime(
                                                txn.createdAt),
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(
                                              txn.totalAmount),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: txn.isVoided
                                                ? pos.error
                                                : cs.onSurface,
                                            decoration: txn.isVoided
                                                ? TextDecoration
                                                    .lineThrough
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          txn.paymentMode.toUpperCase(),
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Student?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete ${widget.student.name}? This action cannot be undone.',
            style: GoogleFonts.inter(
                fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StudentRepository().deleteStudent(widget.student.id);
              await AuditRepository().log(
                action: AppConstants.auditEdit,
                description:
                    'Deleted student: ${widget.student.name} (${widget.student.id})',
              );
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pos.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        // No border — Apple style
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w700, fontSize: 24)),
        ],
      ),
    );
  }
}
