import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_expense_record.dart';
import 'day_book_models.dart';
import 'day_book_money_flow.dart';

enum DayBookExplorerTab {
  sales('Sales'),
  gstSales('GST Sales'),
  girvi('Girvi'),
  advance('Advance'),
  returns('Returns'),
  purchase('Purchase'),
  expenses('Expense'),
  otherPayments('Other Payments');

  const DayBookExplorerTab(this.label);
  final String label;
}

class DayBookExplorerEntry {
  const DayBookExplorerEntry.document(this.document)
      : money = null,
        event = null,
        expense = null;
  const DayBookExplorerEntry.money(this.money)
      : document = null,
        event = null,
        expense = null;
  const DayBookExplorerEntry.event(this.event)
      : document = null,
        money = null,
        expense = null;
  const DayBookExplorerEntry.expense(this.expense)
      : document = null,
        money = null,
        event = null;

  final DayBookDocument? document;
  final DayBookMoneyEntry? money;
  final DayBookActivityEvent? event;
  final DayBookExpenseRecord? expense;

  String get reference {
    if (document != null) return document!.number;
    if (money != null) {
      final source = money!.referenceId?.split('#').first.trim();
      return source?.isNotEmpty == true ? source! : money!.transactionId;
    }
    return event?.number ?? expense!.reference;
  }

  double get amount =>
      document?.amount ?? money?.amount ?? event?.amount ?? expense!.amount;
}

/// Read-only projection over already posted Day Book sources.
class DayBookDocumentExplorer {
  const DayBookDocumentExplorer(this.summary);
  final DayBookSummary summary;

  List<DayBookExplorerEntry> entriesFor(DayBookExplorerTab tab) {
    final documents = summary.documents.where((row) => !row.isVoided);
    List<DayBookExplorerEntry> docs(bool Function(DayBookDocument) include) =>
        documents.where(include).map(DayBookExplorerEntry.document).toList();
    return switch (tab) {
      DayBookExplorerTab.sales =>
        docs((row) => row.kind == DayBookDocumentKind.regularInvoice),
      DayBookExplorerTab.gstSales =>
        docs((row) => row.kind == DayBookDocumentKind.gstInvoice),
      DayBookExplorerTab.advance =>
        docs((row) => row.kind == DayBookDocumentKind.advanceReceipt),
      DayBookExplorerTab.otherPayments =>
        (summary.moneyFlow?.entries ?? const <DayBookMoneyEntry>[])
            .where((row) =>
                row.incoming &&
                !row.isInternalTransfer &&
                !const {'SALE', 'SALE_PAYMENT', 'ADVANCE', 'ADVANCE_RECEIVED'}
                    .contains(row.category.toUpperCase()))
            .map(DayBookExplorerEntry.money)
            .toList(),
      DayBookExplorerTab.girvi => [
          ...docs((row) => row.kind == DayBookDocumentKind.girviTicket),
          ...summary.activityEvents
              .where((row) => row.kind != DayBookActivityKind.dueCollection)
              .map(DayBookExplorerEntry.event),
        ],
      DayBookExplorerTab.returns => docs((row) =>
          row.kind == DayBookDocumentKind.returnVoucher ||
          row.kind == DayBookDocumentKind.advanceCancellationVoucher),
      DayBookExplorerTab.purchase => docs((row) =>
          row.kind == DayBookDocumentKind.purchaseVoucher &&
          row.sourceType?.toUpperCase() == 'CUSTOMER'),
      DayBookExplorerTab.expenses =>
        summary.expenseRecords.map(DayBookExplorerEntry.expense).toList(),
    };
  }
}
