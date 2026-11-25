import 'package:intl/intl.dart';

String dayBookMetalWeight(double grams) {
  final kilograms = grams.abs() >= 1000;
  final value = kilograms ? grams / 1000 : grams;
  final pattern = kilograms ? '#,##0.000###' : '#,##0.000';
  return '${NumberFormat(pattern, 'en_IN').format(value)} ${kilograms ? 'kg' : 'g'}';
}
