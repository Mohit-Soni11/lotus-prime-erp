import 'day_book_document.dart';
import 'day_book_money_flow.dart';

class DayBookDocumentCollectionMapper {
  const DayBookDocumentCollectionMapper._();

  static List<DayBookDocument> apply(
      List<DayBookDocument> documents, DayBookMoneyFlow flow) {
    final collections = <String, double>{};
    final advanceCollections = <String, double>{};
    for (final entry in flow.entries) {
      if (!entry.incoming) continue;
      if (entry.referenceType?.toUpperCase() == 'ORDER' &&
          {'ADVANCE', 'ADVANCE_RECEIVED'}
              .contains(entry.category.toUpperCase())) {
        final receiptId = entry.referenceId?.split('#ADV#').last;
        if (receiptId != null &&
            receiptId != entry.referenceId &&
            int.tryParse(receiptId) != null) {
          advanceCollections[receiptId] =
              (advanceCollections[receiptId] ?? 0) + entry.amount;
        }
        continue;
      }
      if (entry.referenceType?.toUpperCase() != 'BILL' ||
          !{'SALE', 'SALE_PAYMENT'}.contains(entry.category.toUpperCase())) {
        continue;
      }
      final billNo = entry.referenceId?.split('#').first.trim();
      if (billNo == null || billNo.isEmpty) {
        continue;
      }
      collections[billNo] = (collections[billNo] ?? 0) + entry.amount;
    }
    return List.unmodifiable(documents.map((document) {
      if (document.kind == DayBookDocumentKind.advanceReceipt) {
        final collection = advanceCollections[document.sourceId];
        return collection == null
            ? document
            : document.withCollection(collection);
      }
      if (document.kind != DayBookDocumentKind.regularInvoice &&
          document.kind != DayBookDocumentKind.gstInvoice) {
        return document;
      }
      final collection = collections[document.number];
      if (collection == null) {
        return document;
      }
      return document.withCollection(collection);
    }));
  }
}
