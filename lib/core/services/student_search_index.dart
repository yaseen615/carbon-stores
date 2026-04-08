import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry in the local student search index.
/// Contains only the minimal data needed for search (zero Firestore reads).
class StudentIndexEntry {
  final String studentId;
  final String name;

  const StudentIndexEntry({required this.studentId, required this.name});

  Map<String, String> toJson() => {'id': studentId, 'name': name};

  factory StudentIndexEntry.fromJson(Map<String, dynamic> json) {
    return StudentIndexEntry(
      studentId: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// Lightweight local search index stored in SharedPreferences.
///
/// Holds only `{studentId: name}` pairs — no balances, no debt.
/// Rebuilt ONLY when sync is triggered (not on every app start).
/// Supports instant, case-insensitive substring search on both name & ID.
class StudentSearchIndex {
  static const String _storageKey = 'student_search_index';

  // In-memory cache (populated from SharedPreferences on first access)
  List<StudentIndexEntry>? _entries;

  /// Whether the index has been loaded from storage
  bool get isLoaded => _entries != null;

  /// Total number of indexed students
  int get length => _entries?.length ?? 0;

  /// Load the index from SharedPreferences into memory.
  /// Call once on first access. If no index exists, returns empty.
  Future<void> load() async {
    if (_entries != null) return; // already loaded

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _entries = [];
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      _entries = decoded
          .map((e) => StudentIndexEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _entries = [];
    }
  }

  /// Rebuild the index from a list of {studentId, name} pairs.
  /// Persists to SharedPreferences for offline use.
  Future<void> rebuild(List<StudentIndexEntry> entries) async {
    _entries = List.from(entries);
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_entries!.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Add a single student to the index (e.g. after manual add).
  /// Does NOT replace existing entries with the same ID.
  Future<void> addEntry(StudentIndexEntry entry) async {
    await load();
    // Avoid duplicates
    if (_entries!.any((e) => e.studentId == entry.studentId)) return;
    _entries!.add(entry);
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_entries!.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Search the index. Returns matching entries (max [limit]).
  ///
  /// Matches case-insensitively against both name and studentId.
  /// Supports substring matching (not just prefix).
  List<StudentIndexEntry> search(String query, {int limit = 12}) {
    if (_entries == null || query.trim().isEmpty) return [];

    final q = query.toLowerCase().trim();
    final results = <StudentIndexEntry>[];

    for (final entry in _entries!) {
      final nameLower = entry.name.toLowerCase();
      final idLower = entry.studentId.toLowerCase();

      // Match if the query matches the start of ANY word in the name,
      // or if it matches anywhere in the student ID.
      if (nameLower.startsWith(q) || 
          nameLower.contains(' $q') ||
          idLower.contains(q)) {
        results.add(entry);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Get all entries (e.g. for displaying default sorted list in UI).
  /// Returns a sorted copy ordered alphabetically by name.
  List<StudentIndexEntry> getAll() {
    if (_entries == null) return [];
    return List.from(_entries!)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Clear the index from memory and storage.
  Future<void> clear() async {
    _entries = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
