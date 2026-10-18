import '../../../models/girvi/girvi_enums.dart';

/// Customer-facing labels derived from the stored Girvi item description.
class NoticeItemDescription {
  const NoticeItemDescription._();

  static String? itemNames(String description) {
    final names = <String>{};
    for (final line in description.split(RegExp(r'\r?\n'))) {
      final firstField = line.split('|').first.trim();
      final name = firstField
          .replaceFirst(
            RegExp(r'^(?:Serial Number\s+\d+\s*-?\s*|#\s*\d+\s*)',
                caseSensitive: false),
            '',
          )
          .trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names.isEmpty ? null : names.join(', ');
  }

  static String? purity(String description, {String? fallback}) {
    final codes = <String>{};
    for (final match in RegExp(
            r'\b(?:24|22|20|18|14)K(?:T)?\b|\b(?:999|925|800)\b',
            caseSensitive: false)
        .allMatches(description)) {
      codes.add(match.group(0)!.toUpperCase());
    }
    if (codes.isEmpty && fallback?.trim().isNotEmpty == true) {
      codes.add(fallback!.trim());
    }
    if (codes.isEmpty) return null;
    return codes.map(_purityLabel).join(', ');
  }

  static String _purityLabel(String code) {
    final normalized = code.toUpperCase();
    for (final purity in MetalPurity.values) {
      if (purity == MetalPurity.other) continue;
      final matches = purity.dbValue.toUpperCase() == normalized ||
          purity.legacyValues.any((value) => value.toUpperCase() == normalized);
      if (matches) {
        return '${purity.dbValue} (${(purity.fineness * 100).toStringAsFixed(1)}%)';
      }
    }
    return code;
  }
}
