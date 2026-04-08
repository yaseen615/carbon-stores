import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/transaction_model.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

class ReceiptGenerator {
  static String _formatPdfCurrency(double amount) {
    return CurrencyFormatter.format(amount).replaceAll('₹', 'Rs. ');
  }

  static Future<Uint8List> generateReceipt(
    StoreTransaction transaction, {
    double? walletDeducted,
    double? cashAmount,
  }) async {
    final pdf = pw.Document();

    // Standard receipt width: ~80mm (roughly 226 points)
    final pageFormat = PdfPageFormat.roll80.copyWith(
      marginBottom: 30,
      marginLeft: 10,
      marginRight: 10,
      marginTop: 10,
    );

    // Use the actual stored amounts if available, otherwise fallback to approximation
    double calculatedWallet = walletDeducted ?? transaction.walletAmount;
    double calculatedCash = cashAmount ?? transaction.cashAmount;
    
    if (walletDeducted == null && cashAmount == null && transaction.walletAmount == 0 && transaction.cashAmount == 0) {
      if (transaction.paymentMode == 'wallet') {
        calculatedWallet = transaction.totalAmount; // Entire amount came from wallet
      } else if (transaction.paymentMode == 'cash') {
        calculatedCash = transaction.totalAmount; // Entire amount came from cash
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store Header
              pw.Center(
                child: pw.Text(
                  'CARBON GURUKULAM',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),
              ),
              pw.Center(
                child: pw.Text('Cash Receipt', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(DateFormatter.formatDateTime(transaction.createdAt), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(transaction.receiptId, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              
              if (transaction.studentName != null && transaction.studentName!.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Student:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(transaction.studentName!, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Items Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                ]
              ),
              pw.SizedBox(height: 3),

              // Items List
              ...transaction.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(_formatPdfCurrency(item.total), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL DO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatPdfCurrency(transaction.totalAmount), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 8),

              // Payment Breakdown
              if (calculatedWallet > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid via Wallet', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(_formatPdfCurrency(calculatedWallet), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              if (calculatedCash > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid via Cash', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(_formatPdfCurrency(calculatedCash), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              if (transaction.debtAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Added to Debt', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_formatPdfCurrency(transaction.debtAmount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),

              // Cancelled Notice
              if (transaction.isVoided) ...[
                 pw.SizedBox(height: 10),
                 pw.Center(child: pw.Text('*** CANCELLED TRANSACTION ***', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              ],

              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('Thank you!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print the receipt directly
  static Future<void> printReceipt(StoreTransaction transaction, {double? walletDeducted, double? cashAmount}) async {
    final pdfBytes = await generateReceipt(transaction, walletDeducted: walletDeducted, cashAmount: cashAmount);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt_${transaction.receiptId}',
    );
  }
}
