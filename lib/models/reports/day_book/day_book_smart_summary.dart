import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_expense_record.dart';
import 'day_book_models.dart';
import 'day_book_money_flow.dart';

enum DayBookCardType {
  sales('Total Sales'),
  advanceReceived('Advance Received'),
  receipts("Today's Receipts"),
  dues("Today's Dues"),
  girviGiven('Girvi Given'),
  returnAndCancellation('Return & Cancellation'),
  customerMetalPurchase('Customer Metal Purchase'),
  expenses('Expenses');

  const DayBookCardType(this.label);
  final String label;
}

class DayBookSmartGroup {
  const DayBookSmartGroup(
    this.label, {
    this.documents = const [],
    this.moneyEntries = const [],
    this.expenses = const [],
    this.sourceDocuments = const [],
    this.sourceEvents = const [],
  });

  final String label;
  final List<DayBookDocument> documents;
  final List<DayBookMoneyEntry> moneyEntries;
  final List<DayBookExpenseRecord> expenses;
  final List<DayBookDocument> sourceDocuments;
  final List<DayBookActivityEvent> sourceEvents;

  int get count => documents.length + moneyEntries.length + expenses.length;
  double get amount =>
      documents.fold<double>(0, (sum, row) => sum + row.amount) +
      moneyEntries.fold<double>(0, (sum, row) => sum + row.amount) +
      expenses.fold<double>(0, (sum, row) => sum + row.amount);
  double get collection =>
      documents.fold<double>(0, (sum, row) => sum + (row.collection ?? 0));
  double get tax =>
      documents.fold<double>(0, (sum, row) => sum + (row.tax ?? 0));
  double get due => documents.fold<double>(
      0, (sum, row) => sum + (row.outstanding ?? 0).clamp(0, double.infinity));
  bool get hasUnknownDue => documents.any((row) => row.outstanding == null);
  String get numberRange {
    final numbers = [
      ...documents.map((row) => row.number),
      ...moneyEntries
          .map((row) => row.referenceId?.split('#').first ?? row.transactionId),
      ...expenses.map((row) => row.reference),
    ];
    if (numbers.isEmpty) return '';
    return numbers.length == 1
        ? numbers.first
        : '${numbers.first} – ${numbers.last}';
  }
}

class DayBookSmartCard {
  const DayBookSmartCard(this.type, this.groups);

  final DayBookCardType type;
  final List<DayBookSmartGroup> groups;

  String get title => type.label;
  int get count => groups.fold(0, (sum, group) => sum + group.count);
  double get amount => type == DayBookCardType.dues
      ? groups.fold(0, (sum, group) => sum + group.due)
      : groups.fold(0, (sum, group) => sum + group.amount);
  bool get hasUnknownDue =>
      type == DayBookCardType.dues &&
      groups.any((group) => group.hasUnknownDue);
}

/// Read-only source projection. Zero-activity cards remain in the layout.
class DayBookSmartSummary {
  const DayBookSmartSummary(this.cards);

  final List<DayBookSmartCard> cards;

  factory DayBookSmartSummary.fromDay(DayBookSummary summary) {
    final documents = summary.documents.where((row) => !row.isVoided).toList();
    List<DayBookDocument> docs(DayBookDocumentKind kind) =>
        documents.where((row) => row.kind == kind).toList();
    final regular = docs(DayBookDocumentKind.regularInvoice);
    final gst = docs(DayBookDocumentKind.gstInvoice);
    final invoiceDues = [...regular, ...gst]
        .where((row) => row.outstanding == null || row.outstanding! > 0)
        .toList();
    final customerPurchases = docs(DayBookDocumentKind.purchaseVoucher)
        .where((row) => row.sourceType?.toUpperCase() == 'CUSTOMER')
        .toList();
    final receipts = summary.moneyFlow?.entries
            .where((row) => row.incoming && !row.isInternalTransfer)
            .toList() ??
        <DayBookMoneyEntry>[];

    return DayBookSmartSummary(List.unmodifiable([
      DayBookSmartCard(DayBookCardType.sales, [
        DayBookSmartGroup('Regular invoices', documents: regular),
        DayBookSmartGroup('GST invoices', documents: gst),
      ]),
      DayBookSmartCard(DayBookCardType.advanceReceived, [
        DayBookSmartGroup('Advance receipts',
            documents: docs(DayBookDocumentKind.advanceReceipt)),
      ]),
      DayBookSmartCard(DayBookCardType.receipts, [
        DayBookSmartGroup('Posted money in',
            moneyEntries: receipts,
            sourceDocuments: documents,
            sourceEvents: summary.activityEvents),
      ]),
      DayBookSmartCard(DayBookCardType.dues, [
        DayBookSmartGroup('Invoices with new dues', documents: invoiceDues),
      ]),
      DayBookSmartCard(DayBookCardType.girviGiven, [
        DayBookSmartGroup('Loans given',
            documents: docs(DayBookDocumentKind.girviTicket)),
      ]),
      DayBookSmartCard(DayBookCardType.returnAndCancellation, [
        DayBookSmartGroup('Sales returns',
            documents: docs(DayBookDocumentKind.returnVoucher)),
        DayBookSmartGroup('Advance cancellations',
            documents: docs(DayBookDocumentKind.advanceCancellationVoucher)),
      ]),
      DayBookSmartCard(DayBookCardType.customerMetalPurchase, [
        DayBookSmartGroup('Customer metal purchases',
            documents: customerPurchases),
      ]),
      DayBookSmartCard(DayBookCardType.expenses, [
        DayBookSmartGroup('Expense entries', expenses: summary.expenseRecords),
      ]),
    ]));
  }
}
