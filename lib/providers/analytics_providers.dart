import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import 'external_debtor_providers.dart';
import 'supplier_providers.dart';

enum AnalyticsDateFilter {
  today,
  thisMonth,
  thisYear,
  allTime,
  custom,
}

// ─── Selected Filter ───
final analyticsDateFilterProvider = StateProvider<AnalyticsDateFilter>((ref) => AnalyticsDateFilter.today);

// ─── Custom Date Range ───
final analyticsCustomDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// ─── Resolved Date Range Helper ───
/// Returns null for 'allTime' or if custom is empty.
final analyticsResolvedDateRangeProvider = Provider<DateTimeRange?>((ref) {
  final filter = ref.watch(analyticsDateFilterProvider);
  final customRange = ref.watch(analyticsCustomDateRangeProvider);
  final now = DateTime.now();

  switch (filter) {
    case AnalyticsDateFilter.today:
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      return DateTimeRange(start: start, end: end);
    case AnalyticsDateFilter.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(start: start, end: end);
    case AnalyticsDateFilter.thisYear:
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year + 1, 1, 1);
      return DateTimeRange(start: start, end: end);
    case AnalyticsDateFilter.custom:
      return customRange;
    case AnalyticsDateFilter.allTime:
      return null;
  }
});

// ─── Total Outstanding Debt Helper ───
final totalOverallDebtProvider = Provider<double>((ref) {
  final studentDebt = ref.watch(studentsStreamProvider).valueOrNull
      ?.fold<double>(0, (sum, s) => sum + s.debt) ?? 0;
  final externalDebt = ref.watch(externalDebtorsStreamProvider).valueOrNull
      ?.fold<double>(0, (sum, e) => sum + e.debt) ?? 0;
  return studentDebt + externalDebt;
});

// ─── Total Supplier Payables Helper ───
final totalSupplierPayablesProvider = Provider<double>((ref) {
  final suppliers = ref.watch(suppliersStreamProvider).valueOrNull ?? [];
  return suppliers.fold<double>(0, (sum, s) => sum + s.balance);
});
