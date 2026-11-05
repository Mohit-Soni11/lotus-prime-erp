import '../../../constants/app_routes.dart';
import '../../../models/reports/day_book/day_book_activity_event.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../models/reports/day_book/day_book_expense_record.dart';

String dayBookExpenseDestination(DayBookExpenseRecord record, DateTime date) {
  final day = '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  return Uri(path: RoutePaths.financeExpense, queryParameters: {
    'date': day,
    'reference': record.reference,
  }).toString();
}

String? dayBookDocumentDestination(DayBookDocument document) {
  final id = document.customerId;
  final sourceId = int.tryParse(document.sourceId);
  if (document.kind == DayBookDocumentKind.purchaseVoucher) {
    if (document.sourceType?.toUpperCase() == 'CUSTOMER') {
      return sourceId == null
          ? null
          : RoutePaths.customerMetalPurchaseVoucherFor(sourceId);
    }
    final supplierId = document.supplierId;
    return supplierId == null
        ? null
        : Uri(
            path: RoutePaths.supplierProfileFor(supplierId),
            queryParameters: {'voucherId': document.sourceId},
          ).toString();
  }
  if (id == null) return null;
  final params = <String, String>{};
  switch (document.kind) {
    case DayBookDocumentKind.regularInvoice:
    case DayBookDocumentKind.gstInvoice:
      if (sourceId != null) params['billId'] = '$sourceId';
    case DayBookDocumentKind.returnVoucher:
      if (const {'BILL', 'SALE', 'SALES_INVOICE'}
              .contains(document.sourceType?.toUpperCase()) &&
          document.originalSourceId != null) {
        params['billId'] = '${document.originalSourceId}';
      }
    case DayBookDocumentKind.advanceCancellationVoucher:
      if (document.originalSourceId != null) {
        params['advanceId'] = '${document.originalSourceId}';
      }
    case DayBookDocumentKind.girviTicket:
      if (sourceId != null) params['girviId'] = '$sourceId';
    case DayBookDocumentKind.advanceReceipt:
      if (document.relatedEntityId != null) {
        params['advanceId'] = '${document.relatedEntityId}';
      }
    case DayBookDocumentKind.purchaseVoucher:
      break;
  }
  return Uri(path: RoutePaths.customerProfileFor(id), queryParameters: params)
      .toString();
}

String? dayBookActivityDestination(DayBookActivityEvent event) {
  final customerId = event.customerId;
  if (customerId == null) return null;
  return Uri(
    path: RoutePaths.customerProfileFor(customerId),
    queryParameters: event.kind == DayBookActivityKind.dueCollection
        ? {'billId': '${event.sourceId}'}
        : {'girviId': '${event.sourceId}'},
  ).toString();
}

String? dayBookReceiptDestination(
  DayBookMoneyEntry entry,
  List<DayBookDocument> documents,
  List<DayBookActivityEvent> events,
) {
  final reference = entry.referenceId?.split('#').first.trim();
  if (reference == null || reference.isEmpty) return null;
  final category = entry.category.toUpperCase();
  if (category == 'DUE_COLLECTION' ||
      category == 'GIRVI_RETURN' ||
      category == 'INTEREST_RECEIVED') {
    for (final event in events) {
      if (event.number != reference) continue;
      if (category == 'DUE_COLLECTION' &&
          event.kind == DayBookActivityKind.dueCollection) {
        return dayBookActivityDestination(event);
      }
      if (category != 'DUE_COLLECTION' &&
          (event.kind == DayBookActivityKind.girviRelease ||
              event.kind == DayBookActivityKind.girviInterest)) {
        return dayBookActivityDestination(event);
      }
    }
  }
  for (final document in documents) {
    if (document.number == reference ||
        document.number.startsWith('$reference /')) {
      return dayBookDocumentDestination(document);
    }
  }
  return null;
}
