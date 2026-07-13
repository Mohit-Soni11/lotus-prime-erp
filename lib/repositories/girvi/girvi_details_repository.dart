import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_persistence_models.dart';

class GirviLoanItemDetails {
  const GirviLoanItemDetails({
    required this.item,
    required this.photos,
  });

  final GirviLoanItem item;
  final List<GirviItemPhoto> photos;
}

class GirviLoanDetails {
  const GirviLoanDetails({
    required this.loan,
    required this.items,
    required this.disbursements,
  });

  final GirviLoan loan;
  final List<GirviLoanItemDetails> items;
  final List<GirviDisbursement> disbursements;
}

class GirviDetailsRepository {
  GirviDetailsRepository(this._db);

  final AppDatabase _db;

  Future<int> createLoanWithDetails({
    required GirviLoansCompanion loan,
    required List<GirviLoanItemInput> items,
    required List<GirviDisbursementInput> disbursements,
    required double expectedLoanAmount,
  }) async {
    _validateDetails(
      items: items,
      disbursements: disbursements,
      expectedLoanAmount: expectedLoanAmount,
    );

    return _db.transaction(() async {
      final loanId = await _db.into(_db.girviLoans).insert(loan);
      await _insertDetails(
        loanId: loanId,
        items: items,
        disbursements: disbursements,
      );
      return loanId;
    });
  }

  Future<bool> updateLoanWithDetails({
    required int loanId,
    required GirviLoansCompanion loan,
    required List<GirviLoanItemInput> items,
    required List<GirviDisbursementInput> disbursements,
    required double expectedLoanAmount,
  }) async {
    _validateDetails(
      items: items,
      disbursements: disbursements,
      expectedLoanAmount: expectedLoanAmount,
    );

    return _db.transaction(() async {
      final updated = await (_db.update(_db.girviLoans)
            ..where((row) => row.id.equals(loanId)))
          .write(
        loan.copyWith(updatedAt: drift.Value(DateTime.now())),
      );
      if (updated == 0) return false;

      await (_db.delete(_db.girviLoanItems)
            ..where((row) => row.girviId.equals(loanId)))
          .go();
      await (_db.delete(_db.girviDisbursements)
            ..where((row) => row.girviId.equals(loanId)))
          .go();
      await _insertDetails(
        loanId: loanId,
        items: items,
        disbursements: disbursements,
      );
      return true;
    });
  }

  Future<GirviLoanDetails?> getLoanDetails(int loanId) async {
    final loan = await (_db.select(_db.girviLoans)
          ..where((row) => row.id.equals(loanId)))
        .getSingleOrNull();
    if (loan == null) return null;

    final items = await (_db.select(_db.girviLoanItems)
          ..where((row) => row.girviId.equals(loanId))
          ..orderBy([(row) => drift.OrderingTerm.asc(row.serialNo)]))
        .get();
    final itemIds = items.map((item) => item.id).toList(growable: false);
    final photos = itemIds.isEmpty
        ? const <GirviItemPhoto>[]
        : await (_db.select(_db.girviItemPhotos)
              ..where((row) => row.itemId.isIn(itemIds))
              ..orderBy([
                (row) => drift.OrderingTerm.asc(row.itemId),
                (row) => drift.OrderingTerm.asc(row.sortOrder),
              ]))
            .get();
    final photosByItem = <int, List<GirviItemPhoto>>{};
    for (final photo in photos) {
      photosByItem.putIfAbsent(photo.itemId, () => []).add(photo);
    }

    final disbursements = await (_db.select(_db.girviDisbursements)
          ..where((row) => row.girviId.equals(loanId))
          ..orderBy([(row) => drift.OrderingTerm.asc(row.sequenceNo)]))
        .get();

    return GirviLoanDetails(
      loan: loan,
      items: items
          .map(
            (item) => GirviLoanItemDetails(
              item: item,
              photos: List.unmodifiable(
                photosByItem[item.id] ?? const <GirviItemPhoto>[],
              ),
            ),
          )
          .toList(growable: false),
      disbursements: List.unmodifiable(disbursements),
    );
  }

  Future<GirviLoanDetails?> getLoanDetailsByTicket(String ticketNo) async {
    final loan = await (_db.select(_db.girviLoans)
          ..where((row) => row.ticketNo.equals(ticketNo)))
        .getSingleOrNull();
    return loan == null ? null : getLoanDetails(loan.id);
  }

  Future<void> _insertDetails({
    required int loanId,
    required List<GirviLoanItemInput> items,
    required List<GirviDisbursementInput> disbursements,
  }) async {
    for (final input in items) {
      final itemId = await _db.into(_db.girviLoanItems).insert(
            GirviLoanItemsCompanion.insert(
              girviId: loanId,
              serialNo: input.serialNo,
              itemName: input.itemName.trim(),
              metalType: input.metalType.trim(),
              purity: input.purity.trim(),
              purityFactor: drift.Value(input.purityFactor),
              pieces: drift.Value(input.pieces),
              huidNumber: drift.Value(_nullableText(input.huidNumber)),
              grossWeight: drift.Value(input.grossWeight),
              lessWeight: drift.Value(input.lessWeight),
              netWeight: drift.Value(input.netWeight),
              valuationMethod: drift.Value(input.valuationMethod.trim()),
              valuationPurityPercent: drift.Value(input.valuationPurityPercent),
              fineWeight: drift.Value(input.fineWeight),
              ratePerGram: drift.Value(input.ratePerGram),
              valuationAmount: drift.Value(input.valuationAmount),
              notes: drift.Value(_nullableText(input.notes)),
            ),
          );

      for (var index = 0; index < input.photoPaths.length; index++) {
        await _db.into(_db.girviItemPhotos).insert(
              GirviItemPhotosCompanion.insert(
                itemId: itemId,
                filePath: input.photoPaths[index].trim(),
                sortOrder: drift.Value(index + 1),
              ),
            );
      }
    }

    for (final input in disbursements) {
      await _db.into(_db.girviDisbursements).insert(
            GirviDisbursementsCompanion.insert(
              girviId: loanId,
              sequenceNo: input.sequenceNo,
              mode: input.mode.trim(),
              displayLabel: input.displayLabel.trim(),
              amount: input.amount,
              bankAccountId: drift.Value(input.bankAccountId),
              accountName: drift.Value(_nullableText(input.accountName)),
              referenceNo: drift.Value(_nullableText(input.referenceNo)),
              details: drift.Value(_nullableText(input.details)),
            ),
          );
    }
  }

  void _validateDetails({
    required List<GirviLoanItemInput> items,
    required List<GirviDisbursementInput> disbursements,
    required double expectedLoanAmount,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('At least one pledged item is required.');
    }
    if (expectedLoanAmount <= 0) {
      throw ArgumentError('Loan amount must be greater than zero.');
    }

    final serialNumbers = <int>{};
    for (final item in items) {
      if (item.serialNo <= 0 || !serialNumbers.add(item.serialNo)) {
        throw ArgumentError('Pledged item serial numbers must be unique.');
      }
      if (item.itemName.trim().isEmpty) {
        throw ArgumentError('Every pledged item needs a name.');
      }
      if (item.metalType.trim().isEmpty || item.purity.trim().isEmpty) {
        throw ArgumentError('Every pledged item needs metal and purity.');
      }
      if (item.pieces <= 0 || item.grossWeight <= 0) {
        throw ArgumentError('Item pieces and gross weight must be positive.');
      }
      if (item.lessWeight < 0 || item.lessWeight > item.grossWeight) {
        throw ArgumentError('Item less weight is invalid.');
      }
      final expectedNet = item.grossWeight - item.lessWeight;
      if ((item.netWeight - expectedNet).abs() > 0.001) {
        throw ArgumentError('Item net weight does not match its weights.');
      }
      if (item.fineWeight < 0 ||
          item.ratePerGram <= 0 ||
          item.valuationAmount < 0) {
        throw ArgumentError('Item valuation values are invalid.');
      }
      if (item.photoPaths.any((path) => path.trim().isEmpty)) {
        throw ArgumentError('Item photo path cannot be empty.');
      }
    }

    if (disbursements.isEmpty) {
      throw ArgumentError('At least one disbursement entry is required.');
    }
    final sequenceNumbers = <int>{};
    var totalDisbursed = 0.0;
    for (final entry in disbursements) {
      if (entry.sequenceNo <= 0 || !sequenceNumbers.add(entry.sequenceNo)) {
        throw ArgumentError('Disbursement sequence numbers must be unique.');
      }
      if (entry.mode.trim().isEmpty ||
          entry.displayLabel.trim().isEmpty ||
          entry.amount <= 0) {
        throw ArgumentError('Disbursement entry is invalid.');
      }
      totalDisbursed += entry.amount;
    }
    if ((totalDisbursed - expectedLoanAmount).abs() > 0.50) {
      throw ArgumentError('Disbursement total must match the loan amount.');
    }
  }

  String? _nullableText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
