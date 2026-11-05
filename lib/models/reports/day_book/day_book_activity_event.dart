import 'day_book_document_item.dart';

enum DayBookActivityKind {
  girviRelease,
  girviInterest,
  girviMelted,
  dueCollection,
}

class DayBookActivityEvent {
  const DayBookActivityEvent({
    required this.kind,
    required this.sourceId,
    required this.number,
    required this.date,
    required this.amount,
    required this.customerId,
    this.partyName,
    this.mobile,
    this.items = const [],
    this.invoiceValue,
    this.savedPaid,
    this.savedDue,
  });

  final DayBookActivityKind kind;
  final int sourceId;
  final String number;
  final DateTime date;
  final double amount;
  final int? customerId;
  final String? partyName;
  final String? mobile;
  final List<DayBookDocumentItem> items;
  final double? invoiceValue;
  final double? savedPaid;
  final double? savedDue;

  DayBookActivityEvent withParty({String? name, String? phone}) =>
      DayBookActivityEvent(
        kind: kind,
        sourceId: sourceId,
        number: number,
        date: date,
        amount: amount,
        customerId: customerId,
        partyName: name ?? partyName,
        mobile: phone ?? mobile,
        items: items,
        invoiceValue: invoiceValue,
        savedPaid: savedPaid,
        savedDue: savedDue,
      );
}
