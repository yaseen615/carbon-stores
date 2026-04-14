import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../../core/constants/app_constants.dart';

/// Holds aggregate stats computed via Firestore AggregateQuery (1 read).
class StudentStats {
  final double totalBalance;
  final double totalDebt;
  final int count;

  const StudentStats({
    required this.totalBalance,
    required this.totalDebt,
    required this.count,
  });

  static const empty = StudentStats(totalBalance: 0, totalDebt: 0, count: 0);
}

/// Holds a page of students with cursor for the next page.
class StudentPage {
  final List<Student> students;
  final DocumentSnapshot? lastDocument; // cursor for startAfter
  final bool hasMore;

  const StudentPage({
    required this.students,
    required this.lastDocument,
    required this.hasMore,
  });
}

class StudentRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _collection;

  StudentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.studentsCollection);

  // ──────────────────────────────────────────────────────────
  //  PAGINATED QUERIES (9–12 docs per page instead of ALL)
  // ──────────────────────────────────────────────────────────

  /// Fetch a single page of students, ordered by name.
  ///
  /// [limit]      — how many to fetch (default 12)
  /// [startAfter] — cursor from the previous page's [lastDocument]
  ///
  /// Cost: [limit] reads.
  Future<StudentPage> getStudentsPaginated({
    int limit = 12,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _collection.orderBy('name').limit(limit + 1); // +1 to detect hasMore

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

    return StudentPage(
      students: pageDocs.map(Student.fromFirestore).toList(),
      lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
      hasMore: hasMore,
    );
  }

  // ──────────────────────────────────────────────────────────
  //  AGGREGATE QUERIES (1 read instead of N)
  // ──────────────────────────────────────────────────────────

  /// Get total balance, total debt, and student count using
  /// Firestore's AggregateQuery. Costs 1 document read.
  Future<StudentStats> getStudentStats() async {
    try {
      final aggregation = await _collection.aggregate(
        sum('balance'),
        sum('debt'),
        count(),
      ).get();

      return StudentStats(
        totalBalance: (aggregation.getSum('balance') ?? 0).toDouble(),
        totalDebt: (aggregation.getSum('debt') ?? 0).toDouble(),
        count: aggregation.count ?? 0,
      );
    } catch (_) {
      // Fallback if aggregate not supported (very old SDK)
      return StudentStats.empty;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  TARGETED READS (for search results & individual students)
  // ──────────────────────────────────────────────────────────

  /// Fetch specific students by their IDs (document IDs).
  /// Cost: [ids.length] reads — typically 5–12 for search results.
  Future<List<Student>> getStudentsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'whereIn' supports max 30 values per query
    final results = <Student>[];
    for (int i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(
        i,
        i + 30 > ids.length ? ids.length : i + 30,
      );
      final snapshot = await _collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snapshot.docs.map(Student.fromFirestore));
    }
    return results;
  }

  /// Get a single student by admission number
  Future<Student?> getStudent(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Student.fromFirestore(doc);
  }

  /// Search students directly in Firestore (no local index needed).
  ///
  /// Uses a two-pronged approach for fast, comprehensive results:
  ///   1. **Name prefix query** — Firestore range scan on `name` field.
  ///      Uses Unicode upper bound trick for case-insensitive prefix matching.
  ///   2. **Document ID lookup** — exact match on admission number.
  ///
  /// Results are deduplicated and capped at [limit].
  /// Cost: 2 Firestore queries (name range + doc get).
  Future<List<Student>> searchStudents(String query, {int limit = 12}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = <String, Student>{}; // dedupe by ID

    // ── Strategy 1: Name prefix search (case-insensitive) ──
    // Firestore doesn't natively support case-insensitive search,
    // so we query with the original casing AND a capitalised variant.
    // The Unicode '\uf8ff' trick gives us "starts with" behavior.
    try {
      final lowerQ = trimmed.toLowerCase();
      final capitalQ = trimmed.substring(0, 1).toUpperCase() +
          (trimmed.length > 1 ? trimmed.substring(1).toLowerCase() : '');

      // Query 1a: lowercase prefix
      final snap1 = await _collection
          .orderBy('name')
          .startAt([lowerQ])
          .endAt(['$lowerQ\uf8ff'])
          .limit(limit)
          .get();
      for (final doc in snap1.docs) {
        results[doc.id] = Student.fromFirestore(doc);
      }

      // Query 1b: capitalised prefix (covers "Rahul", "John", etc.)
      if (results.length < limit) {
        final snap2 = await _collection
            .orderBy('name')
            .startAt([capitalQ])
            .endAt(['$capitalQ\uf8ff'])
            .limit(limit - results.length)
            .get();
        for (final doc in snap2.docs) {
          results[doc.id] = Student.fromFirestore(doc);
        }
      }

      // Query 1c: uppercase prefix (covers "RAHUL", etc.)
      if (results.length < limit) {
        final upperQ = trimmed.toUpperCase();
        if (upperQ != capitalQ) {
          final snap3 = await _collection
              .orderBy('name')
              .startAt([upperQ])
              .endAt(['$upperQ\uf8ff'])
              .limit(limit - results.length)
              .get();
          for (final doc in snap3.docs) {
            results[doc.id] = Student.fromFirestore(doc);
          }
        }
      }
    } catch (_) {
      // Firestore index may not exist yet — continue to ID lookup
    }

    // ── Strategy 2: Exact document ID lookup (admission number) ──
    if (results.length < limit) {
      try {
        final doc = await _collection.doc(trimmed).get();
        if (doc.exists) {
          results[doc.id] = Student.fromFirestore(doc);
        }
      } catch (_) {}
    }

    return results.values.take(limit).toList();
  }

  // ──────────────────────────────────────────────────────────
  //  FULL COLLECTION (only for CSV export — on-demand)
  // ──────────────────────────────────────────────────────────

  /// Stream all students ordered by name.
  /// ⚠️  Use ONLY for CSV export. Costs N reads.
  Stream<List<Student>> getStudents() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Student.fromFirestore).toList());
  }

  /// One-time fetch of all students (for CSV export).
  /// Use instead of the stream when you just need current data.
  Future<List<Student>> getAllStudentsForExport() async {
    final snapshot = await _collection.orderBy('name').get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  // ──────────────────────────────────────────────────────────
  //  WRITE OPERATIONS (unchanged — existing logic preserved)
  // ──────────────────────────────────────────────────────────

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
