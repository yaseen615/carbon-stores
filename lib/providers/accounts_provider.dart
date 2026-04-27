import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import 'transaction_providers.dart';
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

final accountsTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final filter = ref.watch(accountsDateFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final section = ref.watch(storeSectionProvider);

  Stream<List<StoreTransaction>> stream;

  switch (filter) {
    case AccountsDateFilter.today:
      stream = repo.getTransactionsByDate(DateTime.now());
      break;
    case AccountsDateFilter.thisWeek:
      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = now.add(Duration(days: 7 - now.weekday));
      stream = repo.getTransactionsByDateRange(
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day, 23, 59, 59),
      );
      break;
    case AccountsDateFilter.thisMonth:
      final now = DateTime.now();
      stream = repo.getTransactionsByMonth(now.year, now.month);
      break;
    case AccountsDateFilter.allTime:
      stream = repo.getTransactions();
      break;
    case AccountsDateFilter.custom:
      final customRange = ref.watch(accountsCustomDateRangeProvider);
      if (customRange != null) {
        stream = repo.getTransactionsByDateRange(
          customRange.start,
          DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59),
        );
      } else {
        stream = Stream.value([]);
      }
      break;
  }

  if (section == StoreSection.all) return stream;
  // combined transactions appear in BOTH cafe and store filters
  return stream.map((list) => list.where((t) {
    if (t.section == 'combined') return true;
    return t.section == section.firestoreValue;
  }).toList());
});

final accountsSummaryProvider = Provider<AccountsSummary>((ref) {
  final txnsAsync = ref.watch(accountsTransactionsProvider);

  return txnsAsync.maybeWhen(
    data: (txns) {
      double cash = 0;
      double upi = 0;
      double wallet = 0;
      double debt = 0;

      for (var t in txns) {
        if (t.isVoided) continue;
        cash += t.cashAmount;
        upi += t.upiAmount;
        wallet += t.walletAmount;
        debt += t.debtAmount;
      }

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
