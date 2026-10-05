import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_interest_period_snapshot.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/contact_recovery_model.dart';
import '../../repositories/girvi/girvi_notice_action_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import '../../repositories/girvi/girvi_interest_period_snapshot_repository.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import 'girvi_risk_policy.dart';

class ContactRecoveryController extends ChangeNotifier {
  ContactRecoveryController({
    AppDatabase? db,
    GirviRepository? repository,
    GirviBillingRepo? billingRepo,
    GirviNoticeActionRepository? noticeActionRepository,
  }) {
    final resolvedDb = db ?? AppDatabase();
    _db = resolvedDb;
    _repository = repository ?? GirviRepository(resolvedDb);
    _billingRepo = billingRepo ?? GirviBillingRepo(db: resolvedDb);
    _noticeActionRepository =
        noticeActionRepository ?? GirviNoticeActionRepository(resolvedDb);
  }

  late final AppDatabase _db;
  late final GirviRepository _repository;
  late final GirviBillingRepo _billingRepo;
  late final GirviNoticeActionRepository _noticeActionRepository;
  late final GirviInterestPeriodSnapshotRepository
      _interestPeriodSnapshotRepository =
      GirviInterestPeriodSnapshotRepository(_db);

  AppDatabase get database => _db;

  Future<List<RecoveryBankAccountOption>>
      loadActiveRecoveryBankAccounts() async {
    final accounts = await (_db.select(_db.bankAccounts)
          ..where((account) => account.isActive.equals(true))
          ..orderBy([
            (account) => drift.OrderingTerm.desc(account.isPrimary),
            (account) => drift.OrderingTerm.asc(account.accountName),
          ]))
        .get();
    return accounts
        .map(
          (account) => RecoveryBankAccountOption(
            id: account.id,
            label: '${account.accountName} · ${account.bankName}',
          ),
        )
        .toList(growable: false);
  }

  ContactRecoveryState _state = ContactRecoveryState.initial();
  ContactRecoveryState get state => _state;

  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  Future<void> load({bool keepInlineMessage = false}) async {
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearInlineMessage: !keepInlineMessage,
    );
    notifyListeners();

    try {
      await _repository.syncOverdueStatus();
      final billing = await _billingRepo.fetch();
      final noticeDays = billing.noticeDays <= 0 ? 7 : billing.noticeDays;
      final now = DateTime.now();
      final loans =
          await _repository.getLoansWithCustomer(includeAuctioned: true);
      // Materialize the financial timeline before cases are built. Notice
      // generation only reads these snapshots and never recalculates history.
      final interestPeriodSnapshots = await _interestPeriodSnapshotRepository
          .synchronizeForLoans(loans, asOf: now);
      final paymentHistory = await _loadPaymentHistory(
        loans.map((entry) => entry.loan.id).toList(growable: false),
      );

      final candidateAccounts = loans.where((entry) {
        final status = entry.loan.girviStatus;
        if (status == GirviStatus.released ||
            status == GirviStatus.readyForDelivery) {
          return false;
        }
        if (status == GirviStatus.auctioned) return true;
        final maturityDate = entry.loan.maturityDate ??
            GirviLoanModel.addChargeableMonths(
              entry.loan.startDate,
              entry.loan.durationMonths,
            );
        final coveredInterestMonths = _coveredInterestMonths(
          entry,
          paymentHistory[entry.loan.id] ?? const [],
        );
        final hasInterestPaidBeforeMaturity =
            entry.loan.lastInterestPaidDate != null &&
                !entry.loan.lastInterestPaidDate!.isAfter(maturityDate);
        final assessment = GirviRiskPolicy.assess(
          status: status,
          startDate: entry.loan.startDate,
          maturityDate: maturityDate,
          lastInterestPaidDate: entry.loan.lastInterestPaidDate,
          principalDue: entry.principalDue,
          interestDue: _verifiedInterestDue(
            entry,
            interestPeriodSnapshots[entry.loan.id] ?? const [],
          ),
          hasCollectionHistory: entry.interestPaidTotal > 0 ||
              entry.principalPaidTotal > 0 ||
              entry.interestDiscountTotal > 0 ||
              entry.principalDiscountTotal > 0 ||
              entry.legacyPrincipalRepaidTotal > 0 ||
              entry.loan.lastInterestPaidDate != null,
          hasInterestPaidBeforeMaturity: hasInterestPaidBeforeMaturity,
          coveredInterestMonths: coveredInterestMonths,
          now: now,
        );
        return assessment.stage == GirviRiskStage.critical;
      }).toList();
      final actionHistory = await _noticeActionRepository.actionsByGirviIds(
        candidateAccounts.map((entry) => entry.loan.id).toList(),
      );
      final photoPaths = await _loadItemPhotoPaths(
        candidateAccounts.map((entry) => entry.loan.id).toList(),
      );
      final cases = candidateAccounts
          .map(
            (entry) => ContactRecoveryCase(
              account: entry,
              noticePeriodDays: noticeDays,
              now: now,
              latestAction: (actionHistory[entry.loan.id] ?? const []).isEmpty
                  ? null
                  : actionHistory[entry.loan.id]!.first,
              actionHistory: actionHistory[entry.loan.id] ?? const [],
              paymentHistory: paymentHistory[entry.loan.id] ?? const [],
              interestPeriodSnapshots:
                  interestPeriodSnapshots[entry.loan.id] ?? const [],
              itemPhotoPaths: photoPaths[entry.loan.id] ?? const [],
            ),
          )
          .toList()
        ..sort(_sortCases);

      _state = _state.copyWith(
        allCases: cases,
        stats: _buildStats(cases, now),
        noticePeriodDays: noticeDays,
        isLoading: false,
        clearError: true,
      );
      _applyFilters();
    } catch (error) {
      AppLogger.debug('Contact & Recovery load failed: $error');
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Notice and recovery records could not be loaded.',
      );
      notifyListeners();
    }
  }

  void setFilter(ContactRecoveryFilter filter) {
    _state = _state.copyWith(filter: filter);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    _applyFilters();
  }

  int _coveredInterestMonths(
    GirviLoanWithCustomer entry,
    List<GirviPaymentModel> payments,
  ) {
    final ledgerMonths = payments.fold<int>(0, (sum, payment) {
      if (payment.type != GirviPaymentType.interest &&
          payment.type != GirviPaymentType.partialInterest) {
        return sum;
      }
      return sum + (payment.monthsCovered ?? 0).clamp(0, 1000000);
    });
    if (ledgerMonths > 0) return ledgerMonths;

    final paidThrough = entry.loan.lastInterestPaidDate;
    if (paidThrough != null && paidThrough.isAfter(entry.loan.startDate)) {
      return GirviLoanModel.chargeableMonthsBetween(
        entry.loan.startDate,
        paidThrough,
      );
    }

    // A payment without a stored covered period cannot safely be converted
    // into months from the current rate. Treat it as unverified coverage and
    // keep the account in the conservative risk bucket.
    return 0;
  }

  Future<Map<int, List<String>>> _loadItemPhotoPaths(List<int> loanIds) async {
    if (loanIds.isEmpty) return const {};

    final items = await (_db.select(_db.girviLoanItems)
          ..where((item) => item.girviId.isIn(loanIds)))
        .get();
    if (items.isEmpty) return const {};

    final itemLoanIds = <int, int>{};
    for (final item in items) {
      itemLoanIds[item.id] = item.girviId;
    }

    final photos = await (_db.select(_db.girviItemPhotos)
          ..where((photo) => photo.itemId.isIn(itemLoanIds.keys.toList()))
          ..orderBy([
            (photo) => drift.OrderingTerm.asc(photo.itemId),
            (photo) => drift.OrderingTerm.asc(photo.sortOrder),
          ]))
        .get();

    final byLoan = <int, List<String>>{};
    for (final photo in photos) {
      final loanId = itemLoanIds[photo.itemId];
      final path = photo.filePath.trim();
      if (loanId != null && path.isNotEmpty) {
        byLoan.putIfAbsent(loanId, () => <String>[]).add(path);
      }
    }
    return byLoan;
  }

  double _verifiedInterestDue(
    GirviLoanWithCustomer entry,
    List<GirviInterestPeriodSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) return entry.netInterestDue;
    final gross = snapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.periodInterest,
    );
    final due = gross - entry.interestPaidTotal - entry.interestDiscountTotal;
    return due <= 0 ? 0 : due;
  }

  Future<Map<int, List<GirviPaymentModel>>> _loadPaymentHistory(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};
    return _repository.getPaymentModelsForLoans(loanIds);
  }

  Future<bool> initiateCollateralRecovery(ContactRecoveryCase item) async {
    if (!item.canInitiateCollateralRecovery) {
      _state = _state.copyWith(
        inlineMessage:
            'Collateral recovery can be started only after the final review cycle is complete.',
      );
      notifyListeners();
      return false;
    }

    try {
      await _noticeActionRepository.recordCollateralRecoveryInitiated(
        girviId: item.loan.id,
        noticePeriodDays: item.noticePeriodDays,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage:
            'Ticket ${item.loan.ticketNo} moved to collateral recovery.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery initiation failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Collateral recovery could not be started.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordNoticeDraft(
    ContactRecoveryCase item,
    String noticeText,
  ) async {
    try {
      await _noticeActionRepository.recordNoticeDraft(
        girviId: item.loan.id,
        noticeText: noticeText,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage:
            'Legal notice prepared and copied for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery notice draft audit failed: $error');
      _state = _state.copyWith(
        inlineMessage:
            'Notice copied, but notice history could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordNoticePrepared(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    String noticeText, {
    String? autoGeneratedText,
  }) async {
    try {
      if (item.nextNoticeType != noticeType || !item.canPrepareNextNotice) {
        throw StateError('This notice stage is not eligible yet.');
      }
      await _noticeActionRepository.recordNoticePrepared(
        girviId: item.loan.id,
        noticeType: noticeType,
        noticeText: noticeText,
        noticePeriodDays: item.noticePeriodDays,
        autoGeneratedText: autoGeneratedText,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage:
            '${noticeType.label} saved for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery notice stage audit failed: $error');
      _state = _state.copyWith(
        inlineMessage: '${noticeType.label} could not be saved.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordNoticeDeliveryProof({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required String noticeText,
    required String actionType,
    required String deliveryChannel,
    required String deliveryStatus,
    String? deliveryReference,
  }) async {
    try {
      await _noticeActionRepository.recordNoticeDeliveryProof(
        girviId: item.loan.id,
        noticeType: noticeType,
        noticeText: noticeText,
        actionType: actionType,
        deliveryChannel: deliveryChannel,
        deliveryStatus: deliveryStatus,
        deliveryReference: deliveryReference,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage:
            '${noticeType.label} $deliveryStatus for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery delivery proof failed: $error');
      _state = _state.copyWith(
        inlineMessage: '${noticeType.label} proof could not be recorded.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeDisposalSettlement({
    required ContactRecoveryCase item,
    required double pledgedValuation,
    required double recoveredAmount,
    required double penaltyAmount,
    required String note,
    String paymentMode = 'CASH',
    int? bankAccountId,
  }) async {
    if (!item.canCloseDisposal) {
      _state = _state.copyWith(
        inlineMessage:
            'Send this ticket to collateral recovery before closing settlement.',
      );
      notifyListeners();
      return false;
    }
    if (pledgedValuation <= 0 || recoveredAmount <= 0) {
      _state = _state.copyWith(
        inlineMessage:
            'Enter a valid pledged valuation and recovered amount before closing settlement.',
      );
      notifyListeners();
      return false;
    }

    try {
      final normalizedPledgedValuation = _money(pledgedValuation);
      final normalizedRecoveredAmount = _money(recoveredAmount);
      final normalizedPenaltyAmount = _money(penaltyAmount);
      final settlementTotal = _money(
        item.verifiedTotalPayable + normalizedPenaltyAmount,
      );
      final balanceDue = normalizedRecoveredAmount >= settlementTotal
          ? 0.0
          : _money(settlementTotal - normalizedRecoveredAmount);
      final surplus = normalizedRecoveredAmount > settlementTotal
          ? _money(normalizedRecoveredAmount - settlementTotal)
          : 0.0;
      final normalizedPaymentMode = paymentMode.trim().toUpperCase();
      if (!_isSupportedRecoveryPaymentMode(normalizedPaymentMode)) {
        throw ArgumentError.value(paymentMode, 'paymentMode');
      }

      await _db.transaction(() async {
        final alreadySettled = await (_db.select(_db.girviNoticeActions)
              ..where(
                (action) =>
                    action.girviId.equals(item.loan.id) &
                    action.actionType
                        .equals(GirviNoticeActionTypes.disposalSettled),
              )
              ..limit(1))
            .getSingleOrNull();
        if (alreadySettled != null) {
          throw StateError('This recovery settlement is already closed.');
        }

        final referenceId = 'GIRVI-RECOVERY-${item.loan.ticketNo}';
        final transactionId = _recoveryTransactionId(item.loan.id);
        final settledAt = DateTime.now();
        if (normalizedPaymentMode == 'CASH') {
          await _db.into(_db.cashTransactions).insert(
                CashTransactionsCompanion.insert(
                  txnId: transactionId,
                  txnDate: settledAt,
                  type: 'INCOME',
                  category: 'DUE_COLLECTION',
                  amount: drift.Value(normalizedRecoveredAmount),
                  paymentMode: drift.Value(normalizedPaymentMode),
                  description: drift.Value(
                    'Girvi recovery proceeds for ${item.loan.ticketNo}',
                  ),
                  referenceId: drift.Value(referenceId),
                  referenceType: const drift.Value('GIRVI_RECOVERY'),
                  partyName: drift.Value(item.account.customerName),
                  isAutoGenerated: const drift.Value(true),
                  isVoided: const drift.Value(false),
                ),
              );
        } else {
          if (bankAccountId == null) {
            throw StateError(
                'Select an active bank account for non-cash recovery.');
          }
          final bankAccount = await (_db.select(_db.bankAccounts)
                ..where(
                  (account) =>
                      account.id.equals(bankAccountId) &
                      account.isActive.equals(true),
                )
                ..limit(1))
              .getSingleOrNull();
          if (bankAccount == null) {
            throw StateError('The selected bank account is no longer active.');
          }
          await _db.into(_db.bankTransactions).insert(
                BankTransactionsCompanion.insert(
                  txnId: transactionId,
                  accountId: bankAccountId,
                  txnDate: settledAt,
                  type: 'CREDIT',
                  category: 'DUE_COLLECTION',
                  amount: drift.Value(normalizedRecoveredAmount),
                  paymentMode: drift.Value(normalizedPaymentMode),
                  description: drift.Value(
                    'Girvi recovery proceeds for ${item.loan.ticketNo}',
                  ),
                  referenceId: drift.Value(referenceId),
                  referenceType: const drift.Value('GIRVI_RECOVERY'),
                  partyName: drift.Value(item.account.customerName),
                  isAutoGenerated: const drift.Value(true),
                  isVoided: const drift.Value(false),
                ),
              );
        }

        if (balanceDue > 0) {
          await _db.into(_db.customerAccountLedger).insert(
                CustomerAccountLedgerCompanion.insert(
                  customerId: item.loan.customerId,
                  entryType: 'DEBIT',
                  sourceType: 'GIRVI_RECOVERY_BALANCE',
                  sourceReference: drift.Value(referenceId),
                  amount: drift.Value(balanceDue),
                  paymentMode: drift.Value(normalizedPaymentMode),
                  notes: drift.Value(
                    'Unrecovered balance after recovery settlement for ${item.loan.ticketNo}',
                  ),
                  entryDate: drift.Value(settledAt),
                  isVoided: const drift.Value(false),
                ),
              );
        }
        if (surplus > 0) {
          await _db.into(_db.customerAccountLedger).insert(
                CustomerAccountLedgerCompanion.insert(
                  customerId: item.loan.customerId,
                  entryType: 'CREDIT',
                  sourceType: 'GIRVI_RECOVERY_SURPLUS',
                  sourceReference: drift.Value(referenceId),
                  amount: drift.Value(surplus),
                  paymentMode: drift.Value(normalizedPaymentMode),
                  notes: drift.Value(
                    'Customer surplus payable after recovery settlement for ${item.loan.ticketNo}',
                  ),
                  entryDate: drift.Value(settledAt),
                  isVoided: const drift.Value(false),
                ),
              );
        }

        final updated = await _repository.updateStatus(
          item.loan.id,
          GirviStatus.auctioned,
        );
        if (!updated) {
          throw StateError('Loan status could not be updated.');
        }

        await (_db.update(_db.girviLoanItems)
              ..where((loanItem) => loanItem.girviId.equals(item.loan.id)))
            .write(
          GirviLoanItemsCompanion(
            recoveryDispositionStatus: const drift.Value('DISPOSED'),
            recoveryDispositionReference: drift.Value(referenceId),
            recoveryDisposedAt: drift.Value(settledAt),
          ),
        );

        await _noticeActionRepository.recordDisposalSettlement(
          girviId: item.loan.id,
          pledgedValuation: normalizedPledgedValuation,
          recoveredAmount: normalizedRecoveredAmount,
          penaltyAmount: normalizedPenaltyAmount,
          settlementTotal: settlementTotal,
          customerBalanceDue: balanceDue,
          customerSurplus: surplus,
          note: note,
          performedBy: _operatorIdentity(),
        );
      });

      _state = _state.copyWith(
        inlineMessage:
            'Recovery settlement closed for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery settlement failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Recovery settlement could not be closed.',
      );
      notifyListeners();
      return false;
    }
  }

  void showInlineMessage(String message) {
    _state = _state.copyWith(inlineMessage: message);
    notifyListeners();
  }

  double _money(double value) => (value * 100).roundToDouble() / 100;

  bool _isSupportedRecoveryPaymentMode(String value) => const {
        'CASH',
        'UPI',
        'NEFT',
        'RTGS',
        'IMPS',
        'CHEQUE',
      }.contains(value);

  String _recoveryTransactionId(int loanId) =>
      'GRVREC-$loanId-${DateTime.now().microsecondsSinceEpoch}';

  String _operatorIdentity() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'LOCAL_OPERATOR';
      final email = user.email?.trim();
      return email == null || email.isEmpty ? user.uid : '$email (${user.uid})';
    } catch (_) {
      return 'LOCAL_OPERATOR';
    }
  }

  void dismissInlineMessage() {
    _state = _state.copyWith(clearInlineMessage: true);
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<ContactRecoveryCase>.from(_state.allCases);

    switch (_state.filter) {
      case ContactRecoveryFilter.firstNotice:
        result = result
            .where((item) => item.stage == ContactRecoveryStage.firstNoticeDue)
            .toList();
        break;
      case ContactRecoveryFilter.secondNotice:
        result = result
            .where((item) => item.stage == ContactRecoveryStage.secondNoticeDue)
            .toList();
        break;
      case ContactRecoveryFilter.finalNotice:
        result = result
            .where((item) => item.stage == ContactRecoveryStage.finalNoticeDue)
            .toList();
        break;
      case ContactRecoveryFilter.disposalReady:
        result = result
            .where((item) => item.stage == ContactRecoveryStage.disposalReady)
            .toList();
        break;
      case ContactRecoveryFilter.recoveryInProgress:
        result = result
            .where(
                (item) => item.stage == ContactRecoveryStage.recoveryInProgress)
            .toList();
        break;
      case ContactRecoveryFilter.settled:
        result = result
            .where((item) => item.stage == ContactRecoveryStage.settled)
            .toList();
        break;
      case ContactRecoveryFilter.all:
        result = result
            .where((item) => item.stage != ContactRecoveryStage.settled)
            .toList();
        break;
    }

    final query = _state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) {
        final loan = item.loan;
        final account = item.account;
        return loan.ticketNo.toLowerCase().contains(query) ||
            account.customerName.toLowerCase().contains(query) ||
            account.customerMobile.contains(query) ||
            account.customerAddress.toLowerCase().contains(query) ||
            loan.itemDescription.toLowerCase().contains(query) ||
            loan.itemSummary.toLowerCase().contains(query) ||
            loan.metalType.toLowerCase().contains(query) ||
            loan.metalPurity.toLowerCase().contains(query) ||
            item.stageLabel.toLowerCase().contains(query) ||
            item.stageDescription.toLowerCase().contains(query) ||
            item.noticesSentLabel.toLowerCase().contains(query) ||
            item.preparedNoticeActions.any(
              (action) =>
                  action.displayLabel.toLowerCase().contains(query) ||
                  (action.noticeText?.toLowerCase().contains(query) ?? false),
            ) ||
            (item.latestAction?.displayLabel.toLowerCase().contains(query) ??
                false);
      }).toList();
    }

    result.sort(_sortCases);
    _state = _state.copyWith(visibleCases: result, isLoading: false);
    notifyListeners();
  }

  ContactRecoveryStats _buildStats(
    List<ContactRecoveryCase> cases,
    DateTime now,
  ) {
    final activeCases = cases
        .where((item) => item.stage != ContactRecoveryStage.settled)
        .toList();

    return ContactRecoveryStats(
      totalCases: activeCases.length,
      noticeDueCount: activeCases.length,
      finalNoticeCount: activeCases
          .where((item) => item.stage == ContactRecoveryStage.finalNoticeDue)
          .length,
      disposalReadyCount: activeCases
          .where((item) => item.stage == ContactRecoveryStage.disposalReady)
          .length,
      recoveryInProgressCount: activeCases
          .where(
              (item) => item.stage == ContactRecoveryStage.recoveryInProgress)
          .length,
      settledCount: cases
          .where((item) => item.stage == ContactRecoveryStage.settled)
          .length,
      principalExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.account.principalDue,
      ),
      interestExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.verifiedInterestDue,
      ),
      totalExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.verifiedTotalPayable,
      ),
      lastUpdatedAt: _timeFormat.format(now),
    );
  }

  int _sortCases(ContactRecoveryCase a, ContactRecoveryCase b) {
    final stageCompare = _stageRank(b.stage).compareTo(_stageRank(a.stage));
    if (stageCompare != 0) return stageCompare;
    final overdueCompare = b.overdueDays.compareTo(a.overdueDays);
    if (overdueCompare != 0) return overdueCompare;
    return b.verifiedTotalPayable.compareTo(a.verifiedTotalPayable);
  }

  int _stageRank(ContactRecoveryStage stage) {
    switch (stage) {
      case ContactRecoveryStage.disposalReady:
        return 5;
      case ContactRecoveryStage.recoveryInProgress:
        return 6;
      case ContactRecoveryStage.finalNoticeDue:
        return 4;
      case ContactRecoveryStage.secondNoticeDue:
        return 3;
      case ContactRecoveryStage.firstNoticeDue:
        return 2;
      case ContactRecoveryStage.settled:
        return 1;
    }
  }
}
