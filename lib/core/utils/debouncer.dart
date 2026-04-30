import 'dart:async';

/// A simple debouncer that delays execution until a pause in calls.
/// Use for search inputs to reduce unnecessary Firestore queries.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 350)});

  /// Run [action] after [delay] milliseconds of inactivity.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the debouncer is currently waiting.
  bool get isActive => _timer?.isActive ?? false;

  /// Dispose the debouncer. Call in widget dispose().
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
