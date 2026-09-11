import 'package:intl/intl.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';

class SalesReportExportIdentity {
  final String shopName;
  final List<String> headerLines;

  const SalesReportExportIdentity({
    required this.shopName,
    this.headerLines = const [],
  });

  static const fallback = SalesReportExportIdentity(shopName: 'Sales Report');
}

class SalesReportExportFormatters {
  SalesReportExportFormatters._();

  static String date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('dd MMM yyyy hh:mm a').format(value);

  static String money(double value) => 'Rs ${value.toStringAsFixed(2)}';

  static String weight(double value) => '${value.toStringAsFixed(3)} g';

  static double totalNetWeight(List<SalesReportItemRow> items) {
    return items.fold(0, (sum, item) => sum + item.netWeight);
  }

  static String periodLabel(SalesReportFilter filter) {
    final start = DateFormat('d MMM yyyy').format(filter.startDate);
    final end = DateFormat('d MMM yyyy').format(filter.endDate);
    return start == end ? start : '$start - $end';
  }

  static String taxModeLabel(SalesReportTaxMode mode) {
    switch (mode) {
      case SalesReportTaxMode.all:
        return 'All Bills';
      case SalesReportTaxMode.gst:
        return 'GST Bills';
      case SalesReportTaxMode.nonGst:
        return 'Normal Bills';
    }
  }

  static String paymentFilterLabel(SalesReportPaymentFilter filter) {
    switch (filter) {
      case SalesReportPaymentFilter.all:
        return 'All Payments';
      case SalesReportPaymentFilter.paid:
        return 'Paid';
      case SalesReportPaymentFilter.due:
        return 'Due';
      case SalesReportPaymentFilter.partial:
        return 'Partial';
    }
  }

  static String filePart(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'sales-report' : normalized;
  }

  static List<List<String>> salesSummaryRows(SalesReportSummary summary) {
    return [
      ['Invoices', '${summary.invoiceCount}'],
      ['GST Bills', '${summary.gstInvoiceCount}'],
      ['Normal Bills', '${summary.nonGstInvoiceCount}'],
      ['Gross Amount', money(summary.grossAmount)],
      ['Discount', money(summary.discountAmount)],
      ['Taxable Amount', money(summary.taxableAmount)],
      ['GST Amount', money(summary.gstAmount)],
      ['Round Off', money(summary.roundOffAmount)],
      ['Final Amount', money(summary.finalAmount)],
      ['Making Amount', money(summary.makingAmount)],
      ['Net Weight', weight(summary.netWeight)],
    ];
  }

  static List<List<String>> salesSummaryRowsWithMetalBreakdown(
    SalesReportSnapshot snapshot,
  ) {
    return [
      ...salesSummaryRows(snapshot.summary)
          .where((row) => row[0] != 'Net Weight'),
      [
        'Net Weight by Metal',
        totalNetWeightWithBreakdown(snapshot.items),
      ],
    ];
  }

  static List<List<String>> gstLiabilityRows(
    SalesReportGstLiabilitySummary summary,
  ) {
    final rows = <List<String>>[
      ['Invoices in Period', '${summary.invoiceCount}'],
      ['GST Bills', '${summary.gstInvoiceCount}'],
      ['Normal Bills', '${summary.nonGstInvoiceCount}'],
      ['Normal Bill Sales', money(summary.nonGstSalesAmount)],
      ['GST Bill Sales', money(summary.gstFinalAmount)],
      ['Due Amount', money(summary.dueAmount)],
      ['GST Collected', money(summary.recordedGstAmount)],
      [
        'Normal Bill GST Estimate (${rate(summary.projectedGstRatePercent)})',
        money(summary.projectedGstAmount),
      ],
    ];
    return rows.where((row) {
      if (row.length < 2) return true;
      if (row[0] == 'Due Amount') return summary.dueAmount.abs() > 0.005;
      if (row[0] == 'GST Collected') {
        return summary.recordedGstAmount.abs() > 0.005;
      }
      if (row[0].startsWith('Normal Bill GST Estimate')) {
        return summary.projectedGstAmount.abs() > 0.005;
      }
      return true;
    }).toList(growable: false);
  }

  static List<List<String>> metalRows(List<SalesReportMetalSummary> metals) {
    return metals
        .map(
          (metal) => [
            metal.metalType,
            '${metal.invoiceCount}',
            '${metal.itemCount}',
            '${metal.pieces}',
            weight(metal.grossWeight),
            weight(metal.netWeight),
            money(metal.makingAmount),
            money(metal.salesAmount),
          ],
        )
        .toList(growable: false);
  }

  static Map<int, Map<String, double>> invoiceWeights(
    List<SalesReportItemRow> items,
  ) {
    final weights = <int, Map<String, double>>{};
    for (final item in items) {
      final byMetal = weights.putIfAbsent(item.billId, () => {});
      final metal = item.metalType.trim().isEmpty ? 'Metal' : item.metalType;
      byMetal[metal] = (byMetal[metal] ?? 0) + item.netWeight;
    }
    return weights;
  }

  static String invoiceWeightTotal(List<SalesReportItemRow> items) {
    final totals = <String, double>{};
    for (final item in items) {
      final metal = item.metalType.trim().isEmpty ? 'Metal' : item.metalType;
      totals[metal] = (totals[metal] ?? 0) + item.netWeight;
    }
    return weightSummary(totals);
  }

  static String totalNetWeightWithBreakdown(List<SalesReportItemRow> items) {
    final total = weight(totalNetWeight(items));
    final breakdown = invoiceWeightTotal(items);
    return breakdown == '-' ? total : '$total ($breakdown)';
  }

  static String weightSummary(Map<String, double> weights) {
    if (weights.isEmpty) return '-';
    final metals = weights.keys.toList()..sort();
    return metals
        .map((metal) => '$metal ${weight(weights[metal]!)}')
        .join(' | ');
  }

  static List<List<String>> gradeRows(List<SalesReportItemRow> items) {
    final groups = <String, List<SalesReportItemRow>>{};
    for (final item in items) {
      final grade = item.purity.trim().isEmpty ? 'UNSPECIFIED' : item.purity;
      groups.putIfAbsent(grade, () => []).add(item);
    }
    final grades = groups.keys.toList()..sort();
    return [
      for (final grade in grades)
        [
          grade,
          '${groups[grade]!.map((item) => item.billId).toSet().length}',
          '${groups[grade]!.length}',
          '${groups[grade]!.fold(0, (sum, item) => sum + item.quantity)}',
          weight(
            groups[grade]!.fold(0, (sum, item) => sum + item.grossWeight),
          ),
          weight(
            groups[grade]!.fold(0, (sum, item) => sum + item.netWeight),
          ),
          money(
            groups[grade]!.fold(0, (sum, item) => sum + item.makingCharge),
          ),
          money(groups[grade]!.fold(0, (sum, item) => sum + item.itemTotal)),
        ],
    ];
  }

  static String rate(double value) => '${value.toStringAsFixed(2)}%';
}
