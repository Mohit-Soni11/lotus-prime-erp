import 'package:intl/intl.dart';

import '../domain/gst_report_models.dart';

class GstReportFormatters {
  GstReportFormatters._();

  static String monthLabel(GstReportPeriod period) {
    return DateFormat('MMMM yyyy').format(period.startDate);
  }

  static String periodLabel(GstReportPeriod period) {
    final start = DateFormat('d MMM yyyy').format(period.startDate);
    final end = DateFormat('d MMM yyyy').format(period.endDate);
    return '$start - $end';
  }

  static String date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  static String shortMonth(DateTime value) => DateFormat('MMM').format(value);

  static String monthYear(DateTime value) =>
      DateFormat('MMMM yyyy').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('dd MMM yyyy hh:mm a').format(value);

  static String money(double value) => 'Rs ${value.toStringAsFixed(2)}';

  static String rate(double value) => '${value.toStringAsFixed(2)}%';

  static String count(int value) => NumberFormat.decimalPattern().format(value);

  static String filePart(GstReportPeriod period) {
    return DateFormat('yyyy-MM').format(period.startDate);
  }
}
