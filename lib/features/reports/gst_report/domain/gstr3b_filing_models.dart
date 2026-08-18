import 'gst_report_models.dart';

class Gstr3bFilingSnapshot {
  const Gstr3bFilingSnapshot({
    required this.table31Rows,
    required this.table32Rows,
    required this.itcRows,
    required this.exemptInwardRows,
    required this.paymentRows,
    required this.portalNotes,
    required this.readiness,
  });

  factory Gstr3bFilingSnapshot.fromReport(GstReportSnapshot snapshot) {
    final table31Rows = _buildTable31Rows(snapshot);
    final table32Rows = _buildTable32Rows(snapshot);
    final itcRows = _buildItcRows();
    final paymentRows = _buildPaymentRows(snapshot);
    final filing = Gstr3bFilingSnapshot(
      table31Rows: table31Rows,
      table32Rows: table32Rows,
      itcRows: itcRows,
      exemptInwardRows: _buildExemptInwardRows(),
      paymentRows: paymentRows,
      portalNotes: _buildPortalNotes(),
      readiness: Gstr3bReadiness.empty,
    );

    return Gstr3bFilingSnapshot(
      table31Rows: filing.table31Rows,
      table32Rows: filing.table32Rows,
      itcRows: filing.itcRows,
      exemptInwardRows: filing.exemptInwardRows,
      paymentRows: filing.paymentRows,
      portalNotes: filing.portalNotes,
      readiness: _buildReadiness(snapshot, filing),
    );
  }

  final List<Gstr3bTaxRow> table31Rows;
  final List<Gstr3bInterStateRow> table32Rows;
  final List<Gstr3bItcRow> itcRows;
  final List<Gstr3bExemptInwardRow> exemptInwardRows;
  final List<Gstr3bPaymentRow> paymentRows;
  final List<Gstr3bPortalVerificationNote> portalNotes;
  final Gstr3bReadiness readiness;

  double get outwardTaxableValue => _roundMoney(
        table31Rows
            .where((row) => row.code == '3.1(a)')
            .fold<double>(0, (total, row) => total + row.taxableValue),
      );

  double get outputTax => _roundMoney(
        table31Rows.fold<double>(0, (total, row) => total + row.totalTax),
      );

  double get netCashPayable => _roundMoney(
        paymentRows.fold<double>(0, (total, row) => total + row.cashPayable),
      );

  static List<Gstr3bTaxRow> _buildTable31Rows(GstReportSnapshot snapshot) {
    final summary = snapshot.gstr3b;
    return [
      Gstr3bTaxRow(
        code: '3.1(a)',
        title: 'Outward Taxable Supplies',
        note: 'Other than zero-rated, nil-rated and exempted supplies',
        taxableValue: summary.outwardTaxableValue,
        igst: summary.outwardIgst,
        cgst: summary.outwardCgst,
        sgst: summary.outwardSgst,
      ),
      const Gstr3bTaxRow(
        code: '3.1(b)',
        title: 'Zero-Rated Outward Supplies',
        note: 'Exports and SEZ supplies',
      ),
      Gstr3bTaxRow(
        code: '3.1(c)',
        title: 'Nil / Exempt Outward Supplies',
        note: 'Taxable value only, no tax payable',
        taxableValue: summary.nilExemptNonGstValue,
      ),
      const Gstr3bTaxRow(
        code: '3.1(d)',
        title: 'Inward Supplies Liable to RCM',
        note: 'Reverse charge purchases and expenses',
      ),
      const Gstr3bTaxRow(
        code: '3.1(e)',
        title: 'Non-GST Outward Supplies',
        note: 'Only real non-GST outward supply, not GST-inclusive sales',
      ),
    ];
  }

  static List<Gstr3bInterStateRow> _buildTable32Rows(
    GstReportSnapshot snapshot,
  ) {
    final accumulators = <String, _InterStateAccumulator>{};
    for (final invoice in snapshot.gstr1B2cInvoices) {
      if (invoice.supplyType != 'INTER_STATE' || invoice.igstAmount <= 0.005) {
        continue;
      }
      final place = invoice.placeOfSupply.trim().isEmpty
          ? 'Place of supply pending'
          : invoice.placeOfSupply.trim();
      final acc = accumulators.putIfAbsent(
        place,
        () => _InterStateAccumulator(placeOfSupply: place),
      );
      acc.taxableValue += invoice.taxableAmount;
      acc.igst += invoice.igstAmount;
    }
    return accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) => a.placeOfSupply.compareTo(b.placeOfSupply));
  }

  static List<Gstr3bItcRow> _buildItcRows() {
    return const [
      Gstr3bItcRow(
        section: '4(A)(1)',
        title: 'Import of Goods',
        status: 'Pending GSTR-2B / Purchase integration',
      ),
      Gstr3bItcRow(
        section: '4(A)(2)',
        title: 'Import of Services',
        status: 'Pending GSTR-2B / Purchase integration',
      ),
      Gstr3bItcRow(
        section: '4(A)(3)',
        title: 'Inward Supplies Liable to RCM',
        status: 'Pending reverse charge purchase tagging',
      ),
      Gstr3bItcRow(
        section: '4(A)(4)',
        title: 'Inward Supplies from ISD',
        status: 'Not configured',
      ),
      Gstr3bItcRow(
        section: '4(A)(5)',
        title: 'All Other ITC',
        status: 'Pending Purchase Report + GSTR-2B reconciliation',
      ),
      Gstr3bItcRow(
        section: '4(B)',
        title: 'ITC Reversed',
        status: 'Pending reversal rules',
      ),
      Gstr3bItcRow(
        section: '4(C)',
        title: 'Net ITC Available',
        status: 'Locked until purchase ITC is live',
      ),
      Gstr3bItcRow(
        section: '4(D)',
        title: 'Ineligible ITC',
        status: 'Pending GSTR-2B classification',
      ),
    ];
  }

  static List<Gstr3bExemptInwardRow> _buildExemptInwardRows() {
    return const [
      Gstr3bExemptInwardRow(
        title: 'From Composition Taxable Persons',
        interStateValue: 0,
        intraStateValue: 0,
        status: 'Pending purchase classification',
      ),
      Gstr3bExemptInwardRow(
        title: 'Nil-Rated / Exempt Inward Supplies',
        interStateValue: 0,
        intraStateValue: 0,
        status: 'Pending purchase classification',
      ),
      Gstr3bExemptInwardRow(
        title: 'Non-GST Inward Supplies',
        interStateValue: 0,
        intraStateValue: 0,
        status: 'Pending purchase classification',
      ),
    ];
  }

  static List<Gstr3bPaymentRow> _buildPaymentRows(GstReportSnapshot snapshot) {
    final summary = snapshot.gstr3b;
    return [
      Gstr3bPaymentRow(
        taxHead: 'IGST',
        taxPayable: summary.outwardIgst,
        itcAvailable: 0,
      ),
      Gstr3bPaymentRow(
        taxHead: 'CGST',
        taxPayable: summary.outwardCgst,
        itcAvailable: 0,
      ),
      Gstr3bPaymentRow(
        taxHead: 'SGST',
        taxPayable: summary.outwardSgst,
        itcAvailable: 0,
      ),
      const Gstr3bPaymentRow(
        taxHead: 'Cess',
        taxPayable: 0,
        itcAvailable: 0,
      ),
    ];
  }

  static List<Gstr3bPortalVerificationNote> _buildPortalNotes() {
    return const [
      Gstr3bPortalVerificationNote(
        title: 'Purchase ITC / GSTR-2B',
        whenRequired:
            'Required only when purchase invoices or supplier ITC are available.',
        portalAction:
            'Open GSTR-2B, verify supplier-uploaded invoices, then enter eligible ITC in Table 4.',
        erpStatus:
            'ERP will automate this after Purchase Report and GSTR-2B reconciliation are connected.',
      ),
      Gstr3bPortalVerificationNote(
        title: 'Interest, Late Fee and Ledger Balance',
        whenRequired:
            'Required during final filing, especially when return/payment is late or ledger balance differs.',
        portalAction:
            'Confirm GST portal cash ledger, credit ledger, interest, late fee and challan adjustment before filing.',
        erpStatus:
            'This is portal-side verification and is not counted as an ERP audit blocker.',
      ),
    ];
  }

  static Gstr3bReadiness _buildReadiness(
    GstReportSnapshot snapshot,
    Gstr3bFilingSnapshot filing,
  ) {
    final blockers = <String>[];
    final warnings = <String>[];
    final outputGst = _roundMoney(snapshot.dashboard.totalGst);
    final table31Tax = _roundMoney(
      filing.table31Rows
          .where((row) => row.code == '3.1(a)')
          .fold<double>(0, (total, row) => total + row.totalTax),
    );

    if ((outputGst - table31Tax).abs() > 0.01) {
      blockers.add('GSTR-3B output tax does not match GST dashboard.');
    }
    if (snapshot.auditFindings.any(
      (finding) => finding.severity == GstAuditSeverity.critical,
    )) {
      blockers.add('Critical GST audit issues are still open.');
    }
    if (snapshot.identity.gstin.trim().length != 15) {
      blockers.add('Shop GSTIN is missing or invalid.');
    }
    if (snapshot.dashboard.nonGstSalesEstimate > 0.005) {
      warnings.add('Review queue has sales that need GST treatment check.');
    }

    return Gstr3bReadiness(
      blockerCount: blockers.length,
      warningCount: warnings.length,
      blockers: blockers,
      warnings: warnings,
    );
  }
}

class Gstr3bTaxRow {
  const Gstr3bTaxRow({
    required this.code,
    required this.title,
    required this.note,
    this.taxableValue = 0,
    this.igst = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.cess = 0,
  });

  final String code;
  final String title;
  final String note;
  final double taxableValue;
  final double igst;
  final double cgst;
  final double sgst;
  final double cess;

  double get totalTax => _roundMoney(igst + cgst + sgst + cess);
}

class Gstr3bInterStateRow {
  const Gstr3bInterStateRow({
    required this.placeOfSupply,
    required this.taxableValue,
    required this.igst,
  });

  final String placeOfSupply;
  final double taxableValue;
  final double igst;
}

class Gstr3bItcRow {
  const Gstr3bItcRow({
    required this.section,
    required this.title,
    required this.status,
    this.igst = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.cess = 0,
  });

  final String section;
  final String title;
  final String status;
  final double igst;
  final double cgst;
  final double sgst;
  final double cess;
}

class Gstr3bExemptInwardRow {
  const Gstr3bExemptInwardRow({
    required this.title,
    required this.interStateValue,
    required this.intraStateValue,
    required this.status,
  });

  final String title;
  final double interStateValue;
  final double intraStateValue;
  final String status;
}

class Gstr3bPaymentRow {
  const Gstr3bPaymentRow({
    required this.taxHead,
    required this.taxPayable,
    required this.itcAvailable,
    this.interest = 0,
    this.lateFee = 0,
  });

  final String taxHead;
  final double taxPayable;
  final double itcAvailable;
  final double interest;
  final double lateFee;

  double get cashPayable => _roundMoney(
        (taxPayable - itcAvailable) < 0 ? 0 : taxPayable - itcAvailable,
      );
}

class Gstr3bPortalVerificationNote {
  const Gstr3bPortalVerificationNote({
    required this.title,
    required this.whenRequired,
    required this.portalAction,
    required this.erpStatus,
  });

  final String title;
  final String whenRequired;
  final String portalAction;
  final String erpStatus;
}

class Gstr3bReadiness {
  const Gstr3bReadiness({
    required this.blockerCount,
    required this.warningCount,
    required this.blockers,
    required this.warnings,
  });

  static const empty = Gstr3bReadiness(
    blockerCount: 0,
    warningCount: 0,
    blockers: [],
    warnings: [],
  );

  final int blockerCount;
  final int warningCount;
  final List<String> blockers;
  final List<String> warnings;

  bool get canFile => blockerCount == 0;
}

class _InterStateAccumulator {
  _InterStateAccumulator({required this.placeOfSupply});

  final String placeOfSupply;
  double taxableValue = 0;
  double igst = 0;

  Gstr3bInterStateRow toRow() {
    return Gstr3bInterStateRow(
      placeOfSupply: placeOfSupply,
      taxableValue: _roundMoney(taxableValue),
      igst: _roundMoney(igst),
    );
  }
}

double _roundMoney(double value) => (value * 100).round() / 100;
