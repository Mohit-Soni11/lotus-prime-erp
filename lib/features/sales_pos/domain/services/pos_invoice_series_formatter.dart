class PosInvoiceSeriesFormatter {
  const PosInvoiceSeriesFormatter._();

  static final RegExp _tokenCleanup = RegExp(r'[^A-Z0-9]');
  static final RegExp _currentPattern =
      RegExp(r'^([A-Z0-9]{2,6})-(\d{2})-(\d+)$');
  static final RegExp _legacyPattern =
      RegExp(r'^(?:TAX|INV|EST)-([A-Z0-9]{1,8})-(\d{4})-(\d+)$');

  static String businessCode(String shopName) {
    final words = shopName
        .trim()
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(_tokenCleanup, ''))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}';
    }
    if (words.length == 1) {
      final word = words.single;
      return word.length == 1 ? '${word}H' : word.substring(0, 2);
    }
    return 'SH';
  }

  static int financialYearStart(DateTime date) {
    return date.month >= DateTime.april ? date.year : date.year - 1;
  }

  static String financialYearToken(DateTime date) {
    return (financialYearStart(date) % 100).toString().padLeft(2, '0');
  }

  static String build({
    required String businessCode,
    required String financialYearToken,
    required int sequence,
  }) {
    return '${normalizeBusinessCode(businessCode)}-'
        '${normalizeFinancialYearToken(financialYearToken)}-'
        '${formatSequence(sequence)}';
  }

  static String formatSequence(int sequence) {
    final normalized = sequence < 1 ? 1 : sequence;
    return normalized.toString().padLeft(3, '0');
  }

  static String normalizeBusinessCode(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(_tokenCleanup, '');
    if (normalized.length >= 2) return normalized.substring(0, 2);
    if (normalized.length == 1) return '${normalized}H';
    return 'SH';
  }

  static String normalizeFinancialYearToken(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return ((int.tryParse(digits.substring(0, 4)) ?? DateTime.now().year) %
              100)
          .toString()
          .padLeft(2, '0');
    }
    if (digits.length >= 2) return digits.substring(0, 2);
    if (digits.length == 1) return '0$digits';
    return financialYearToken(DateTime.now());
  }

  static ParsedPosInvoiceSeries? parse(String billNumber) {
    final normalized = billNumber.trim().toUpperCase();
    final current = _currentPattern.firstMatch(normalized);
    if (current != null) {
      return ParsedPosInvoiceSeries(
        businessCode: normalizeBusinessCode(current.group(1) ?? ''),
        financialYearToken: normalizeFinancialYearToken(current.group(2) ?? ''),
        sequence: int.tryParse(current.group(3) ?? '') ?? 0,
        isLegacy: false,
      );
    }

    final legacy = _legacyPattern.firstMatch(normalized);
    if (legacy != null) {
      return ParsedPosInvoiceSeries(
        businessCode: normalizeBusinessCode(legacy.group(1) ?? ''),
        financialYearToken: normalizeFinancialYearToken(legacy.group(2) ?? ''),
        sequence: int.tryParse(legacy.group(3) ?? '') ?? 0,
        isLegacy: true,
      );
    }

    return null;
  }
}

class ParsedPosInvoiceSeries {
  const ParsedPosInvoiceSeries({
    required this.businessCode,
    required this.financialYearToken,
    required this.sequence,
    required this.isLegacy,
  });

  final String businessCode;
  final String financialYearToken;
  final int sequence;
  final bool isLegacy;
}
