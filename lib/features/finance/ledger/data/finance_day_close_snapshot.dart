import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_custody_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_document_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_owned_stock_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_stock_movement_repository.dart';

class FinanceDayCloseSnapshot {
  const FinanceDayCloseSnapshot(this.json, this.sourceHash);

  final String json;
  final String sourceHash;
}

/// Builds the immutable close evidence from the same database transaction as
/// the finance-day lock. A failed source query aborts the close.
class FinanceDayCloseSnapshotBuilder {
  const FinanceDayCloseSnapshotBuilder(this.db);

  final AppDatabase db;

  Future<FinanceDayCloseSnapshot> build(
    DateTime day, {
    required double physicalCash,
    double? physicalBank,
    Map<String, num>? denominationCount,
  }) async {
    final start = DateTime(day.year, day.month, day.day);
    if (denominationCount != null) {
      var counted = 0.0;
      for (final entry in denominationCount.entries) {
        final value = entry.value.toDouble();
        if (!value.isFinite || value < 0) {
          throw StateError('Physical cash count contains an invalid value.');
        }
        if (entry.key == 'coins') {
          counted += value;
        } else {
          final denomination = int.tryParse(entry.key);
          if (denomination == null ||
              denomination <= 0 ||
              value != value.roundToDouble()) {
            throw StateError(
                'Physical cash count has an invalid denomination.');
          }
          counted += denomination * value;
        }
      }
      if ((counted - physicalCash).abs() >= 0.01) {
        throw StateError('Physical cash count differs from the closing cash.');
      }
    }
    final moneyRepo = DayBookMoneyRepository(db);
    final openingCash = await moneyRepo.fetchOpeningCash(start);
    final money = await moneyRepo.fetch(start, openingCash);
    if ((money.closingCash - physicalCash).abs() >= 0.01) {
      throw StateError('Cash balance changed during day closing.');
    }
    if (physicalBank != null &&
        (!physicalBank.isFinite ||
            (money.closingBank - physicalBank).abs() >= 0.01)) {
      throw StateError('Bank balance changed during day closing.');
    }

    final movements = await DayBookStockMovementRepository(db).fetch(start);
    final owned = await DayBookOwnedStockRepository(db).fetch(start, movements);
    final custody = await DayBookCustodyRepository(db).fetch(start);
    final documents = await DayBookDocumentRepository(db).fetch(start);
    final bankAccounts = await db.select(db.bankAccounts).get();
    final end = DateTime(start.year, start.month, start.day + 1);
    final accountMovements = await db.customSelect(
      '''SELECT account_id,
           SUM(CASE WHEN type = 'CREDIT' THEN amount
                    WHEN type = 'DEBIT' THEN -amount ELSE 0 END) AS movement
         FROM bank_transactions
         WHERE is_voided = 0 AND txn_date < ?
         GROUP BY account_id''',
      variables: [Variable.withDateTime(end)],
    ).get();
    final movementByAccount = {
      for (final row in accountMovements)
        row.read<int>('account_id'): row.read<double>('movement'),
    };
    final bankPositions = [
      for (final account in bankAccounts)
        {
          'id': account.id,
          'name': account.accountName,
          'closing': (DateTime(account.activeSince.year,
                          account.activeSince.month, account.activeSince.day)
                      .isAfter(start)
                  ? 0.0
                  : account.openingBalance) +
              (movementByAccount[account.id] ?? 0),
        },
    ]..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    final sourceEvidence = {
      'openingCash': money.openingCash,
      'openingBank': money.openingBank,
      'bankAccounts': bankPositions,
      'money': [
        for (final entry in [
          ...money.entries
        ]..sort((a, b) => a.transactionId.compareTo(b.transactionId)))
          [
            entry.transactionId,
            entry.referenceType,
            entry.referenceId,
            entry.category,
            entry.amount,
            entry.incoming,
            entry.paymentMode
          ],
      ],
      'stock': [
        for (final move in movements)
          [
            move.id,
            move.sourceType,
            move.sourceId,
            move.sourceLineNo,
            move.metal,
            move.puritySnapshot,
            move.quantityDelta,
            move.grossWeightDelta,
            move.netWeightDelta,
            move.fineWeightDelta
          ],
      ],
      'documents': [
        for (final doc in documents)
          [doc.kind.name, doc.sourceId, doc.number, doc.amount, doc.status],
      ],
      'custody': [
        for (final line in [...custody.lines]..sort((a, b) {
            final byTicket = a.ticketNo.compareTo(b.ticketNo);
            return byTicket == 0 ? a.itemName.compareTo(b.itemName) : byTicket;
          }))
          [
            line.ticketNo,
            line.itemName,
            line.purity,
            line.pieces,
            line.netWeight,
            line.receivedAt.toIso8601String(),
            line.exitedAt?.toIso8601String()
          ],
      ],
    };
    final sourceHash =
        sha256.convert(utf8.encode(jsonEncode(sourceEvidence))).toString();
    final snapshot = {
      'version': 1,
      'day': '${start.year.toString().padLeft(4, '0')}-'
          '${start.month.toString().padLeft(2, '0')}-'
          '${start.day.toString().padLeft(2, '0')}',
      'physicalCash': physicalCash,
      if (physicalBank != null) 'physicalBank': physicalBank,
      'denominations': denominationCount,
      'money': {
        'openingCash': money.openingCash,
        'cashIn': money.cashIn,
        'cashOut': money.cashOut,
        'closingCash': money.closingCash,
        'openingBank': money.openingBank,
        'bankIn': money.bankIn,
        'bankOut': money.bankOut,
        'closingBank': money.closingBank,
        'openingTotal': money.openingTotal,
        'closingTotal': money.closingTotal,
        'unclearedChequeIn': money.unclearedChequeIn,
        'unclearedChequeOut': money.unclearedChequeOut,
        'bankAccounts': bankPositions,
      },
      'ownedMetal': {
        'gold': {
          'openingGrams': owned.gold.openingGrams,
          'inwardGrams': owned.gold.inwardGrams,
          'soldGrams': owned.gold.soldGrams,
          'otherOutGrams': owned.gold.otherOutGrams,
          'closingGrams': owned.gold.closingGrams,
          'consistent': owned.gold.isConsistent,
        },
        'silver': {
          'openingGrams': owned.silver.openingGrams,
          'inwardGrams': owned.silver.inwardGrams,
          'soldGrams': owned.silver.soldGrams,
          'otherOutGrams': owned.silver.otherOutGrams,
          'closingGrams': owned.silver.closingGrams,
          'consistent': owned.silver.isConsistent,
        },
      },
      'custody': {
        'openingPieces':
            custody.opening.fold<int>(0, (n, line) => n + line.pieces),
        'receivedPieces':
            custody.received.fold<int>(0, (n, line) => n + line.pieces),
        'releasedPieces':
            custody.released.fold<int>(0, (n, line) => n + line.pieces),
        'closingPieces':
            custody.closing.fold<int>(0, (n, line) => n + line.pieces),
        'verified': custody.closingVerified,
      },
      'sourceHash': sourceHash,
    };
    return FinanceDayCloseSnapshot(jsonEncode(snapshot), sourceHash);
  }
}
