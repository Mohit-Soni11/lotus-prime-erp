part of 'booking_advance_repository.dart';

int _bookingDocumentSequence(
  String orderNo, {
  required String yearToken,
}) {
  final normalized = orderNo.trim().toUpperCase();
  final current = RegExp(
    '^[A-Z0-9]{2,6}-BK-${RegExp.escape(yearToken)}-(\\d+)\$',
  ).firstMatch(normalized);
  if (current != null) {
    return int.tryParse(current.group(1) ?? '') ?? 0;
  }

  final legacy = RegExp(
    '^BK-[A-Z0-9]{1,8}-(\\d{4})-(\\d+)\$',
  ).firstMatch(normalized);
  if (legacy != null &&
      _legacyFinancialYearStartToken(legacy.group(1) ?? '') == yearToken) {
    return int.tryParse(legacy.group(2) ?? '') ?? 0;
  }

  return 0;
}

String _legacyFinancialYearStartToken(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 4) {
    final first = int.tryParse(digits.substring(0, 2));
    final second = int.tryParse(digits.substring(2, 4));
    if (first != null && second != null) {
      return (second - first + 100) % 100 == 1
          ? digits.substring(0, 2)
          : digits.substring(2, 4);
    }
  }
  if (digits.length >= 2) {
    return digits.substring(0, 2);
  }
  return PosInvoiceSeriesFormatter.normalizeFinancialYearToken(value);
}

String _legacyFinancialYearSpan(String yearToken) {
  final start = int.tryParse(yearToken) ?? 0;
  final end = (start + 1) % 100;
  return '${start.toString().padLeft(2, '0')}'
      '${end.toString().padLeft(2, '0')}';
}

String _legacyCalendarYear(String yearToken) {
  return '20${yearToken.padLeft(2, '0')}';
}

String _shopNameFromSetup(Map<String, dynamic>? shopData) {
  final basicInfo = shopData?['basic_info'] as Map<String, dynamic>?;
  return [
    basicInfo?['brand_display_name'],
    basicInfo?['display_name'],
    basicInfo?['legal_name'],
  ]
      .map((value) => value?.toString().trim() ?? '')
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _nullableUpper(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed.toUpperCase();
}
