final class AddStockPurityUtils {
  const AddStockPurityUtils._();

  static String formatRateText(double value) {
    if (value <= 0) {
      return '';
    }

    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  static double parseRateText(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  static String shortPurityLabel(String value) {
    final normalized = value.toUpperCase().replaceAll('KT', 'K');
    final match = RegExp(r'(\d{1,2}K)').firstMatch(normalized);
    if (match != null) {
      return match.group(1)!;
    }
    if (normalized.contains('999')) {
      return '24K';
    }
    if (normalized.contains('916')) {
      return '22K';
    }
    if (normalized.contains('750')) {
      return '18K';
    }
    if (normalized.contains('585')) {
      return '14K';
    }
    if (normalized.contains('375')) {
      return '9K';
    }
    if (normalized.contains('417')) {
      return '10K';
    }
    return value.trim();
  }

  static String normaliseRateKey(String value) {
    final normalized = value.trim().toUpperCase().replaceAll('KT', 'K');
    final karatMatch = RegExp(r'(\d{1,2}K)').firstMatch(normalized);
    if (karatMatch != null) {
      return karatMatch.group(1)!;
    }
    if (normalized.contains('999')) return '24K';
    if (normalized.contains('916')) return '22K';
    if (normalized.contains('750')) return '18K';
    if (normalized.contains('585')) return '14K';
    if (normalized.contains('375')) return '9K';
    return normalized;
  }

  static double resolvePurityPercent(String value) {
    final normalized = value.toUpperCase().replaceAll('KT', 'K');

    final karatMatch = RegExp(r'(\d{1,2})K').firstMatch(normalized);
    if (karatMatch != null) {
      final karat = double.tryParse(karatMatch.group(1) ?? '');
      if (karat != null) {
        return (karat / 24.0) * 100.0;
      }
    }

    final hallmarkMatch = RegExp(
      r'\((\d{3}(?:\.\d+)?)\)',
    ).firstMatch(normalized);
    if (hallmarkMatch != null) {
      final hallmark = double.tryParse(hallmarkMatch.group(1) ?? '');
      if (hallmark != null) {
        return hallmark / 10.0;
      }
    }

    final directPercentMatch = RegExp(
      r'(\d{2,3}(?:\.\d+)?)\s*%',
    ).firstMatch(normalized);
    if (directPercentMatch != null) {
      return double.tryParse(directPercentMatch.group(1) ?? '') ?? 0.0;
    }

    final pureCodeMatch = RegExp(
      r'\b(999|925|800|700)\b',
    ).firstMatch(normalized);
    if (pureCodeMatch != null) {
      final code = double.tryParse(pureCodeMatch.group(1) ?? '');
      if (code != null) {
        return code / 10.0;
      }
    }

    return 0.0;
  }

  static bool near(double a, double b) => (a - b).abs() < 0.11;
}
