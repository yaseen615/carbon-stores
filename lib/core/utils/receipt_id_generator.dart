import 'package:uuid/uuid.dart';

class ReceiptIdGenerator {
  ReceiptIdGenerator._();

  static const _uuid = Uuid();

  /// Generate a unique receipt ID like "CG-20260402-A1B2C3"
  static String generate() {
    final now = DateTime.now();
    final dateStr = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final shortId = _uuid.v4().substring(0, 6).toUpperCase();
    return 'CG-$dateStr-$shortId';
  }
}
