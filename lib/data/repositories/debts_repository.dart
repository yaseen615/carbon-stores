import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import 'audit_repository.dart';

class DebtsRepository {
  final FirebaseFirestore _firestore;

  DebtsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> clearDebt({
    required bool isStudent,
    required String personId,
    required String personName,
    required double amountCleared,
    required String paymentMode, // 'cash' or 'upi'
  }) async {
    await _firestore.runTransaction((tx) async {
      DocumentReference ref;
      double currentDebt = 0;
      double newDebt = 0;

      if (isStudent) {
        ref = _firestore.collection(AppConstants.studentsCollection).doc(personId);
        final doc = await tx.get(ref);
        if (!doc.exists) throw Exception('Student not found');
        
        final data = doc.data() as Map<String, dynamic>;
        currentDebt = (data['debt'] ?? 0).toDouble();
      } else {
        ref = _firestore.collection(AppConstants.externalDebtorsCollection).doc(personId);
        final doc = await tx.get(ref);
        if (!doc.exists) throw Exception('External debtor not found');
        
        final data = doc.data() as Map<String, dynamic>;
        currentDebt = (data['debt'] ?? 0).toDouble();
      }

      if (amountCleared > currentDebt) {
        throw Exception('Amount cleared cannot exceed current debt');
      }

      newDebt = currentDebt - amountCleared;

      tx.update(ref, {
        'debt': newDebt,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await AuditRepository(firestore: _firestore).log(
      action: AppConstants.auditEdit, // Using Edit for now, or create new "debt_clearance"
      description: 'Debt Clearance: $personName paid $amountCleared ($paymentMode)',
      metadata: {
        'person_id': personId,
        'person_name': personName,
        'is_student': isStudent,
        'amount_cleared': amountCleared,
        'payment_mode': paymentMode,
      },
    );
  }
}
