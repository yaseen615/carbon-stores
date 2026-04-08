import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Callback for reporting sync progress: (processed, total)
typedef SyncProgressCallback = void Function(int processed, int total);

/// Result model for sync operation
class StudentSyncResult {
  final int totalFetched;
  final int newlyAdded;
  final int alreadyExisted;
  final String? error;

  const StudentSyncResult({
    required this.totalFetched,
    required this.newlyAdded,
    required this.alreadyExisted,
    this.error,
  });

  bool get hasError => error != null;

  factory StudentSyncResult.failure(String message) => StudentSyncResult(
        totalFetched: 0,
        newlyAdded: 0,
        alreadyExisted: 0,
        error: message,
      );
}

/// Service to sync students from an external GraphQL API into Firestore.
///
/// Key guarantees:
/// - NEVER updates existing student records
/// - NEVER modifies wallets, balances, or debt
/// - ONLY inserts students that don't already exist
/// - Uses studentId as Firestore document ID to enforce uniqueness
/// - Uses batch writes for performance
class StudentSyncService {
  final FirebaseFirestore _firestore;
  final String _graphqlEndpoint;

  StudentSyncService({
    FirebaseFirestore? firestore,
    required String graphqlEndpoint,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _graphqlEndpoint = graphqlEndpoint;

  /// The GraphQL query to fetch all students
  static const String _query = '''
    query GetAllStudents {
      students {
        edges {
          node {
            id
            studentId
            fullName
          }
        }
      }
    }
  ''';

  /// Fetches students from GraphQL API and syncs new ones to Firestore.
  ///
  /// [onProgress] is called after each student is processed with (processed, total).
  /// Returns a [StudentSyncResult] with counts of fetched, added, and skipped.
  Future<StudentSyncResult> syncStudents({
    SyncProgressCallback? onProgress,
  }) async {
    try {
      // ── Step 1: Fetch from GraphQL API ──
      onProgress?.call(0, 0); // Signal: fetching from API
      final students = await _fetchStudentsFromApi();

      if (students.isEmpty) {
        return const StudentSyncResult(
          totalFetched: 0,
          newlyAdded: 0,
          alreadyExisted: 0,
        );
      }

      // ── Step 2: Sync to Firestore (insert-only, no updates) ──
      return await _syncToFirestore(students, onProgress: onProgress);
    } on http.ClientException catch (e) {
      return StudentSyncResult.failure('Network error: ${e.message}');
    } on FormatException catch (e) {
      return StudentSyncResult.failure('Invalid response format: ${e.message}');
    } catch (e) {
      return StudentSyncResult.failure(e.toString());
    }
  }

  /// Fetches students from the external GraphQL API.
  ///
  /// Returns a list of maps with keys: `studentId`, `fullName`
  Future<List<Map<String, String>>> _fetchStudentsFromApi() async {
    final response = await http.post(
      Uri.parse(_graphqlEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': _query}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'API returned status ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for GraphQL errors
    if (body.containsKey('errors')) {
      final errors = body['errors'] as List;
      final message =
          errors.isNotEmpty ? errors.first['message'] ?? 'Unknown error' : 'Unknown error';
      throw Exception('GraphQL error: $message');
    }

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Missing "data" field in response');
    }

    final studentsData = data['students'] as Map<String, dynamic>?;
    if (studentsData == null) {
      throw const FormatException('Missing "students" field in response');
    }

    final edges = studentsData['edges'] as List<dynamic>?;
    if (edges == null || edges.isEmpty) {
      return [];
    }

    final students = <Map<String, String>>[];
    for (final edge in edges) {
      final node = edge['node'] as Map<String, dynamic>?;
      if (node == null) continue;

      final studentId = node['studentId']?.toString();
      final fullName = node['fullName']?.toString();

      // Skip entries with missing required fields
      if (studentId == null ||
          studentId.isEmpty ||
          fullName == null ||
          fullName.isEmpty) {
        continue;
      }

      students.add({
        'studentId': studentId.trim(),
        'fullName': fullName.trim(),
      });
    }

    return students;
  }

  /// Syncs fetched students to Firestore using batch writes.
  ///
  /// Strategy:
  /// - Uses studentId as the Firestore document ID (enforces uniqueness)
  /// - Checks existence via doc.exists before writing
  /// - Only creates new documents; never updates existing ones
  /// - Batches writes in groups of 400 (under Firestore's 500 limit)
  /// - Yields to the event loop periodically so the UI can repaint progress
  Future<StudentSyncResult> _syncToFirestore(
      List<Map<String, String>> students, {
      SyncProgressCallback? onProgress,
  }) async {
    final collection =
        _firestore.collection(AppConstants.studentsCollection);

    int newlyAdded = 0;
    int alreadyExisted = 0;
    final total = students.length;

    const batchSize = 400;

    WriteBatch? batch;
    int opsInBatch = 0;

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final studentId = student['studentId']!;

      // Check if student already exists
      final doc = await collection.doc(studentId).get();

      if (doc.exists) {
        alreadyExisted++;
      } else {
        // Student doesn't exist — queue for batch write
        batch ??= _firestore.batch();

        final docRef = collection.doc(studentId);
        batch.set(docRef, {
          'name': student['fullName']!,
          'balance': 0,
          'debt': 0,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        newlyAdded++;
        opsInBatch++;

        // Commit if batch is getting full
        if (opsInBatch >= batchSize) {
          await batch.commit();
          batch = null;
          opsInBatch = 0;
        }
      }

      // Report progress
      onProgress?.call(i + 1, total);

      // Yield to event loop every 5 students so UI can repaint
      if ((i + 1) % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // Commit remaining operations
    if (batch != null && opsInBatch > 0) {
      await batch.commit();
    }

    return StudentSyncResult(
      totalFetched: students.length,
      newlyAdded: newlyAdded,
      alreadyExisted: alreadyExisted,
    );
  }
}
