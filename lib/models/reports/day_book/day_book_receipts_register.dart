import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_expense_record.dart';
import 'day_book_models.dart';
import 'day_book_money_flow.dart';

enum DayBookRegisterTab { due, received, expense }

class DayBookDueRow {
  const DayBookDueRow({
    required this.reference,
    required this.type,
    this.customerName,
    this.phone,
    this.customerId,
    this.totalValue,
    this.amountPaid,
    this.dueAmount,
    this.paidAgainstDue = 0,
    this.document,
    this.event,
  });

  final String reference;
  final String type;
  final String? customerName;
  final String? phone;
  final int? customerId;
  final double? totalValue;
  final double? amountPaid;
  final double? dueAmount;
  final double paidAgainstDue;
  final DayBookDocument? document;
  final DayBookActivityEvent? event;

  double? get dueBeforeReceipts =>
      dueAmount == null ? null : dueAmount! + paidAgainstDue;
}

class DayBookReceivedRow {
  const DayBookReceivedRow({
    required this.reference,
    required this.type,
    required this.amount,
    required this.mode,
    this.customerName,
    this.phone,
    this.totalValue,
    this.entry,
  });

  final String reference;
  final String type;
  final String? customerName;
  final String? phone;
  final double? totalValue;
  final double amount;
  final String mode;
  final DayBookMoneyEntry? entry;
}

class DayBookReceiptsRegister {
  const DayBookReceiptsRegister({
    required this.dues,
    required this.received,
    required this.expenses,
  });

  final List<DayBookDueRow> dues;
  final List<DayBookReceivedRow> received;
  final List<DayBookExpenseRecord> expenses;

  factory DayBookReceiptsRegister.fromSummary(DayBookSummary summary) {
    final documents = summary.documents.where((row) => !row.isVoided).toList();
    final receiptsByBill = <String, List<DayBookActivityEvent>>{};
    for (final event in summary.activityEvents) {
      if (event.kind == DayBookActivityKind.dueCollection) {
        receiptsByBill.putIfAbsent(event.number, () => []).add(event);
      }
    }
    final dues = <DayBookDueRow>[];
    final knownNumbers = <String>{};
    for (final document in documents) {
      if (document.kind != DayBookDocumentKind.regularInvoice &&
          document.kind != DayBookDocumentKind.gstInvoice) {
        continue;
      }
      final dueReceipts = receiptsByBill[document.number] ?? const [];
      final issuedDue = document.outstanding;
      if (issuedDue != null && issuedDue <= 0 && dueReceipts.isEmpty) {
        continue;
      }
      final collectedToday =
          dueReceipts.fold<double>(0, (sum, event) => sum + event.amount);
      knownNumbers.add(document.number);
      dues.add(DayBookDueRow(
        reference: document.number,
        type: document.kind == DayBookDocumentKind.gstInvoice ? 'GST' : 'Sales',
        customerName: document.partyName,
        phone: document.mobile,
        customerId: document.customerId,
        totalValue: document.amount,
        amountPaid: issuedDue == null
            ? null
            : document.amount - issuedDue + collectedToday,
        dueAmount: issuedDue == null
            ? null
            : (issuedDue - collectedToday).clamp(0, double.infinity),
        paidAgainstDue: collectedToday,
        document: document,
      ));
    }
    for (final events in receiptsByBill.values) {
      final event = events.first;
      if (knownNumbers.contains(event.number)) continue;
      dues.add(DayBookDueRow(
        reference: event.number,
        type: 'Old Due',
        customerName: event.partyName,
        phone: event.mobile,
        customerId: event.customerId,
        totalValue: event.invoiceValue,
        amountPaid: null,
        dueAmount: null,
        paidAgainstDue:
            events.fold<double>(0, (sum, receipt) => sum + receipt.amount),
        event: event,
      ));
    }

    final documentsByNumber = {for (final row in documents) row.number: row};
    final received = <DayBookReceivedRow>[];
    for (final entry
        in summary.moneyFlow?.entries ?? const <DayBookMoneyEntry>[]) {
      if (!entry.incoming || entry.isInternalTransfer) continue;
      final number = entry.referenceId?.split('#').first.trim();
      final document = documentsByNumber[number];
      final activity = receiptsByBill[number]?.firstOrNull;
      received.add(DayBookReceivedRow(
        reference: number?.isNotEmpty == true ? number! : entry.transactionId,
        type: _receiptType(entry.category),
        customerName:
            document?.partyName ?? activity?.partyName ?? entry.partyName,
        phone: document?.mobile ?? activity?.mobile,
        totalValue: document?.amount ?? activity?.invoiceValue,
        amount: entry.amount,
        mode: entry.paymentMode,
        entry: entry,
      ));
    }
    return DayBookReceiptsRegister(
      dues: List.unmodifiable(dues),
      received: List.unmodifiable(received),
      expenses: summary.expenseRecords,
    );
  }

  static String _receiptType(String category) =>
      switch (category.toUpperCase()) {
        'SALE' || 'SALE_PAYMENT' => 'Sales',
        'DUE_COLLECTION' => 'Due',
        'ADVANCE' || 'ADVANCE_RECEIVED' => 'Advance',
        'GIRVI_RETURN' => 'Girvi Release',
        'CHANGE_RECEIVED' => 'Change received',
        'REFUND_PAYABLE_RECEIVED' => 'Customer deposit',
        'INTEREST_RECEIVED' => 'Interest',
        'COUNTER_SALE_INCOME' => 'Counter sale (no invoice)',
        'GOLD_REPAIR_INCOME' => 'Gold repair',
        'SILVER_REPAIR_INCOME' => 'Silver repair',
        'JEWELLERY_MAKING_INCOME' => 'Jewellery making',
        'OTHER_INCOME' => 'Other income',
        _ => category.replaceAll('_', ' '),
      };
}
