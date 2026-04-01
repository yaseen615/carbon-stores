import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../../core/constants/app_constants.dart';

class StudentRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _collection;

  StudentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.studentsCollection);

  /// Stream all students ordered by name
  Stream<List<Student>> getStudents() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Student.fromFirestore).toList());
  }

  /// Get a single student by admission number
  Future<Student?> getStudent(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Student.fromFirestore(doc);
  }

  /// Add a new student (using admission number as doc ID)
  Future<void> addStudent(Student student) async {
    final docRef = _collection.doc(student.id);
    final doc = await docRef.get();
    if (doc.exists) {
      throw Exception('A student with this admission number already exists');
    }
    await docRef.set(student.toFirestore());
  }

  /// Update a student
  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(data);
  }

  /// Atomic wallet recharge
  Future<void> rechargeWallet(String studentId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _collection.doc(studentId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('Student not found');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentBalance = (data['balance'] ?? 0).toDouble();
      final currentDebt = (data['debt'] ?? 0).toDouble();

      double newBalance = currentBalance + amount;
      double newDebt = currentDebt;

      // If student has debt, use recharge to clear debt first
      if (currentDebt > 0 && newBalance >= currentDebt) {
        newBalance -= currentDebt;
        newDebt = 0;
      } else if (currentDebt > 0) {
        newDebt -= newBalance;
        newBalance = 0;
      }

      transaction.update(docRef, {
        'balance': newBalance,
        'debt': newDebt,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Atomic wallet deduction during sale
  /// Returns actual amount deducted and any remaining debt
  Future<Map<String, double>> deductWallet(String studentId, double amount) async {
    return await _firestore.runTransaction((transaction) async {
      final docRef = _collection.doc(studentId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('Student not found');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentBalance = (data['balance'] ?? 0).toDouble();
      final currentDebt = (data['debt'] ?? 0).toDouble();

      double walletDeducted = 0;
      double newDebt = currentDebt;
      double newBalance = currentBalance;

      if (currentBalance >= amount) {
        // Wallet has enough - full deduction
        walletDeducted = amount;
        newBalance = currentBalance - amount;
      } else {
        // Wallet insufficient - deduct available, rest becomes debt
        walletDeducted = currentBalance;
        newBalance = 0;
        newDebt = currentDebt + (amount - currentBalance);
      }

      transaction.update(docRef, {
        'balance': newBalance,
        'debt': newDebt,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'wallet_deducted': walletDeducted,
        'debt_added': amount - walletDeducted,
        'new_balance': newBalance,
        'new_debt': newDebt,
      };
    });
  }

  /// Delete a student
  Future<void> deleteStudent(String id) async {
    await _collection.doc(id).delete();
  }
}
