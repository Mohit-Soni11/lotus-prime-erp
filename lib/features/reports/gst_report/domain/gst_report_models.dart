enum GstReportTab {
  dashboard,
  gstr1,
  gstr3b,
  hsnRegister,
  audit,
}

enum GstAuditSeverity {
  critical,
  warning,
  info,
}

enum GstFilingSegment {
  b2b,
  b2c,
}

enum GstFilingTask {
  monthlyTaxPayment,
  b2bIffUpload,
  b2bReturnFiled,
  b2cReturnFiled,
  quarterReturnFiled,
}

extension GstFilingTaskMetadata on GstFilingTask {
  String get storageKey {
    switch (this) {
      case GstFilingTask.monthlyTaxPayment:
        return 'monthly_tax_payment';
      case GstFilingTask.b2bIffUpload:
        return 'b2b_iff_upload';
      case GstFilingTask.b2bReturnFiled:
        return 'b2b_return_filed';
      case GstFilingTask.b2cReturnFiled:
        return 'b2c_return_filed';
      case GstFilingTask.quarterReturnFiled:
        return 'quarter_return_filed';
    }
  }

  String get segmentKey {
    switch (this) {
      case GstFilingTask.b2bIffUpload:
      case GstFilingTask.b2bReturnFiled:
        return 'B2B';
      case GstFilingTask.b2cReturnFiled:
        return 'B2C';
      case GstFilingTask.monthlyTaxPayment:
      case GstFilingTask.quarterReturnFiled:
        return '';
    }
  }

  static GstFilingTask? fromStorageKey(String value) {
    for (final task in GstFilingTask.values) {
      if (task.storageKey == value) return task;
    }
    return null;
  }
}

class GstFilingTaskStatus {
  const GstFilingTaskStatus({
    required this.task,
    required this.periodMonth,
    required this.quarterKey,
    required this.quarterLabel,
    this.amountSnapshot = 0,
    this.invoiceCountSnapshot = 0,
    this.portalReference = '',
    this.cpin = '',
    this.cin = '',
    this.paymentMode = '',
    this.notes = '',
    this.completed = false,
    this.completedAt,
  });

  factory GstFilingTaskStatus.empty({
    required GstFilingTask task,
    required DateTime periodMonth,
    required String quarterKey,
    required String quarterLabel,
  }) {
    return GstFilingTaskStatus(
      task: task,
      periodMonth: periodMonth,
      quarterKey: quarterKey,
      quarterLabel: quarterLabel,
    );
  }

  final GstFilingTask task;
  final DateTime periodMonth;
  final String quarterKey;
  final String quarterLabel;
  final double amountSnapshot;
  final int invoiceCountSnapshot;
  final String portalReference;
  final String cpin;
  final String cin;
  final String paymentMode;
  final String notes;
  final bool completed;
  final DateTime? completedAt;
}

class GstFilingWorkflowSnapshot {
  const GstFilingWorkflowSnapshot({
    required this.periodMonth,
    required this.quarterKey,
    required this.quarterLabel,
    required this.statuses,
    required this.completedQuarterKeys,
  });

  factory GstFilingWorkflowSnapshot.empty({
    required DateTime periodMonth,
    required String quarterKey,
    required String quarterLabel,
  }) {
    return GstFilingWorkflowSnapshot(
      periodMonth: periodMonth,
      quarterKey: quarterKey,
      quarterLabel: quarterLabel,
      statuses: {
        for (final task in GstFilingTask.values)
          task: GstFilingTaskStatus.empty(
            task: task,
            periodMonth: periodMonth,
            quarterKey: quarterKey,
            quarterLabel: quarterLabel,
          ),
      },
      completedQuarterKeys: const {},
    );
  }

  final DateTime periodMonth;
  final String quarterKey;
  final String quarterLabel;
  final Map<GstFilingTask, GstFilingTaskStatus> statuses;
  final Set<String> completedQuarterKeys;

  GstFilingTaskStatus statusFor(GstFilingTask task) {
    return statuses[task] ??
        GstFilingTaskStatus.empty(
          task: task,
          periodMonth: periodMonth,
          quarterKey: quarterKey,
          quarterLabel: quarterLabel,
        );
  }

  bool isTaskComplete(GstFilingTask task) => statusFor(task).completed;

  bool isQuarterComplete(String key) => completedQuarterKeys.contains(key);
}

class GstReportPeriod {
  const GstReportPeriod({
    required this.startDate,
    required this.endDate,
  });

  factory GstReportPeriod.currentMonth() {
    final now = DateTime.now();
    return GstReportPeriod.forMonth(DateTime(now.year, now.month));
  }

  factory GstReportPeriod.forMonth(DateTime month) {
    return GstReportPeriod(
      startDate: DateTime(month.year, month.month),
      endDate: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
    );
  }

  final DateTime startDate;
  final DateTime endDate;

  DateTime get month => DateTime(startDate.year, startDate.month);
}

class GstReportShopIdentity {
  const GstReportShopIdentity({
    this.shopName = 'Lotus ERP',
    this.gstin = '',
    this.stateCode = '',
    this.stateName = '',
    this.configuredStateName = '',
  });

  final String shopName;
  final String gstin;
  final String stateCode;
  final String stateName;
  final String configuredStateName;

  bool get hasStateMismatch {
    final registered = _normalizeStateName(stateName);
    final configured = _normalizeStateName(configuredStateName);
    return registered.isNotEmpty &&
        configured.isNotEmpty &&
        registered != configured;
  }
}

class GstReportDashboardSummary {
  const GstReportDashboardSummary({
    this.totalInvoices = 0,
    this.gstInvoiceCount = 0,
    this.nonGstInvoiceCount = 0,
    this.exclusive = const GstPricingModeSummary(),
    this.inclusive = const GstPricingModeSummary(),
    this.gstExclusiveSales = 0,
    this.gstInclusiveSales = 0,
    this.taxableSales = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.totalGst = 0,
    this.gstInvoiceValue = 0,
    double? taxReviewSales,
    double? nonGstSalesEstimate,
  }) : taxReviewSales = taxReviewSales ?? nonGstSalesEstimate ?? 0;

  final int totalInvoices;
  final int gstInvoiceCount;
  final int nonGstInvoiceCount;
  final GstPricingModeSummary exclusive;
  final GstPricingModeSummary inclusive;
  final double gstExclusiveSales;
  final double gstInclusiveSales;
  final double taxableSales;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalGst;
  final double gstInvoiceValue;
  final double taxReviewSales;

  double get outputGstLiability => totalGst;
  double get nonGstSalesEstimate => taxReviewSales;
}

class GstPricingModeSummary {
  const GstPricingModeSummary({
    this.invoiceCount = 0,
    this.invoiceValue = 0,
    this.taxableValue = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.outputGst = 0,
  });

  final int invoiceCount;
  final double invoiceValue;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double outputGst;
}

class GstInvoiceRow {
  const GstInvoiceRow({
    required this.billId,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.customerName,
    required this.customerGstin,
    required this.placeOfSupply,
    this.customerStateCode = '',
    this.placeOfSupplyStateCode = '',
    this.shopStateCode = '',
    this.supplyType = 'INTRA_STATE',
    required this.billType,
    this.gstPricingMode = 'GST_EXCLUSIVE',
    this.documentType = 'TAX_INVOICE',
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.roundOffAmount,
    required this.invoiceValue,
    required this.isGst,
  });

  final int billId;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String customerName;
  final String customerGstin;
  final String placeOfSupply;
  final String customerStateCode;
  final String placeOfSupplyStateCode;
  final String shopStateCode;
  final String supplyType;
  final String billType;
  final String gstPricingMode;
  final String documentType;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double roundOffAmount;
  final double invoiceValue;
  final bool isGst;

  bool get isB2B => customerGstin.trim().isNotEmpty;
}

class GstHsnSummaryRow {
  const GstHsnSummaryRow({
    required this.hsnCode,
    required this.description,
    required this.gstRate,
    required this.invoiceType,
    required this.invoiceCount,
    required this.lineCount,
    required this.quantity,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.invoiceValue,
  });

  final String hsnCode;
  final String description;
  final double gstRate;
  final String invoiceType;
  final int invoiceCount;
  final int lineCount;
  final int quantity;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double invoiceValue;
}

class GstRateSummaryRow {
  const GstRateSummaryRow({
    required this.rate,
    required this.invoiceCount,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.invoiceValue,
  });

  final double rate;
  final int invoiceCount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double invoiceValue;
}

class Gstr3bSummary {
  const Gstr3bSummary({
    this.outwardTaxableValue = 0,
    this.outwardCgst = 0,
    this.outwardSgst = 0,
    this.outwardIgst = 0,
    this.nilExemptNonGstValue = 0,
  });

  final double outwardTaxableValue;
  final double outwardCgst;
  final double outwardSgst;
  final double outwardIgst;
  final double nilExemptNonGstValue;

  double get netTaxPayable => outwardCgst + outwardSgst + outwardIgst;
}

class GstAuditFinding {
  const GstAuditFinding({
    required this.severity,
    required this.title,
    required this.message,
    this.invoiceNo = '',
  });

  final GstAuditSeverity severity;
  final String title;
  final String message;
  final String invoiceNo;
}

class GstReportSnapshot {
  const GstReportSnapshot({
    required this.period,
    required this.identity,
    required this.dashboard,
    required this.gstr1B2bInvoices,
    required this.gstr1B2cInvoices,
    required this.hsnSummary,
    required this.rateSummary,
    required this.gstr3b,
    required this.auditFindings,
  });

  factory GstReportSnapshot.empty(GstReportPeriod period) {
    return GstReportSnapshot(
      period: period,
      identity: const GstReportShopIdentity(),
      dashboard: const GstReportDashboardSummary(),
      gstr1B2bInvoices: const [],
      gstr1B2cInvoices: const [],
      hsnSummary: const [],
      rateSummary: const [],
      gstr3b: const Gstr3bSummary(),
      auditFindings: const [],
    );
  }

  final GstReportPeriod period;
  final GstReportShopIdentity identity;
  final GstReportDashboardSummary dashboard;
  final List<GstInvoiceRow> gstr1B2bInvoices;
  final List<GstInvoiceRow> gstr1B2cInvoices;
  final List<GstHsnSummaryRow> hsnSummary;
  final List<GstRateSummaryRow> rateSummary;
  final Gstr3bSummary gstr3b;
  final List<GstAuditFinding> auditFindings;

  List<GstInvoiceRow> get gstInvoices => [
        ...gstr1B2bInvoices,
        ...gstr1B2cInvoices,
      ];
}

String _normalizeStateName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
