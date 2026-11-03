import 'day_book_document.dart';
import 'day_book_models.dart';

/// Daily invoice values and posted receipts are intentionally separate.
class DayBookOverviewMetrics {
  const DayBookOverviewMetrics({
    required this.openingCounterCash,
    required this.regularInvoiceCount,
    required this.regularInvoiceValue,
    required this.taxInvoiceCount,
    required this.taxInvoiceValue,
    required this.invoiceTax,
    required this.gstInvoiceCollection,
    required this.salesCollection,
    required this.dueCollection,
    required this.closingCounterCash,
  });

  factory DayBookOverviewMetrics.fromSummary(DayBookSummary summary) {
    var regularCount = 0;
    var regularValue = 0.0;
    var taxCount = 0;
    var taxValue = 0.0;
    var invoiceTax = 0.0;
    var gstCollection = 0.0;
    var salesCollection = 0.0;

    for (final document in summary.documents) {
      switch (document.kind) {
        case DayBookDocumentKind.regularInvoice:
          regularCount++;
          regularValue += document.amount;
          salesCollection += document.collection ?? 0;
        case DayBookDocumentKind.gstInvoice:
          taxCount++;
          taxValue += document.amount;
          invoiceTax += document.tax ?? 0;
          gstCollection += document.collection ?? 0;
          salesCollection += document.collection ?? 0;
        default:
          break;
      }
    }

    final dueCollection = summary.moneyFlow == null
        ? summary.cashIn.dueCollection
        : summary.moneyFlow!.entries
            .where((entry) =>
                entry.incoming &&
                entry.category.toUpperCase() == 'DUE_COLLECTION')
            .fold<double>(0, (total, entry) => total + entry.amount);

    return DayBookOverviewMetrics(
      openingCounterCash: summary.openingCash,
      regularInvoiceCount: regularCount,
      regularInvoiceValue: regularValue,
      taxInvoiceCount: taxCount,
      taxInvoiceValue: taxValue,
      invoiceTax: invoiceTax,
      gstInvoiceCollection: gstCollection,
      salesCollection: salesCollection,
      dueCollection: dueCollection,
      closingCounterCash: summary.closingCash,
    );
  }

  final double openingCounterCash;
  final int regularInvoiceCount;
  final double regularInvoiceValue;
  final int taxInvoiceCount;
  final double taxInvoiceValue;
  final double invoiceTax;
  final double gstInvoiceCollection;
  final double salesCollection;
  final double dueCollection;
  final double closingCounterCash;

  double get totalSales => regularInvoiceValue + taxInvoiceValue;
}
