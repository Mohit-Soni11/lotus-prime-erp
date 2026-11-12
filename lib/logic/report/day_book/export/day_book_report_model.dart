import 'package:intl/intl.dart';

class DayBookReportCell {
  const DayBookReportCell(this.raw, {String? display})
      : display = display ?? raw;

  final String raw;
  final String display;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'INR ',
    decimalDigits: 2,
  );

  factory DayBookReportCell.money(num? amount) => amount == null
      ? const DayBookReportCell('Not recorded')
      : DayBookReportCell(amount.toStringAsFixed(2),
          display: _currency.format(amount));

  factory DayBookReportCell.weight(num? grams) => grams == null
      ? const DayBookReportCell('Unverified')
      : DayBookReportCell(grams.toStringAsFixed(3),
          display: '${grams.toStringAsFixed(3)} g');

  factory DayBookReportCell.count(num value) =>
      DayBookReportCell(value.toString());
}

class DayBookReportSection {
  const DayBookReportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<DayBookReportCell>> rows;
}
