class PosNumberParser {
  const PosNumberParser._();

  static final RegExp _nonNegativeNumberPattern = RegExp(r'^\d+(?:\.\d*)?$');

  static double parseNonNegative(String value, {double fallback = 0}) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return fallback;
    }
    if (!_nonNegativeNumberPattern.hasMatch(normalized)) {
      return fallback;
    }
    return double.tryParse(normalized) ?? fallback;
  }
}
