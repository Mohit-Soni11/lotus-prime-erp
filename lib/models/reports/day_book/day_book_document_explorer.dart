import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_models.dart';

enum DayBookExplorerTab {
  sales('Sales'),
  gstSales('GST Sales'),
  girvi('Girvi'),
  advance('Advance'),
  returns('Returns'),
  purchase('Purchase');

  const DayBookExplorerTab(this.label);
  final String label;
}

class DayBookExplorerEntry {
  const DayBookExplorerEntry.document(this.document) : event = null;
  const DayBookExplorerEntry.event(this.event) : document = null;

  final DayBookDocument? document;
  final DayBookActivityEvent? event;

  String get reference => document?.number ?? event!.number;

  double get amount => document?.amount ?? event!.amount;
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
    };
  }
}
