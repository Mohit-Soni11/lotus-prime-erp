import '../domain/gst_report_models.dart';

class GstReportSegmentProjector {
  GstReportSegmentProjector._();

  static GstReportSnapshot project(
    GstReportSnapshot snapshot,
    GstFilingSegment segment,
  ) {
    final invoices = _invoicesFor(snapshot, segment);
    final hsnRows = snapshot.hsnSummary
        .where((row) => row.invoiceType == segment.code)
        .toList(growable: false);
    final rateRows = _buildRateSummary(invoices);
    final dashboard = _buildDashboard(snapshot, invoices, segment);
    final audit = _buildAudit(snapshot, invoices, hsnRows, segment);

    return GstReportSnapshot(
      period: snapshot.period,
      identity: snapshot.identity,
      dashboard: dashboard,
      gstr1B2bInvoices: segment == GstFilingSegment.b2b ? invoices : const [],
      gstr1B2cInvoices: segment == GstFilingSegment.b2c ? invoices : const [],
      hsnSummary: hsnRows,
      rateSummary: rateRows,
      gstr3b: Gstr3bSummary(
        outwardTaxableValue: dashboard.taxableSales,
        outwardCgst: dashboard.cgstAmount,
        outwardSgst: dashboard.sgstAmount,
        outwardIgst: dashboard.igstAmount,
        nilExemptNonGstValue: 0,
      ),
      auditFindings: audit,
    );
  }

  static List<GstInvoiceRow> _invoicesFor(
    GstReportSnapshot snapshot,
    GstFilingSegment segment,
  ) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return snapshot.gstr1B2bInvoices;
      case GstFilingSegment.b2c:
        return snapshot.gstr1B2cInvoices;
    }
  }

  static GstReportDashboardSummary _buildDashboard(
    GstReportSnapshot snapshot,
    List<GstInvoiceRow> invoices,
    GstFilingSegment segment,
  ) {
    final exclusiveInvoices = invoices
        .where((row) =>
            row.gstPricingMode.trim().toUpperCase() != 'GST_INCLUSIVE')
        .toList(growable: false);
    final inclusiveInvoices = invoices
        .where((row) =>
            row.gstPricingMode.trim().toUpperCase() == 'GST_INCLUSIVE')
        .toList(growable: false);
    final exclusive = _pricingSummary(exclusiveInvoices);
    final inclusive = _pricingSummary(inclusiveInvoices);

    return GstReportDashboardSummary(
      totalInvoices: invoices.length +
          (segment == GstFilingSegment.b2c
              ? snapshot.dashboard.nonGstInvoiceCount
              : 0),
      gstInvoiceCount: invoices.length,
      nonGstInvoiceCount: segment == GstFilingSegment.b2c
          ? snapshot.dashboard.nonGstInvoiceCount
          : 0,
      exclusive: exclusive,
      inclusive: inclusive,
      gstExclusiveSales: exclusive.taxableValue,
      gstInclusiveSales: inclusive.taxableValue,
      taxableSales: _sum(invoices, (row) => row.taxableAmount),
      cgstAmount: _sum(invoices, (row) => row.cgstAmount),
      sgstAmount: _sum(invoices, (row) => row.sgstAmount),
      igstAmount: _sum(invoices, (row) => row.igstAmount),
      totalGst: _sum(invoices, (row) => row.gstAmount),
      gstInvoiceValue: _sum(invoices, (row) => row.invoiceValue),
      taxReviewSales: segment == GstFilingSegment.b2c
          ? snapshot.dashboard.nonGstSalesEstimate
          : 0,
    );
  }

  static List<GstRateSummaryRow> _buildRateSummary(
    List<GstInvoiceRow> invoices,
  ) {
    final accumulators = <String, _RateAccumulator>{};
    for (final invoice in invoices) {
      final rate = invoice.taxableAmount.abs() <= 0.005
          ? 0.0
          : _roundMoney((invoice.gstAmount / invoice.taxableAmount) * 100);
      final key = rate.toStringAsFixed(2);
      final acc = accumulators.putIfAbsent(
        key,
        () => _RateAccumulator(rate: rate),
      );
      acc.invoiceCount++;
      acc.taxableAmount += invoice.taxableAmount;
      acc.cgstAmount += invoice.cgstAmount;
      acc.sgstAmount += invoice.sgstAmount;
      acc.igstAmount += invoice.igstAmount;
      acc.gstAmount += invoice.gstAmount;
      acc.invoiceValue += invoice.invoiceValue;
    }
    return accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) => a.rate.compareTo(b.rate));
  }

  static List<GstAuditFinding> _buildAudit(
    GstReportSnapshot snapshot,
    List<GstInvoiceRow> invoices,
    List<GstHsnSummaryRow> hsnRows,
    GstFilingSegment segment,
  ) {
    final invoiceNumbers = invoices.map((row) => row.invoiceNo).toSet();
    final findings = snapshot.auditFindings.where((finding) {
      if (finding.severity == GstAuditSeverity.info) return false;
      if (finding.invoiceNo.isNotEmpty) {
        return invoiceNumbers.contains(finding.invoiceNo);
      }
      return finding.title == 'Shop GSTIN Missing' ||
          finding.message.startsWith(segment.code);
    }).toList(growable: true);

    if (findings.isEmpty) {
      findings.add(GstAuditFinding(
        severity: GstAuditSeverity.info,
        title: '${segment.title} Checks Clear',
        message: 'No ${segment.title} filing blockers found for this period.',
      ));
    }

    return findings;
  }

  static double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return _roundMoney(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  static double _roundMoney(double amount) => (amount * 100).round() / 100;

  static GstPricingModeSummary _pricingSummary(List<GstInvoiceRow> invoices) {
    return GstPricingModeSummary(
      invoiceCount: invoices.length,
      invoiceValue: _sum(invoices, (row) => row.invoiceValue),
      taxableValue: _sum(invoices, (row) => row.taxableAmount),
      cgstAmount: _sum(invoices, (row) => row.cgstAmount),
      sgstAmount: _sum(invoices, (row) => row.sgstAmount),
      igstAmount: _sum(invoices, (row) => row.igstAmount),
      outputGst: _sum(invoices, (row) => row.gstAmount),
    );
  }
}

extension GstFilingSegmentPresentation on GstFilingSegment {
  String get code {
    switch (this) {
      case GstFilingSegment.b2b:
        return 'B2B';
      case GstFilingSegment.b2c:
        return 'B2C';
    }
  }

  String get title {
    switch (this) {
      case GstFilingSegment.b2b:
        return 'B2B GST Report';
      case GstFilingSegment.b2c:
        return 'B2C GST Report';
    }
  }

  String get subtitle {
    switch (this) {
      case GstFilingSegment.b2b:
        return 'Registered customer invoices, GSTIN checks and IFF-ready view';
      case GstFilingSegment.b2c:
        return 'Consumer invoices, place-of-supply and GST inclusive sales view';
    }
  }
}

class _RateAccumulator {
  _RateAccumulator({required this.rate});

  final double rate;
  int invoiceCount = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceValue = 0;

  GstRateSummaryRow toRow() {
    return GstRateSummaryRow(
      rate: rate,
      invoiceCount: invoiceCount,
      taxableAmount: _roundMoney(taxableAmount),
      cgstAmount: _roundMoney(cgstAmount),
      sgstAmount: _roundMoney(sgstAmount),
      igstAmount: _roundMoney(igstAmount),
      gstAmount: _roundMoney(gstAmount),
      invoiceValue: _roundMoney(invoiceValue),
    );
  }

  double _roundMoney(double amount) => (amount * 100).round() / 100;
}
