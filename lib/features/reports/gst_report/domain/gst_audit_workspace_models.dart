import 'gst_report_models.dart';
import 'gstr1_filing_models.dart';
import 'gstr3b_filing_models.dart';

enum GstAuditControlStatus {
  clear,
  review,
  blocked,
}

class GstAuditWorkspaceSnapshot {
  const GstAuditWorkspaceSnapshot({
    required this.criticalCount,
    required this.warningCount,
    required this.passedCount,
    required this.outputGstLiability,
    required this.actionItems,
    required this.controlItems,
    required this.coverageItems,
  });

  factory GstAuditWorkspaceSnapshot.fromReport(GstReportSnapshot snapshot) {
    final gstr1 = Gstr1FilingSnapshot.fromReport(snapshot);
    final gstr3b = Gstr3bFilingSnapshot.fromReport(snapshot);
    final actionItems = _buildActionItems(snapshot, gstr1, gstr3b);
    final controlItems = _buildControlItems(snapshot, gstr1, gstr3b);
    final coverageItems = _buildCoverageItems(snapshot, gstr1, gstr3b);

    return GstAuditWorkspaceSnapshot(
      criticalCount: actionItems
          .where((item) => item.severity == GstAuditSeverity.critical)
          .length,
      warningCount: actionItems
          .where((item) => item.severity == GstAuditSeverity.warning)
          .length,
      passedCount: coverageItems
          .where((item) => item.status == GstAuditControlStatus.clear)
          .length,
      outputGstLiability: snapshot.dashboard.outputGstLiability,
      actionItems: actionItems,
      controlItems: controlItems,
      coverageItems: coverageItems,
    );
  }

  final int criticalCount;
  final int warningCount;
  final int passedCount;
  final double outputGstLiability;
  final List<GstAuditActionItem> actionItems;
  final List<GstAuditControlItem> controlItems;
  final List<GstAuditCoverageItem> coverageItems;

  bool get isReadyForPortal => criticalCount == 0;

  String get portalStatusLabel =>
      isReadyForPortal ? 'Ready for Portal Review' : 'Action Required';

  static List<GstAuditActionItem> _buildActionItems(
    GstReportSnapshot snapshot,
    Gstr1FilingSnapshot gstr1,
    Gstr3bFilingSnapshot gstr3b,
  ) {
    final items = <GstAuditActionItem>[];

    for (final finding in snapshot.auditFindings) {
      if (finding.severity == GstAuditSeverity.info) continue;
      items.add(
        GstAuditActionItem(
          severity: finding.severity,
          title: finding.title,
          message: finding.message,
          invoiceNo: finding.invoiceNo,
          module: _moduleForFinding(finding),
          nextStep: _nextStepForFinding(finding),
        ),
      );
    }

    for (final message in gstr1.readiness.blockers) {
      items.add(
        GstAuditActionItem(
          severity: GstAuditSeverity.critical,
          title: 'GSTR-1 Filing Blocker',
          message: message,
          module: 'GSTR-1',
          nextStep: 'Resolve before exporting outward supply data.',
        ),
      );
    }
    for (final message in gstr1.readiness.warnings) {
      items.add(
        GstAuditActionItem(
          severity: GstAuditSeverity.warning,
          title: 'GSTR-1 Filing Review',
          message: message,
          module: 'GSTR-1',
          nextStep: 'Review before portal upload.',
        ),
      );
    }
    for (final message in gstr3b.readiness.blockers) {
      items.add(
        GstAuditActionItem(
          severity: GstAuditSeverity.critical,
          title: 'GSTR-3B Filing Blocker',
          message: message,
          module: 'GSTR-3B',
          nextStep: 'Resolve before filing tax liability.',
        ),
      );
    }
    for (final message in gstr3b.readiness.warnings) {
      items.add(
        GstAuditActionItem(
          severity: GstAuditSeverity.warning,
          title: 'GSTR-3B Filing Review',
          message: message,
          module: 'GSTR-3B',
          nextStep: 'Confirm on portal before filing.',
        ),
      );
    }

    final deduplicated = <String, GstAuditActionItem>{};
    for (final item in items) {
      final key = [
        item.severity.name,
        item.title,
        item.message,
        item.invoiceNo,
      ].join('|');
      deduplicated.putIfAbsent(key, () => item);
    }

    final result = deduplicated.values.toList(growable: false);
    return [...result]..sort((a, b) {
        final severity = _severityRank(a.severity).compareTo(
          _severityRank(b.severity),
        );
        if (severity != 0) return severity;
        return a.title.compareTo(b.title);
      });
  }

  static List<GstAuditControlItem> _buildControlItems(
    GstReportSnapshot snapshot,
    Gstr1FilingSnapshot gstr1,
    Gstr3bFilingSnapshot gstr3b,
  ) {
    final hasIdentity = snapshot.identity.gstin.trim().length == 15 &&
        snapshot.identity.stateCode.trim().isNotEmpty &&
        snapshot.identity.stateName.trim().isNotEmpty;
    final hsnBlocked = snapshot.hsnSummary.any(
      (row) => row.hsnCode.trim().toUpperCase() == 'UNMAPPED',
    );
    final hasReviewQueue = snapshot.dashboard.nonGstInvoiceCount > 0 ||
        snapshot.dashboard.taxReviewSales > 0.005;
    final invoiceCritical = snapshot.auditFindings.any((finding) {
      if (finding.severity != GstAuditSeverity.critical) return false;
      final title = finding.title.toLowerCase();
      return title.contains('invoice') ||
          title.contains('gst split') ||
          title.contains('quotation');
    });

    return [
      GstAuditControlItem(
        title: 'Business Identity',
        subtitle: hasIdentity
            ? 'Shop GSTIN, state code and state are available.'
            : 'Shop GSTIN or state identity is incomplete.',
        status: hasIdentity
            ? GstAuditControlStatus.clear
            : GstAuditControlStatus.blocked,
        primaryMetric: snapshot.identity.gstin.trim().isEmpty
            ? 'GSTIN Pending'
            : snapshot.identity.gstin.trim(),
        secondaryMetric: snapshot.identity.stateName.trim().isEmpty
            ? 'State Pending'
            : snapshot.identity.stateName.trim(),
      ),
      GstAuditControlItem(
        title: 'Invoice Integrity',
        subtitle: invoiceCritical
            ? 'Invoice snapshot, GST split or total mismatch needs correction.'
            : 'Invoice total, GST split and document type checks are clear.',
        status: invoiceCritical
            ? GstAuditControlStatus.blocked
            : GstAuditControlStatus.clear,
        primaryMetric: '${snapshot.dashboard.gstInvoiceCount} invoices',
        secondaryMetric: 'Outward supply ledger',
      ),
      GstAuditControlItem(
        title: 'GSTR-1 Upload Data',
        subtitle: gstr1.readiness.isPortalReady
            ? 'B2B, B2C, HSN and document summary can be reviewed.'
            : 'Resolve blockers before GSTR-1 export.',
        status: _readinessStatus(
          gstr1.readiness.blockerCount,
          gstr1.readiness.warningCount,
        ),
        primaryMetric: '${gstr1.invoiceCount} records',
        secondaryMetric: '${gstr1.readiness.blockerCount} blockers',
      ),
      GstAuditControlItem(
        title: 'GSTR-3B Liability',
        subtitle: gstr3b.readiness.canFile
            ? 'Output liability is aligned with GST dashboard.'
            : 'GSTR-3B has filing blockers.',
        status: _readinessStatus(
          gstr3b.readiness.blockerCount,
          gstr3b.readiness.warningCount,
        ),
        primaryMetric: '${gstr3b.paymentRows.length} tax heads',
        secondaryMetric: '${gstr3b.readiness.warningCount} reviews',
      ),
      GstAuditControlItem(
        title: 'HSN Table 12',
        subtitle: hsnBlocked
            ? 'One or more outward supply lines are missing HSN.'
            : 'HSN-wise outward summary is available for filing review.',
        status: hsnBlocked
            ? GstAuditControlStatus.blocked
            : GstAuditControlStatus.clear,
        primaryMetric: '${snapshot.hsnSummary.length} rows',
        secondaryMetric: 'B2B/B2C split ready',
      ),
      GstAuditControlItem(
        title: 'Review Queue',
        subtitle: hasReviewQueue
            ? 'Some completed bills still need GST treatment confirmation.'
            : 'No completed sale is waiting for GST classification.',
        status: hasReviewQueue
            ? GstAuditControlStatus.review
            : GstAuditControlStatus.clear,
        primaryMetric: '${snapshot.dashboard.nonGstInvoiceCount} bills',
        secondaryMetric: 'Tax review sales',
      ),
    ];
  }

  static List<GstAuditCoverageItem> _buildCoverageItems(
    GstReportSnapshot snapshot,
    Gstr1FilingSnapshot gstr1,
    Gstr3bFilingSnapshot gstr3b,
  ) {
    final findings = snapshot.auditFindings;
    return [
      _coverage(
        title: 'Shop GSTIN and State',
        clear: snapshot.identity.gstin.trim().length == 15 &&
            snapshot.identity.stateCode.trim().isNotEmpty &&
            snapshot.identity.stateName.trim().isNotEmpty,
        clearNote: 'Legal identity is ready for return filing.',
        issueNote: 'Complete shop GSTIN, state code and state.',
      ),
      _coverage(
        title: 'B2B Customer GSTIN',
        clear: !findings.any(
          (finding) => finding.title == 'Invalid Customer GSTIN',
        ),
        clearNote: 'Registered customer GSTIN checks are clear.',
        issueNote: 'Fix missing or invalid B2B customer GSTIN.',
      ),
      _coverage(
        title: 'Place of Supply',
        clear: !findings.any(
          (finding) => finding.title == 'Missing Place of Supply',
        ),
        clearNote: 'Place-of-supply data is available.',
        issueNote: 'Add place of supply for affected invoices.',
      ),
      _coverage(
        title: 'GST Split',
        clear: !findings.any(
          (finding) => finding.title == 'GST Split Mismatch',
        ),
        clearNote: 'CGST, SGST and IGST split matches output tax.',
        issueNote: 'Correct CGST/SGST/IGST split before filing.',
      ),
      _coverage(
        title: 'Invoice Value Formula',
        clear: !findings.any(
          (finding) => finding.title == 'Invoice Total Mismatch',
        ),
        clearNote: 'Taxable + GST + round-off matches invoice value.',
        issueNote: 'Check round-off and final amount snapshots.',
      ),
      _coverage(
        title: 'HSN Table 12',
        clear: !snapshot.hsnSummary.any(
          (row) => row.hsnCode.trim().toUpperCase() == 'UNMAPPED',
        ),
        clearNote: 'HSN summary is ready for B2B/B2C filing split.',
        issueNote: 'Map missing HSN codes in billed items.',
      ),
      _coverage(
        title: 'GSTR-1 Workspace',
        clear: gstr1.readiness.isPortalReady,
        clearNote: 'GSTR-1 mandatory sections have no blockers.',
        issueNote: 'Open GSTR-1 tab and resolve filing blockers.',
        warning: gstr1.readiness.warningCount > 0,
      ),
      _coverage(
        title: 'GSTR-3B Workspace',
        clear: gstr3b.readiness.canFile,
        clearNote: 'Sales liability can be reviewed for 3B.',
        issueNote: 'Open GSTR-3B tab and resolve blockers.',
        warning: gstr3b.readiness.warningCount > 0,
      ),
    ];
  }

  static GstAuditCoverageItem _coverage({
    required String title,
    required bool clear,
    required String clearNote,
    required String issueNote,
    bool warning = false,
  }) {
    if (!clear) {
      return GstAuditCoverageItem(
        title: title,
        status: GstAuditControlStatus.blocked,
        note: issueNote,
      );
    }
    if (warning) {
      return GstAuditCoverageItem(
        title: title,
        status: GstAuditControlStatus.review,
        note: clearNote,
      );
    }
    return GstAuditCoverageItem(
      title: title,
      status: GstAuditControlStatus.clear,
      note: clearNote,
    );
  }

  static GstAuditControlStatus _readinessStatus(
    int blockerCount,
    int warningCount,
  ) {
    if (blockerCount > 0) return GstAuditControlStatus.blocked;
    if (warningCount > 0) return GstAuditControlStatus.review;
    return GstAuditControlStatus.clear;
  }

  static int _severityRank(GstAuditSeverity severity) {
    switch (severity) {
      case GstAuditSeverity.critical:
        return 0;
      case GstAuditSeverity.warning:
        return 1;
      case GstAuditSeverity.info:
        return 2;
    }
  }

  static String _moduleForFinding(GstAuditFinding finding) {
    final title = finding.title.toLowerCase();
    if (title.contains('shop')) return 'Shop Profile';
    if (title.contains('hsn')) return 'HSN Table 12';
    if (title.contains('customer') || title.contains('place')) {
      return 'Sales Invoice';
    }
    if (title.contains('quotation')) return 'Sales Document';
    if (title.contains('gst split') || title.contains('zero gst')) {
      return 'Invoice Tax Snapshot';
    }
    if (title.contains('total')) return 'Invoice Amount';
    return 'GST Audit';
  }

  static String _nextStepForFinding(GstAuditFinding finding) {
    final title = finding.title.toLowerCase();
    if (title.contains('shop')) {
      return 'Update shop GSTIN and registered state details.';
    }
    if (title.contains('customer')) {
      return 'Open the invoice customer profile and save valid GSTIN.';
    }
    if (title.contains('place')) {
      return 'Set place of supply before export or filing.';
    }
    if (title.contains('zero gst')) {
      return 'Choose GST Exclusive or GST Inclusive treatment.';
    }
    if (title.contains('split')) {
      return 'Recalculate tax split from the invoice snapshot.';
    }
    if (title.contains('total')) {
      return 'Check taxable value, GST amount and round-off.';
    }
    if (title.contains('hsn')) {
      return 'Map HSN code on the billed item master.';
    }
    return 'Review this finding before filing.';
  }
}

class GstAuditActionItem {
  const GstAuditActionItem({
    required this.severity,
    required this.title,
    required this.message,
    required this.module,
    required this.nextStep,
    this.invoiceNo = '',
  });

  final GstAuditSeverity severity;
  final String title;
  final String message;
  final String module;
  final String nextStep;
  final String invoiceNo;
}

class GstAuditControlItem {
  const GstAuditControlItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.primaryMetric,
    required this.secondaryMetric,
  });

  final String title;
  final String subtitle;
  final GstAuditControlStatus status;
  final String primaryMetric;
  final String secondaryMetric;
}

class GstAuditCoverageItem {
  const GstAuditCoverageItem({
    required this.title,
    required this.status,
    required this.note,
  });

  final String title;
  final GstAuditControlStatus status;
  final String note;
}
