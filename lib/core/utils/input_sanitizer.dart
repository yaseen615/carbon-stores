/// Utility for sanitizing user inputs before persistence.
class InputSanitizer {
  InputSanitizer._();

  /// Sanitize a text input: trim, collapse whitespace, limit length.
  static String sanitize(String input, {int maxLength = 200}) {
    var s = input.trim();
    // Collapse multiple spaces into one
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // Limit length
    if (s.length > maxLength) {
      s = s.substring(0, maxLength);
    }
    return s;
  }

  /// Sanitize a name (person or product): capitalize first letters, trim.
  static String sanitizeName(String input, {int maxLength = 100}) {
    return sanitize(input, maxLength: maxLength);
  }

  /// Sanitize a numeric string: ensure it parses to a valid non-negative double.
  /// Returns 0.0 if invalid.
  static double sanitizeAmount(String input) {
    final value = double.tryParse(input.trim()) ?? 0.0;
    return value < 0 ? 0.0 : value;
  }
}
