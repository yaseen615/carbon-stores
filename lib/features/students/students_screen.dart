import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/search_field.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/student_providers.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final filtered = ref.watch(filteredStudentsProvider);
    final totalBalance = ref.watch(totalWalletBalanceProvider);
    final totalDebt = ref.watch(totalDebtProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              Text(
                'Students',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
              const Spacer(),
              // Stats
              _StatChip(
                label: 'Total Balance',
                value: CurrencyFormatter.formatCompact(totalBalance),
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Total Debt',
                value: CurrencyFormatter.formatCompact(totalDebt),
                color: AppColors.error,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Student'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          SizedBox(
            width: 320,
            child: SearchField(
              hintText: 'Search by name or ID...',
              onChanged: (query) {
                ref.read(studentSearchQueryProvider.notifier).state = query;
              },
            ),
          ),
          const SizedBox(height: 16),

          // ─── Students Grid ───
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(
                child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('No students found',
                            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _StudentCard(student: filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Student', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Admission Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Balance (₹)'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (idController.text.isEmpty || nameController.text.isEmpty) return;
                      final student = Student(
                        id: idController.text.trim(),
                        name: nameController.text.trim(),
                        balance: double.tryParse(balanceController.text) ?? 0,
                        debt: 0,
                        updatedAt: DateTime.now(),
                      );
                      try {
                        await StudentRepository().addStudent(student);
                        await AuditRepository().log(
                          action: AppConstants.auditEdit,
                          description: 'Added student: ${student.name} (${student.id})',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Add Student'),
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

class _StudentCard extends StatelessWidget {
  final Student student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${student.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Balance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      CurrencyFormatter.formatCompact(student.balance),
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (student.hasDebt) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${CurrencyFormatter.formatCompact(student.debt)}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Recharge button
                  SizedBox(
                    height: 30,
                    child: TextButton.icon(
                      onPressed: () => _showRechargeDialog(context, student),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Recharge', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
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

  void _showRechargeDialog(BuildContext context, Student student) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recharge Wallet', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${student.name} (${student.id})',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Current Balance: ',
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    Text(CurrencyFormatter.format(student.balance),
                        style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                if (student.hasDebt) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Current Debt: ',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      Text(CurrencyFormatter.format(student.debt),
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Debt will be automatically cleared from recharge amount',
                            style: TextStyle(color: AppColors.warning, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Recharge Amount (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;

                      await StudentRepository().rechargeWallet(student.id, amount);
                      await AuditRepository().log(
                        action: AppConstants.auditRecharge,
                        description: 'Recharged ${student.name}: ${CurrencyFormatter.format(amount)}',
                        metadata: {'student_id': student.id, 'amount': amount},
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Recharge'),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
