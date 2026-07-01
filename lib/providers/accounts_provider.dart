import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/models/supplier_payment_model.dart';
import 'transaction_providers.dart';
import 'supplier_providers.dart';
import '../core/constants/store_section.dart';
import 'store_section_provider.dart';

enum AccountsDateFilter { today, thisWeek, thisMonth, allTime, custom }

final accountsDateFilterProvider = StateProvider<AccountsDateFilter>((ref) => AccountsDateFilter.today);
final accountsCustomDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

class AccountsSummary {
  final double totalCash;
  final double totalUpi;
  final double totalWallet;
  final double totalDebt; // newly accumulated debt

  AccountsSummary({
    this.totalCash = 0,
    this.totalUpi = 0,
    this.totalWallet = 0,
    this.totalDebt = 0,
  });

  double get totalRevenue => totalCash + totalUpi + totalWallet; // not including debt as revenue initially, or maybe just totalCash + totalUpi 
  double get totalReceived => totalCash + totalUpi; // actual money received
}

final _accountsDateRangeProvider = Provider<DateTimeRange?>((ref) {
  final filter = ref.watch(accountsDateFilterProvider);
  
  switch (filter) {
    case AccountsDateFilter.today:
      final now = DateTime.now();
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case AccountsDateFilter.thisWeek:
      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = now.add(Duration(days: 7 - now.weekday));
      return DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day, 23, 59, 59),
      );
    case AccountsDateFilter.thisMonth:
      final now = DateTime.now();
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59), // end of month
      );
    case AccountsDateFilter.allTime:
      return null;
    case AccountsDateFilter.custom:
      final customRange = ref.watch(accountsCustomDateRangeProvider);
      if (customRange != null) {
        return DateTimeRange(
          start: customRange.start,
          end: DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59),
        );
      }
      return null;
  }
});

final accountsTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final filter = ref.watch(accountsDateFilterProvider);
  final range = ref.watch(_accountsDateRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final section = ref.watch(storeSectionProvider);

  Stream<List<StoreTransaction>> stream;

  if (filter == AccountsDateFilter.allTime) {
    stream = repo.getTransactions();
  } else if (filter == AccountsDateFilter.custom && range == null) {
    stream = Stream.value([]);
  } else if (range != null) {
    stream = repo.getTransactionsByDateRange(range.start, range.end);
  } else {
    stream = Stream.value([]);
  }

  if (section == StoreSection.all) return stream;
  // combined transactions appear in BOTH cafe and store filters
  return stream.map((list) => list.where((t) {
    if (t.section == 'combined') return true;
    return t.section == section.firestoreValue;
  }).toList());
});

final accountsSupplierPaymentsProvider = StreamProvider<List<SupplierPayment>>((ref) {
  final filter = ref.watch(accountsDateFilterProvider);
  final range = ref.watch(_accountsDateRangeProvider);
  final repo = ref.watch(supplierPaymentRepositoryProvider);
  
  if (filter == AccountsDateFilter.allTime) {
    return repo.getPaymentsByDateRange(DateTime(2000), DateTime(2100));
  } else if (filter == AccountsDateFilter.custom && range == null) {
    return Stream.value([]);
  } else if (range != null) {
    return repo.getPaymentsByDateRange(range.start, range.end);
  } else {
    return Stream.value([]);
  }
});

final accountsSummaryProvider = Provider<AccountsSummary>((ref) {
  final txnsAsync = ref.watch(accountsTransactionsProvider);
  final paymentsAsync = ref.watch(accountsSupplierPaymentsProvider);

  return txnsAsync.maybeWhen(
    data: (txns) {
      double cash = 0;
      double upi = 0;
      double wallet = 0;
      double debt = 0;

      // Add incoming revenue from sales
      for (var t in txns) {
        if (t.isVoided) continue;
        cash += t.cashAmount;
        upi += t.upiAmount;
        wallet += t.walletAmount;
        debt += t.debtAmount;
      }

      // Subtract outbound supplier payments
      paymentsAsync.whenData((payments) {
        for (var p in payments) {
          if (p.paymentMode == 'cash') {
            cash -= p.amount;
          } else if (p.paymentMode == 'upi' || p.paymentMode == 'bank_transfer') {
            upi -= p.amount;
          } else if (p.paymentMode == 'wallet') {
            wallet -= p.amount;
          }
        }
      });

      return AccountsSummary(
        totalCash: cash,
        totalUpi: upi,
        totalWallet: wallet,
        totalDebt: debt,
      );
    },
    orElse: () => AccountsSummary(),
  );
});
