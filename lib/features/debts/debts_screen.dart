import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/debts_repository.dart';
import '../../../providers/student_providers.dart';
import '../../../providers/external_debtor_providers.dart';
import '../../../core/utils/exporter/csv_exporter_stub.dart'
    if (dart.library.html) '../../../core/utils/exporter/csv_exporter_web.dart'
    if (dart.library.io) '../../../core/utils/exporter/csv_exporter_mobile.dart';
import 'package:intl/intl.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final studentsAsync = ref.watch(studentsStreamProvider);
    final externalsAsync = ref.watch(externalDebtorsStreamProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Debt Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Debt Report',
            onPressed: () => _exportDebtReport(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search debtors...',
                hintStyle: GoogleFonts.inter(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18, color: cs.onSurfaceVariant),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.inter(fontSize: 15),
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                return externalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (externals) {
                    var studentDebtors = students.where((s) => s.debt > 0).toList();
                    var externalDebtors = externals.where((e) => e.debt > 0).toList();

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      studentDebtors = studentDebtors.where((s) =>
                          s.name.toLowerCase().contains(_searchQuery) ||
                          s.id.toLowerCase().contains(_searchQuery)).toList();
                      externalDebtors = externalDebtors.where((e) =>
                          e.name.toLowerCase().contains(_searchQuery)).toList();
                    }

                    // Calculate total debt
                    final totalStudentDebt = studentDebtors.fold(0.0, (sum, s) => sum + s.debt);
                    final totalExternalDebt = externalDebtors.fold(0.0, (sum, e) => sum + e.debt);
                    final totalDebt = totalStudentDebt + totalExternalDebt;

                    if (studentDebtors.isEmpty && externalDebtors.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 56, color: pos.success.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'No matching debtors found' : 'No outstanding debts!',
                              style: GoogleFonts.inter(
                                  fontSize: 16, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        // Total Debt Summary
                        AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Outstanding',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, color: cs.onSurfaceVariant)),
                                Text(
                                  CurrencyFormatter.format(totalDebt),
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: pos.error,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (studentDebtors.isNotEmpty) ...[
                          Text(
                            'Students (${studentDebtors.length})',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...studentDebtors.map((s) => _DebtorCard(
                                personId: s.id,
                                personName: s.name,
                                debtAmount: s.debt,
                                isStudent: true,
                              )),
                          const SizedBox(height: 24),
                        ],
                        if (externalDebtors.isNotEmpty) ...[
                          Text(
                            'Other Debtors (${externalDebtors.length})',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...externalDebtors.map((e) => _DebtorCard(
                                personId: e.id,
                                personName: e.name,
                                debtAmount: e.debt,
                                isStudent: false,
                              )),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDebtReport(BuildContext context, WidgetRef ref) async {
    try {
      final students = ref.read(studentsStreamProvider).valueOrNull ?? [];
      final externals = ref.read(externalDebtorsStreamProvider).valueOrNull ?? [];

      final studentDebtors = students.where((s) => s.debt > 0).toList();
      final externalDebtors = externals.where((e) => e.debt > 0).toList();
      
      final buffer = StringBuffer();
      buffer.writeln('Type,ID,Name,Debt Amount');
      
      for (final s in studentDebtors) {
        buffer.writeln('Student,${s.id},${s.name},${s.debt}');
      }
      for (final e in externalDebtors) {
        buffer.writeln('Other,${e.id},${e.name},${e.debt}');
      }

      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      await saveAndShareFile('Debt_Report_$dateStr.csv', buffer.toString());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt report exported successfully!')),
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
}

class _DebtorCard extends StatelessWidget {
  final String personId;
  final String personName;
  final double debtAmount;
  final bool isStudent;

  const _DebtorCard({
    required this.personId,
    required this.personName,
    required this.debtAmount,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isStudent ? cs.primary.withValues(alpha: 0.1) : pos.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStudent ? Icons.school_rounded : Icons.person_rounded,
                  color: isStudent ? cs.primary : pos.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isStudent ? 'ID: $personId' : 'External Debtor',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(debtAmount),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: pos.error,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showClearDebtDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pos.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Clear Debt',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
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

  void _showClearDebtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ClearDebtDialog(
        personId: personId,
        personName: personName,
        currentDebt: debtAmount,
        isStudent: isStudent,
      ),
    );
  }
}

class _ClearDebtDialog extends StatefulWidget {
  final String personId;
  final String personName;
  final double currentDebt;
  final bool isStudent;

  const _ClearDebtDialog({
    required this.personId,
    required this.personName,
    required this.currentDebt,
    required this.isStudent,
  });

  @override
  State<_ClearDebtDialog> createState() => _ClearDebtDialogState();
}

class _ClearDebtDialogState extends State<_ClearDebtDialog> {
  final _amountController = TextEditingController();
  String _paymentMode = 'cash';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.currentDebt.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > widget.currentDebt) {
      setState(() => _error = 'Amount cannot exceed current debt');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await DebtsRepository().clearDebt(
        isStudent: widget.isStudent,
        personId: widget.personId,
        personName: widget.personName,
        amountCleared: amount,
        paymentMode: _paymentMode,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debt cleared successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear Debt for ${widget.personName}',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Current Debt: ${CurrencyFormatter.format(widget.currentDebt)}',
                style: GoogleFonts.inter(fontSize: 14, color: pos.error),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount to Clear',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Mode',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'cash',
                      // ignore: deprecated_member_use
                      groupValue: _paymentMode,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setState(() => _paymentMode = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('UPI'),
                      value: 'upi',
                      // ignore: deprecated_member_use
                      groupValue: _paymentMode,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setState(() => _paymentMode = val!),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: GoogleFonts.inter(color: pos.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pos.success,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirm'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
