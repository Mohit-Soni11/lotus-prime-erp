import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_customer_response_model.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/recovery_pledged_item_detail.dart';
import '../../repositories/girvi/girvi_notice_action_repository.dart';
import '../../repositories/girvi/girvi_customer_response_repository.dart';
import '../../repositories/girvi/girvi_notice_document_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import '../../repositories/girvi/girvi_interest_period_snapshot_repository.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import 'girvi_notice_eligibility.dart';
import 'recovery_completion_note.dart';

class ContactRecoveryController extends ChangeNotifier {
  ContactRecoveryController({
    required String ticketNo,
    AppDatabase? db,
    GirviRepository? repository,
    GirviBillingRepo? billingRepo,
    GirviNoticeActionRepository? noticeActionRepository,
    GirviCustomerResponseRepository? customerResponseRepository,
    GirviNoticeDocumentRepository? noticeDocumentRepository,
  }) : _ticketNo = ticketNo.trim() {
    final resolvedDb = db ?? AppDatabase();
    _db = resolvedDb;
    _repository = repository ?? GirviRepository(resolvedDb);
    _billingRepo = billingRepo ?? GirviBillingRepo(db: resolvedDb);
    _noticeActionRepository =
        noticeActionRepository ?? GirviNoticeActionRepository(resolvedDb);
    _customerResponseRepository = customerResponseRepository ??
        GirviCustomerResponseRepository(resolvedDb);
    _noticeDocumentRepository =
        noticeDocumentRepository ?? GirviNoticeDocumentRepository(resolvedDb);
  }

  late final AppDatabase _db;
  final String _ticketNo;
  late final GirviRepository _repository;
  late final GirviBillingRepo _billingRepo;
  late final GirviNoticeActionRepository _noticeActionRepository;
  late final GirviCustomerResponseRepository _customerResponseRepository;
  late final GirviNoticeDocumentRepository _noticeDocumentRepository;
  late final GirviInterestPeriodSnapshotRepository
      _interestPeriodSnapshotRepository =
      GirviInterestPeriodSnapshotRepository(_db);

  AppDatabase get database => _db;

  Future<List<RecoveryPledgedItemDetail>> loadRecoveryPledgedItems(
    int girviId,
  ) async {
    final items = await (_db.select(_db.girviLoanItems)
          ..where((item) => item.girviId.equals(girviId))
          ..orderBy([(item) => drift.OrderingTerm.asc(item.serialNo)]))
        .get();
    return [
      for (final item in items)
        RecoveryPledgedItemDetail(
          itemName: item.itemName,
          metalType: item.metalType,
          purity: item.purity,
          pieces: item.pieces,
          netWeight: item.netWeight,
        ),
    ];
  }

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
  bool _isDisposed = false;
  int _loadRevision = 0;

  Future<void> load({bool keepInlineMessage = false}) async {
    if (_isDisposed) return;
    final revision = ++_loadRevision;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearInlineMessage: !keepInlineMessage,
    );
    notifyListeners();

    try {
      if (_ticketNo.isEmpty) {
        _state = _state.copyWith(allCases: [], isLoading: false);
        notifyListeners();
        return;
      }
      final selectedLoan = await _repository.getLoanByTicket(_ticketNo);
      if (_isDisposed || revision != _loadRevision) return;
      if (selectedLoan == null) {
        _state = _state.copyWith(allCases: [], isLoading: false);
        notifyListeners();
        return;
      }
      await _repository.syncOverdueStatus();
      final billing = await _billingRepo.fetch();
      final noticeDays = billing.noticeDays <= 0 ? 7 : billing.noticeDays;
      final now = DateTime.now();
      final loans = await _repository.getLoansWithCustomer(
        loanId: selectedLoan.id,
        includeAuctioned: true,
      );
      final workflowIds = await _loadOpenWorkflowIds(
        loans.map((entry) => entry.loan.id).toList(growable: false),
      );

      final candidateAccounts = loans.where((entry) {
        final status = entry.loan.girviStatus;
        if (status == GirviStatus.released ||
            status == GirviStatus.readyForDelivery) {
          return false;
        }
        if (status == GirviStatus.auctioned) return true;
        final quote = entry.interestQuoteAt(now);
        if (!quote.totalPayable.isFinite || quote.totalPayable <= 0.01) {
          return false;
        }
        final maturityDate = entry.loan.maturityDate ??
            GirviLoanModel.addChargeableMonths(
              entry.loan.startDate,
              entry.loan.durationMonths,
            );
        return GirviNoticeEligibility.hasMaturedBalance(
              status: status,
              maturityDate: maturityDate,
              principalDue: entry.principalDue,
              interestDue: quote.interestOutstanding,
              asOf: now,
            ) ||
            workflowIds.contains(entry.loan.id);
      }).toList();
      // Only notice candidates need persisted statement timelines.
      final interestPeriodSnapshots = await _interestPeriodSnapshotRepository
          .synchronizeForLoans(candidateAccounts, asOf: now);
      final paymentHistory = await _loadPaymentHistory(
        candidateAccounts.map((entry) => entry.loan.id).toList(growable: false),
      );
      final actionHistory = await _noticeActionRepository.actionsByGirviIds(
        candidateAccounts.map((entry) => entry.loan.id).toList(growable: false),
      );
      final customerResponses = await _customerResponseRepository.byGirviIds(
        candidateAccounts.map((entry) => entry.loan.id).toList(),
      );
      final noticeDocuments = await _noticeDocumentRepository.byGirviIds(
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
              latestAction: _latestCurrentNoticeAction(
                actionHistory[entry.loan.id] ?? const [],
              ),
              actionHistory: actionHistory[entry.loan.id] ?? const [],
              customerResponses: customerResponses[entry.loan.id] ?? const [],
              noticeDocuments: noticeDocuments[entry.loan.id] ?? const [],
              paymentHistory: paymentHistory[entry.loan.id] ?? const [],
              interestPeriodSnapshots:
                  interestPeriodSnapshots[entry.loan.id] ?? const [],
              itemPhotoPaths: photoPaths[entry.loan.id] ?? const [],
            ),
          )
          .toList();

      if (_isDisposed || revision != _loadRevision) return;

      _state = _state.copyWith(
        allCases: cases,
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
    } catch (error) {
      if (_isDisposed || revision != _loadRevision) return;
      AppLogger.debug('Contact & Recovery load failed: $error');
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Notice and recovery records could not be loaded.',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadRevision++;
    super.dispose();
  }

  GirviNoticeAction? _latestCurrentNoticeAction(
    List<GirviNoticeAction> actions,
  ) {
    final formal =
        actions.where((action) => action.isFormalNoticePreparation).firstOrNull;
    if (formal == null) return null;
    return actions.where((action) {
      if (!GirviNoticeActionTypes.recordableTypes.contains(action.actionType)) {
        return false;
      }
      if (action.isFormalNoticePreparation) return true;
      if (action.noticeActionId != null) {
        return action.noticeActionId == formal.id;
      }
      return !action.actionAt.isBefore(formal.actionAt);
    }).firstOrNull;
  }

  Future<Set<int>> _loadOpenWorkflowIds(List<int> loanIds) async {
    if (loanIds.isEmpty) return <int>{};
    await _noticeActionRepository.ensureSchema();
    final rows = await (_db.select(_db.girviNoticeActions)
          ..where((action) =>
              action.girviId.isIn(loanIds) &
              action.actionType.equals(GirviNoticeActionTypes.noticePrepared)))
        .get();
    return rows.map((row) => row.girviId).toSet();
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

  Future<Map<int, List<GirviPaymentModel>>> _loadPaymentHistory(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};
    return _repository.getPaymentModelsForLoans(loanIds);
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
    int? noticePeriodDays,
    String? autoGeneratedText,
    Map<GirviNoticeLanguage, String>? noticeDocuments,
    Map<GirviNoticeLanguage, String>? autoGeneratedDocuments,
    String? brandingSnapshot,
    GirviNoticeLanguage primaryLanguage = GirviNoticeLanguage.english,
  }) async {
    try {
      if (item.nextNoticeType != noticeType || !item.canPrepareNotice) {
        throw StateError('This formal notice cannot be prepared now.');
      }
      await _noticeActionRepository.recordNoticePrepared(
        girviId: item.loan.id,
        noticeType: noticeType,
        noticeText: noticeText,
        noticePeriodDays: noticePeriodDays ?? item.noticePeriodDays,
        autoGeneratedText: autoGeneratedText,
        noticeDocuments: noticeDocuments,
        autoGeneratedDocuments: autoGeneratedDocuments,
        brandingSnapshot: brandingSnapshot,
        primaryLanguage: primaryLanguage,
        supersedesNoticeActionId: item.requiresCorrectedFormalNotice
            ? item.formalNoticeAction?.id
            : null,
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
      AppLogger.debug('Formal notice approval failed: $error');
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
    GirviNoticeLanguage? noticeLanguage,
    int? noticeActionId,
    String? deliveryReference,
    DateTime? deliveredAt,
  }) async {
    try {
      await _noticeActionRepository.recordNoticeDeliveryProof(
        girviId: item.loan.id,
        noticeType: noticeType,
        noticeText: noticeText,
        actionType: actionType,
        deliveryChannel: deliveryChannel,
        deliveryStatus: deliveryStatus,
        noticeLanguage: noticeLanguage,
        noticeActionId: noticeActionId,
        deliveryReference: deliveryReference,
        deliveredAt: deliveredAt,
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

  Future<bool> recordCustomerResponse({
    required ContactRecoveryCase item,
    required GirviNoticeAction notice,
    required GirviCustomerResponseKind kind,
    required GirviContactChannel channel,
    required String responseText,
    DateTime? promiseDueAt,
  }) async {
    try {
      final stage = notice.resolvedNoticeStage;
      if (!notice.isFormalNoticePreparation || stage != 1) {
        throw StateError(
            'A customer response must be linked to a saved notice.');
      }
      await _customerResponseRepository.record(
        girviId: item.loan.id,
        noticeActionId: notice.id,
        noticeStage: stage,
        kind: kind,
        channel: channel,
        responseText: responseText,
        promiseDueAt: promiseDueAt,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage: 'Customer response recorded for ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Customer response recording failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Customer response could not be recorded.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveCustomerFollowUp({
    required ContactRecoveryCase item,
    required int responseId,
    required GirviPromiseStatus status,
    String? resolutionNote,
  }) async {
    try {
      await _customerResponseRepository.resolve(
        responseId: responseId,
        status: status,
        resolutionNote: resolutionNote,
        performedBy: _operatorIdentity(),
      );
      _state = _state.copyWith(
        inlineMessage: 'Customer promise updated for ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Customer promise resolution failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Customer promise could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeItemRecovery({
    required ContactRecoveryCase item,
    required double recoveredAmount,
    String note = '',
    String? paymentMode,
    String dispositionMethod = 'MELTED',
    int? bankAccountId,
  }) async {
    if (!item.canCloseDisposal && !item.canInitiateCollateralRecovery) {
      _state = _state.copyWith(
        inlineMessage: item.recoveryBlockedMessage,
      );
      notifyListeners();
      return false;
    }
    if (!recoveredAmount.isFinite || recoveredAmount < 0) {
      _state = _state.copyWith(
        inlineMessage: 'Enter a valid actual recovery amount.',
      );
      notifyListeners();
      return false;
    }

    try {
      final normalizedRecoveredAmount = _money(recoveredAmount);
      final normalizedDispositionMethod =
          dispositionMethod.trim().toUpperCase();
      if (!const {'MELTED', 'SOLD'}.contains(normalizedDispositionMethod)) {
        throw ArgumentError.value(dispositionMethod, 'dispositionMethod');
      }
      final isMelted = normalizedDispositionMethod == 'MELTED';
      final normalizedPaymentMode = paymentMode?.trim().toUpperCase();
      if (isMelted && normalizedRecoveredAmount != 0) {
        throw StateError('Melting does not record a cash recovery amount.');
      }
      if (!isMelted && normalizedRecoveredAmount <= 0) {
        throw StateError('Enter the actual sale proceeds received.');
      }
      if (!isMelted &&
          !_isSupportedRecoveryPaymentMode(normalizedPaymentMode ?? '')) {
        throw ArgumentError.value(paymentMode, 'paymentMode');
      }

      await _db.transaction(() async {
        if (!item.canCloseDisposal) {
          await _noticeActionRepository.recordCollateralRecoveryInitiated(
            girviId: item.loan.id,
            noticePeriodDays: item.noticePeriodDays,
            performedBy: _operatorIdentity(),
          );
        }
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

        final currentLoan = await _repository.getLoanById(item.loan.id);
        if (currentLoan == null ||
            GirviStatus.fromDb(currentLoan.status).isClosed ||
            GirviStatus.fromDb(currentLoan.status) ==
                GirviStatus.readyForDelivery) {
          throw StateError(
              'The pledge account is no longer open for recovery.');
        }
        final currentAccounts = await _repository.getLoansWithCustomer(
          loanId: item.loan.id,
        );
        if (currentAccounts.isEmpty) {
          throw StateError('The current pledge account could not be loaded.');
        }
        final currentPayable = _money(
          currentAccounts.single.interestQuoteAt(DateTime.now()).totalPayable,
        );
        if ((currentPayable - _money(item.verifiedTotalPayable)).abs() > 0.01) {
          throw StateError('Recovery balance changed. Refresh and review it.');
        }
        final recoveryDue = normalizedRecoveredAmount >= currentPayable
            ? 0.0
            : _money(currentPayable - normalizedRecoveredAmount);
        final surplus = normalizedRecoveredAmount > currentPayable
            ? _money(normalizedRecoveredAmount - currentPayable)
            : 0.0;

        final referenceId = 'GIRVI-RECOVERY-${item.loan.ticketNo}';
        final transactionId = _recoveryTransactionId(item.loan.id);
        final settledAt = DateTime.now();
        if (!isMelted && normalizedPaymentMode == 'CASH') {
          await _db.into(_db.cashTransactions).insert(
                CashTransactionsCompanion.insert(
                  txnId: transactionId,
                  txnDate: settledAt,
                  type: 'INCOME',
                  category: 'DUE_COLLECTION',
                  amount: drift.Value(normalizedRecoveredAmount),
                  paymentMode: drift.Value(normalizedPaymentMode!),
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
        } else if (!isMelted) {
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
                  paymentMode: drift.Value(normalizedPaymentMode!),
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
            recoveryDispositionStatus: drift.Value(normalizedDispositionMethod),
            recoveryDispositionReference: drift.Value(referenceId),
            recoveryDisposedAt: drift.Value(settledAt),
          ),
        );

        await _noticeActionRepository.recordDisposalSettlement(
          girviId: item.loan.id,
          recoveredAmount: normalizedRecoveredAmount,
          settlementTotal: currentPayable,
          customerBalanceDue: recoveryDue,
          customerSurplus: surplus,
          note: recoveryCompletionNote(
            dispositionMethod: normalizedDispositionMethod,
            ticketNo: item.loan.ticketNo,
            amountDue: currentPayable,
            recoveredAmount: normalizedRecoveredAmount,
            recoveredAt: settledAt,
            remarks: note,
          ),
          performedBy: _operatorIdentity(),
        );
      });

      _state = _state.copyWith(
        inlineMessage: normalizedDispositionMethod == 'MELTED'
            ? 'Item marked melted; account ${item.loan.ticketNo} closed with recovery due recorded.'
            : 'Item sale recorded and account ${item.loan.ticketNo} closed.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Contact & Recovery settlement failed: $error');
      _state = _state.copyWith(
        inlineMessage: error is StateError
            ? error.message.toString()
            : 'Recovery settlement could not be closed.',
      );
      notifyListeners();
      if (error is StateError && !_isDisposed) {
        await load(keepInlineMessage: true);
      }
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
}
