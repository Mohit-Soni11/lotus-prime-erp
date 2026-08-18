import 'gst_filing_period.dart';
import 'gst_report_models.dart';

class GstQuarterFilingLedger {
  const GstQuarterFilingLedger({
    required this.filing,
    required this.months,
    required this.quarterReturnStatus,
    required this.quarterTaxLiability,
    required this.quarterInvoiceCount,
  });

  final GstFilingPeriod filing;
  final List<GstQuarterFilingMonthLedger> months;
  final GstFilingTaskStatus quarterReturnStatus;
  final double quarterTaxLiability;
  final int quarterInvoiceCount;

  double get paidTaxSnapshot {
    return months.fold<double>(
      0,
      (total, month) =>
          total +
          (month.monthlyPaymentStatus.completed
              ? month.monthlyPaymentStatus.amountSnapshot
              : 0),
    );
  }

  double get monthlyTaxLiability {
    return months.fold<double>(
      0,
      (total, month) =>
          total + (month.hasMonthlyPayment ? month.taxLiability : 0),
    );
  }

  GstQuarterFilingMonthLedger get closingMonth {
    return months.firstWhere(
      (month) => month.filing.isQuarterClosingMonth,
      orElse: () => months.last,
    );
  }

  DateTime get finalFilingMonth {
    final endMonth = filing.quarterEndMonth;
    return DateTime(endMonth.year, endMonth.month + 1);
  }

  double get balanceTaxLiability => quarterTaxLiability - paidTaxSnapshot;
}

class GstQuarterFilingMonthLedger {
  const GstQuarterFilingMonthLedger({
    required this.filing,
    required this.taxLiability,
    required this.invoiceCount,
    required this.b2bInvoiceCount,
    required this.b2bTaxLiability,
    required this.b2cInvoiceCount,
    required this.b2cTaxLiability,
    required this.monthlyPaymentStatus,
    required this.b2bIffStatus,
    required this.b2bReturnStatus,
    required this.b2cReturnStatus,
  });

  final GstFilingPeriod filing;
  final double taxLiability;
  final int invoiceCount;
  final int b2bInvoiceCount;
  final double b2bTaxLiability;
  final int b2cInvoiceCount;
  final double b2cTaxLiability;
  final GstFilingTaskStatus monthlyPaymentStatus;
  final GstFilingTaskStatus b2bIffStatus;
  final GstFilingTaskStatus b2bReturnStatus;
  final GstFilingTaskStatus b2cReturnStatus;

  bool get hasMonthlyPayment => filing.hasMonthlyTaxPayment;

  bool get isMonthlyPaymentComplete =>
      hasMonthlyPayment && monthlyPaymentStatus.completed;

  bool get isIffComplete =>
      filing.iffDueDate != null && b2bIffStatus.completed;
}
