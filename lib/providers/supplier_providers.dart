import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/supplier_model.dart';
import '../data/models/supplier_payment_model.dart';
import '../data/repositories/supplier_repository.dart';
import '../data/repositories/supplier_payment_repository.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';

// ─── Repositories ───
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

final supplierPaymentRepositoryProvider = Provider<SupplierPaymentRepository>((ref) {
  return SupplierPaymentRepository();
});

// ─── Streams ───
final suppliersStreamProvider = StreamProvider<List<Supplier>>((ref) {
  return ref.watch(supplierRepositoryProvider).getSuppliers();
});

final supplierStreamProvider = StreamProvider.family<Supplier?, String>((ref, id) {
  return ref.watch(supplierRepositoryProvider).getSupplierStream(id);
});

final supplierExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, supplierId) {
  return ExpenseRepository().getExpensesBySupplier(supplierId);
});

final supplierPaymentsProvider = StreamProvider.family<List<SupplierPayment>, String>((ref, supplierId) {
  return ref.watch(supplierPaymentRepositoryProvider).getPaymentsForSupplier(supplierId);
});
