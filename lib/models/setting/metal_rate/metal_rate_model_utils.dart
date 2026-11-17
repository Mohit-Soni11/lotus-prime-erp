part of 'metal_rate_model.dart';

double _toDouble(Object? value, {double fallback = 0.0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
  }
  return fallback;
}

Map<String, double> _toDoubleMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map(
    (key, item) => MapEntry(_purityKey(key.toString()), _toDouble(item)),
  );
}

String _purityKey(String value) {
  final cleaned = value.trim().toUpperCase().replaceAll('KT', 'K');
  return cleaned;
}
