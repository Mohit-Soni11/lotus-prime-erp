import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_demo_preview.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document_explorer.dart';

void main() {
  test('preview separates sales, GST, Girvi and other payments', () {
    final explorer = DayBookDocumentExplorer(
      DayBookDemoPreview.forDate(DateTime(2026, 11, 4)),
    );
    final regular = explorer.entriesFor(DayBookExplorerTab.sales);
    final gst = explorer.entriesFor(DayBookExplorerTab.gstSales);
    final payments = explorer.entriesFor(DayBookExplorerTab.otherPayments);
    final girvi = explorer.entriesFor(DayBookExplorerTab.girvi);

    expect(regular.map((row) => row.reference),
        ['REG-025', 'REG-026', 'REG-027', 'REG-028', 'REG-029']);
    expect(regular.fold<double>(0, (sum, row) => sum + row.amount), 111000);
    expect(gst, hasLength(3));
    expect(payments.every((row) => row.money?.incoming == true), isTrue);
    expect(
        payments.any((row) => row.money?.category == 'DUE_COLLECTION'), isTrue);
    expect(girvi.where((row) => row.document != null), hasLength(2));
    expect(girvi.where((row) => row.event != null), hasLength(3));
    expect(explorer.entriesFor(DayBookExplorerTab.expenses), hasLength(3));
  });
}
