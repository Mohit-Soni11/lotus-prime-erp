import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_expense_record.dart';
import 'day_book_models.dart';
import 'day_book_money_flow.dart';
import 'day_book_stock_movement.dart';

enum DayBookTimelineKind {
  document('Source document'),
  payment('Money movement'),
  metal('Metal movement'),
  activity('Business activity'),
  expense('Expense entry');

  const DayBookTimelineKind(this.label);
  final String label;
}

class DayBookTimelineRecord {
  const DayBookTimelineRecord({
    required this.key,
    required this.at,
    required this.kind,
    required this.reference,
    required this.title,
    required this.detail,
    this.amount,
    this.paymentMode,
    this.document,
    this.money,
    this.activity,
    this.stock,
    this.expense,
  });

  final String key;
  final DateTime at;
  final DayBookTimelineKind kind;
  final String reference;
  final String title;
  final String detail;
  final double? amount;
  final String? paymentMode;
  final DayBookDocument? document;
  final DayBookMoneyEntry? money;
  final DayBookActivityEvent? activity;
  final DayBookStockMovement? stock;
  final DayBookExpenseRecord? expense;
}

/// Read-only timeline. Its document values and payment values are separate
/// events and are never summed together as turnover or cash flow.
class DayBookTimeline {
  const DayBookTimeline._();

  static List<DayBookTimelineRecord> fromSummary(DayBookSummary summary) {
    final records = <DayBookTimelineRecord>[];
    for (final doc in summary.documents) {
      records.add(DayBookTimelineRecord(
        key: 'document:${doc.kind.name}:${doc.sourceId}',
        at: doc.date,
        kind: DayBookTimelineKind.document,
        reference: doc.number,
        title: doc.kind.label,
        detail: doc.partyName ?? doc.status,
        amount: doc.amount,
        document: doc,
      ));
    }
    for (final entry
        in summary.moneyFlow?.entries ?? const <DayBookMoneyEntry>[]) {
      records.add(DayBookTimelineRecord(
        key: 'payment:${entry.transactionId}',
        at: entry.date,
        kind: DayBookTimelineKind.payment,
        reference: entry.referenceId ?? entry.transactionId,
        title: entry.incoming ? 'Money In' : 'Money Out',
        detail: '${entry.category} · ${entry.paymentMode}'
            '${entry.accountName == null ? '' : ' · ${entry.accountName}'}',
        amount: entry.amount,
        paymentMode: entry.paymentMode,
        money: entry,
      ));
    }
    for (final move in summary.stockMovements) {
      records.add(DayBookTimelineRecord(
        key: 'metal:${move.id}',
        at: move.occurredAt,
        kind: DayBookTimelineKind.metal,
        reference: move.sourceNumber ??
            '${move.sourceType}:${move.sourceId}'
                '${move.sourceLineNo == null ? '' : ':${move.sourceLineNo}'}',
        title: move.isInward ? 'Metal In' : 'Metal Out',
        detail: '${move.metal} ${move.itemName} · '
            '${move.netWeightDelta.toStringAsFixed(3)} g net',
        stock: move,
      ));
    }
    for (final event in summary.activityEvents) {
      records.add(DayBookTimelineRecord(
        key: 'activity:${event.kind.name}:${event.sourceId}:'
            '${event.date.microsecondsSinceEpoch}',
        at: event.date,
        kind: DayBookTimelineKind.activity,
        reference: event.number,
        title: event.kind.name,
        detail: event.partyName ?? 'Business event',
        amount: event.amount,
        activity: event,
      ));
    }
    final postedReferences = <String>{
      for (final entry
          in summary.moneyFlow?.entries ?? const <DayBookMoneyEntry>[])
        entry.transactionId,
    };
    for (final expense in summary.expenseRecords) {
      if (postedReferences.contains(expense.reference) ||
          expense.postedAt == null) {
        continue;
      }
      records.add(DayBookTimelineRecord(
        key: 'expense:${expense.reference}',
        at: expense.postedAt!,
        kind: DayBookTimelineKind.expense,
        reference: expense.reference,
        title: 'Expense Entry',
        detail: expense.category,
        amount: expense.amount,
        paymentMode: expense.paymentMode,
        expense: expense,
      ));
    }
    records.sort((a, b) {
      final date = a.at.compareTo(b.at);
      return date == 0 ? a.key.compareTo(b.key) : date;
    });
    return List.unmodifiable(records);
  }
}
