import 'gst_report_models.dart';

class Gstr1FilingSnapshot {
  const Gstr1FilingSnapshot({
    required this.b2bInvoices,
    required this.b2cLargeInvoices,
    required this.b2cSmallSummary,
    required this.hsnB2bSummary,
    required this.hsnB2cSummary,
    required this.documentSummary,
    required this.readiness,
  });

  factory Gstr1FilingSnapshot.fromReport(GstReportSnapshot snapshot) {
    final b2cLarge = snapshot.gstr1B2cInvoices.where((invoice) {
      return _isB2cLarge(
        invoice: invoice,
        identity: snapshot.identity,
        period: snapshot.period,
      );
    }).toList(growable: false);
    final b2cLargeIds = b2cLarge.map((invoice) => invoice.billId).toSet();
    final b2cSmall = snapshot.gstr1B2cInvoices.where((invoice) {
      return !b2cLargeIds.contains(invoice.billId);
    }).toList(growable: false);

    final filing = Gstr1FilingSnapshot(
      b2bInvoices: snapshot.gstr1B2bInvoices,
      b2cLargeInvoices: b2cLarge,
      b2cSmallSummary: _buildB2cSmallSummary(b2cSmall),
      hsnB2bSummary: snapshot.hsnSummary
          .where((row) => row.invoiceType.trim().toUpperCase() == 'B2B')
          .toList(growable: false),
      hsnB2cSummary: snapshot.hsnSummary
          .where((row) => row.invoiceType.trim().toUpperCase() == 'B2C')
          .toList(growable: false),
      documentSummary: _buildDocumentSummary(snapshot.gstInvoices),
      readiness: Gstr1Readiness.empty,
    );

    return Gstr1FilingSnapshot(
      b2bInvoices: filing.b2bInvoices,
      b2cLargeInvoices: filing.b2cLargeInvoices,
      b2cSmallSummary: filing.b2cSmallSummary,
      hsnB2bSummary: filing.hsnB2bSummary,
      hsnB2cSummary: filing.hsnB2cSummary,
      documentSummary: filing.documentSummary,
      readiness: _buildReadiness(snapshot, filing),
    );
  }

  final List<GstInvoiceRow> b2bInvoices;
  final List<GstInvoiceRow> b2cLargeInvoices;
  final List<Gstr1B2cSmallSummaryRow> b2cSmallSummary;
  final List<GstHsnSummaryRow> hsnB2bSummary;
  final List<GstHsnSummaryRow> hsnB2cSummary;
  final List<Gstr1DocumentSummaryRow> documentSummary;
  final Gstr1Readiness readiness;

  int get invoiceCount =>
      b2bInvoices.length +
      b2cLargeInvoices.length +
      b2cSmallSummary.fold<int>(0, (total, row) => total + row.invoiceCount);

  double get taxableValue => _roundMoney(
        _sum(b2bInvoices, (row) => row.taxableAmount) +
            _sum(b2cLargeInvoices, (row) => row.taxableAmount) +
            b2cSmallSummary.fold<double>(
              0,
              (total, row) => total + row.taxableValue,
            ),
      );

  double get outputGst => _roundMoney(
        _sum(b2bInvoices, (row) => row.gstAmount) +
            _sum(b2cLargeInvoices, (row) => row.gstAmount) +
            b2cSmallSummary.fold<double>(
              0,
              (total, row) => total + row.outputGst,
            ),
      );

  static List<Gstr1B2cSmallSummaryRow> _buildB2cSmallSummary(
    List<GstInvoiceRow> invoices,
  ) {
    final accumulators = <String, _B2cSmallAccumulator>{};
    for (final invoice in invoices) {
      final rate = _invoiceRate(invoice);
      final place = invoice.placeOfSupply.trim().isEmpty
          ? 'Place of supply pending'
          : invoice.placeOfSupply.trim();
      final placeStateCode = invoice.placeOfSupplyStateCode.trim();
      final supplyType =
          invoice.supplyType == 'INTER_STATE' ? 'Inter-State' : 'Intra-State';
      final key =
          '$placeStateCode|$place|$supplyType|${rate.toStringAsFixed(2)}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _B2cSmallAccumulator(
          placeOfSupply: place,
          placeOfSupplyStateCode: placeStateCode,
          supplyType: supplyType,
          rate: rate,
        ),
      );
      acc.invoiceCount++;
      acc.taxableValue += invoice.taxableAmount;
      acc.cgstAmount += invoice.cgstAmount;
      acc.sgstAmount += invoice.sgstAmount;
      acc.igstAmount += invoice.igstAmount;
      acc.outputGst += invoice.gstAmount;
      acc.invoiceValue += invoice.invoiceValue;
    }
    return accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final place = a.placeOfSupply.compareTo(b.placeOfSupply);
        if (place != 0) return place;
        return a.rate.compareTo(b.rate);
      });
  }

  static List<Gstr1DocumentSummaryRow> _buildDocumentSummary(
    List<GstInvoiceRow> invoices,
  ) {
    if (invoices.isEmpty) return const [];
    final sorted = [...invoices]
      ..sort((a, b) => a.invoiceNo.compareTo(b.invoiceNo));
    return [
      Gstr1DocumentSummaryRow(
        documentType: 'Tax Invoice',
        fromNumber: sorted.first.invoiceNo,
        toNumber: sorted.last.invoiceNo,
        totalIssued: sorted.length,
        cancelled: 0,
      ),
      const Gstr1DocumentSummaryRow(
        documentType: 'Credit Note',
        fromNumber: 'Not issued',
        toNumber: 'Not issued',
        totalIssued: 0,
        cancelled: 0,
      ),
      const Gstr1DocumentSummaryRow(
        documentType: 'Debit Note',
        fromNumber: 'Not issued',
        toNumber: 'Not issued',
        totalIssued: 0,
        cancelled: 0,
      ),
    ];
  }

  static Gstr1Readiness _buildReadiness(
    GstReportSnapshot snapshot,
    Gstr1FilingSnapshot filing,
  ) {
    final blockers = <String>[];
    final warnings = <String>[];

    if (snapshot.identity.gstin.trim().length != 15) {
      blockers.add('Shop GSTIN is missing or invalid.');
    }
    if (snapshot.identity.stateCode.trim().isEmpty ||
        snapshot.identity.stateName.trim().isEmpty) {
      blockers.add('Shop state identity is incomplete.');
    }
    for (final invoice in snapshot.gstr1B2bInvoices) {
      if (invoice.customerGstin.trim().length != 15) {
        blockers.add('B2B invoice ${invoice.invoiceNo} has invalid GSTIN.');
      }
    }
    for (final invoice in snapshot.gstInvoices) {
      if (invoice.placeOfSupply.trim().isEmpty) {
        blockers.add('Invoice ${invoice.invoiceNo} has no place of supply.');
      }
    }
    if (filing.hsnB2bSummary.any((row) => row.hsnCode == 'UNMAPPED') ||
        filing.hsnB2cSummary.any((row) => row.hsnCode == 'UNMAPPED')) {
      blockers.add('One or more invoice items are missing HSN codes.');
    }
    if (snapshot.dashboard.nonGstSalesEstimate > 0.005) {
      warnings.add('Some completed sales are still in review queue.');
    }
    if (filing.b2cLargeInvoices.isNotEmpty) {
      warnings.add(
        '${filing.b2cLargeInvoices.length} B2C Large invoices must be reported invoice-wise.',
      );
    }
    if (filing.documentSummary.isEmpty && snapshot.gstInvoices.isNotEmpty) {
      blockers.add('Document issued summary could not be prepared.');
    }

    return Gstr1Readiness(
      blockerCount: blockers.length,
      warningCount: warnings.length,
      blockers: blockers,
      warnings: warnings,
    );
  }

  static bool _isB2cLarge({
    required GstInvoiceRow invoice,
    required GstReportShopIdentity identity,
    required GstReportPeriod period,
  }) {
    if (invoice.isB2B) return false;
    if (invoice.invoiceValue <= _b2cLargeThreshold(period)) return false;
    if (invoice.placeOfSupplyStateCode.isNotEmpty &&
        invoice.shopStateCode.isNotEmpty) {
      return invoice.placeOfSupplyStateCode != invoice.shopStateCode;
    }
    final place = _normalize(invoice.placeOfSupply);
    final shopState = _normalize(identity.stateName);
    if (place.isEmpty || shopState.isEmpty) return false;
    return place != shopState;
  }

  static double _b2cLargeThreshold(GstReportPeriod period) {
    final effectiveMonth = DateTime(2024, 8);
    return period.month.isBefore(effectiveMonth) ? 250000 : 100000;
  }

  static double _invoiceRate(GstInvoiceRow invoice) {
    if (invoice.taxableAmount.abs() <= 0.005) return 0;
    return _roundMoney((invoice.gstAmount / invoice.taxableAmount) * 100);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static double _sum(
    List<GstInvoiceRow> rows,
    double Function(GstInvoiceRow row) selector,
  ) {
    return _roundMoney(
      rows.fold<double>(0, (total, row) => total + selector(row)),
    );
  }
}

class Gstr1B2cSmallSummaryRow {
  const Gstr1B2cSmallSummaryRow({
    required this.placeOfSupply,
    this.placeOfSupplyStateCode = '',
    required this.supplyType,
    required this.rate,
    required this.invoiceCount,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.outputGst,
    required this.invoiceValue,
  });

  final String placeOfSupply;
  final String placeOfSupplyStateCode;
  final String supplyType;
  final double rate;
  final int invoiceCount;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double outputGst;
  final double invoiceValue;
}

class Gstr1DocumentSummaryRow {
  const Gstr1DocumentSummaryRow({
    required this.documentType,
    required this.fromNumber,
    required this.toNumber,
    required this.totalIssued,
    required this.cancelled,
  });

  final String documentType;
  final String fromNumber;
  final String toNumber;
  final int totalIssued;
  final int cancelled;

  int get netIssued => totalIssued - cancelled;
}

class Gstr1Readiness {
  const Gstr1Readiness({
    required this.blockerCount,
    required this.warningCount,
    required this.blockers,
    required this.warnings,
  });

  static const empty = Gstr1Readiness(
    blockerCount: 0,
    warningCount: 0,
    blockers: [],
    warnings: [],
  );

  final int blockerCount;
  final int warningCount;
  final List<String> blockers;
  final List<String> warnings;

  bool get isPortalReady => blockerCount == 0;
}

class _B2cSmallAccumulator {
  _B2cSmallAccumulator({
    required this.placeOfSupply,
    required this.placeOfSupplyStateCode,
    required this.supplyType,
    required this.rate,
  });

  final String placeOfSupply;
  final String placeOfSupplyStateCode;
  final String supplyType;
  final double rate;
  int invoiceCount = 0;
  double taxableValue = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double outputGst = 0;
  double invoiceValue = 0;

  Gstr1B2cSmallSummaryRow toRow() {
    return Gstr1B2cSmallSummaryRow(
      placeOfSupply: placeOfSupply,
      placeOfSupplyStateCode: placeOfSupplyStateCode,
      supplyType: supplyType,
      rate: rate,
      invoiceCount: invoiceCount,
      taxableValue: _roundMoney(taxableValue),
      cgstAmount: _roundMoney(cgstAmount),
      sgstAmount: _roundMoney(sgstAmount),
      igstAmount: _roundMoney(igstAmount),
      outputGst: _roundMoney(outputGst),
      invoiceValue: _roundMoney(invoiceValue),
    );
  }
}

double _roundMoney(double value) => (value * 100).round() / 100;
