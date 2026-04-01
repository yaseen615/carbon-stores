import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/expense_model.dart';
import 'exporter/csv_exporter_stub.dart'
    if (dart.library.html) 'exporter/csv_exporter_web.dart'
    if (dart.library.io) 'exporter/csv_exporter_mobile.dart';

class CsvExporter {
  CsvExporter._();

  /// Generate CSV from headers and rows, and save/share
  static Future<void> exportCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final csvData = [headers, ...rows];
    final csvString = const ListToCsvConverter().convert(csvData);

    final timestamp = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
    final fullFileName = '${fileName}_$timestamp.csv';

    await saveAndShareFile(fullFileName, csvString);
  }

  /// Export sales report
  static Future<void> exportSalesReport(List<StoreTransaction> transactions) async {
    final headers = ['Receipt ID', 'Date', 'Time', 'Items Summary', 'Payment Mode', 'Paid Amount', 'Debt Added', 'Student ID', 'Total Amount'];
    
    double totalPaid = 0;
    double totalDebt = 0;

    final rows = transactions.map((t) {
      final date = t.createdAt;
      final paid = t.paidAmount;
      final debt = t.debtAmount;
      totalPaid += paid;
      totalDebt += debt;

      return [
        t.receiptId,
        DateFormat('yyyy-MM-dd').format(date),
        DateFormat('HH:mm').format(date),
        t.itemsSummary,
        t.paymentMode.toUpperCase(),
        paid.toStringAsFixed(2),
        debt.toStringAsFixed(2),
        t.studentId ?? 'N/A',
        t.totalAmount.toStringAsFixed(2),
      ];
    }).toList();

    // Summary Rows
    rows.add([]); // empty row
    rows.add(['', '', '', '', 'TOTAL PAID:', totalPaid.toStringAsFixed(2), '', '', '']);
    rows.add(['', '', '', '', 'TOTAL DEBT ADDED:', totalDebt.toStringAsFixed(2), '', '', '']);

    await exportCsv(fileName: 'Sales_Report', headers: headers, rows: rows);
  }

  /// Export inventory report
  static Future<void> exportInventoryReport(List<Product> products) async {
    final headers = ['Product Name', 'Category', 'Price', 'Current Stock', 'Stock Status'];
    final rows = products.map((p) => [
      p.name,
      p.category,
      p.price.toStringAsFixed(2),
      p.stock,
      p.isOutOfStock ? 'Out of Stock' : p.isLowStock ? 'Low Stock' : 'In Stock',
    ]).toList();
    
    await exportCsv(fileName: 'Inventory_Report', headers: headers, rows: rows);
  }

  /// Export student report
  static Future<void> exportStudentReport(List<Student> students) async {
    final headers = ['Admission No', 'Student Name', 'Wallet Balance', 'Pending Debt'];
    
    double totalBalance = 0;
    double totalDebt = 0;

    final rows = students.map((s) {
      final balance = s.balance;
      final debt = s.debt;
      totalBalance += balance;
      totalDebt += debt;

      return [
        s.id,
        s.name,
        balance.toStringAsFixed(2),
        debt.toStringAsFixed(2),
      ];
    }).toList();

    // Summary Rows
    rows.add([]); // empty row
    rows.add(['', 'TOTAL:', totalBalance.toStringAsFixed(2), totalDebt.toStringAsFixed(2)]);

    await exportCsv(fileName: 'Student_Report', headers: headers, rows: rows);
  }

  /// Export Expense report
  static Future<void> exportExpenseReport(List<Expense> expenses) async {
    final headers = ['Date', 'Product Name', 'Qty', 'Unit Cost', 'Total Cost'];
    
    double total = 0;

    final rows = expenses.map((e) {
      total += e.totalCost;
      return [
        DateFormat('yyyy-MM-dd').format(e.date),
        e.productName,
        e.quantity,
        e.cost.toStringAsFixed(2),
        e.totalCost.toStringAsFixed(2),
      ];
    }).toList();

    rows.add([]);
    rows.add(['', '', '', '', '', 'TOTAL:', total.toStringAsFixed(2)]);

    await exportCsv(fileName: 'Expense_Report', headers: headers, rows: rows);
  }

  /// Export Profit & Loss report
  static Future<void> exportPandLReport(List<StoreTransaction> transactions, List<Expense> expenses) async {
    // Grouping by Month (Year-Month key)
    final monthlyData = <String, Map<String, dynamic>>{};
    
    double totalRevenue = 0;
    double totalExpensesValue = 0;
    int totalTxns = transactions.length;

    // Process Transactions
    for (final t in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.createdAt);
      monthlyData.putIfAbsent(monthKey, () => {'rev': 0.0, 'exp': 0.0, 'txns': 0, 'total': 0.0});
      monthlyData[monthKey]!['rev'] += t.paidAmount;
      monthlyData[monthKey]!['txns'] += 1;
      monthlyData[monthKey]!['total'] += t.totalAmount;
      totalRevenue += t.paidAmount;
    }

    // Process Expenses
    for (final e in expenses) {
      final monthKey = DateFormat('yyyy-MM').format(e.date);
      monthlyData.putIfAbsent(monthKey, () => {'rev': 0.0, 'exp': 0.0, 'txns': 0, 'total': 0.0});
      monthlyData[monthKey]!['exp'] += e.totalCost;
      totalExpensesValue += e.totalCost;
    }

    final profit = totalRevenue - totalExpensesValue;
    final avgTxn = totalTxns > 0 ? totalRevenue / totalTxns : 0.0;

    final rows = <List<dynamic>>[];

    // --- Section 1: Summary ---
    rows.add(['"--- OVERALL SUMMARY ---"', '', '', '', '', '']);
    rows.add(['Total Revenue', totalRevenue.toStringAsFixed(2), '', '', '', '']);
    rows.add(['Total Expenses', totalExpensesValue.toStringAsFixed(2), '', '', '', '']);
    rows.add(['Net Profit/Loss', profit.toStringAsFixed(2), '', '', '', '']);
    rows.add(['Total Transactions', totalTxns, '', '', '', '']);
    rows.add(['Average Transaction Value', avgTxn.toStringAsFixed(2), '', '', '', '']);
    rows.add(['', '', '', '', '', '']); // Blank row with padding
    
    // --- Section 2: Monthly Breakdown ---
    rows.add(['"--- MONTHLY BREAKDOWN ---"', '', '', '', '', '']);
    rows.add(['Month', 'Revenue', 'Expenses', 'Net Profit', 'Txn Count', 'Avg/Txn']);
    
    final sortedMonths = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a)); // Newest first

    for (final month in sortedMonths) {
      final data = monthlyData[month]!;
      final mRev = data['rev'] as double;
      final mExp = data['exp'] as double;
      final mTxns = data['txns'] as int;
      final mProfit = mRev - mExp;
      final mAvg = mTxns > 0 ? mRev / mTxns : 0.0;

      rows.add([
        month,
        mRev.toStringAsFixed(2),
        mExp.toStringAsFixed(2),
        mProfit.toStringAsFixed(2),
        mTxns,
        mAvg.toStringAsFixed(2),
      ]);
    }

    // Use the first row as headers to avoid an empty first row in the CSV
    final headers = rows.removeAt(0).map((e) => e.toString()).toList();
    await exportCsv(fileName: 'PandL_Report', headers: headers, rows: rows);
  }
}
