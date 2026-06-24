import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/logging/app_logger.dart';
import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/notice_auction_model.dart';
import '../../repositories/girvi/girvi_notice_action_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';

class NoticeAuctionController extends ChangeNotifier {
  NoticeAuctionController({
    AppDatabase? db,
    GirviRepository? repository,
    GirviBillingRepo? billingRepo,
    GirviNoticeActionRepository? noticeActionRepository,
  }) {
    final resolvedDb = db ?? AppDatabase();
    _repository = repository ?? GirviRepository(resolvedDb);
    _billingRepo = billingRepo ?? GirviBillingRepo(db: resolvedDb);
    _noticeActionRepository =
        noticeActionRepository ?? GirviNoticeActionRepository(resolvedDb);
  }

  late final GirviRepository _repository;
  late final GirviBillingRepo _billingRepo;
  late final GirviNoticeActionRepository _noticeActionRepository;

  NoticeAuctionState _state = NoticeAuctionState.initial();
  NoticeAuctionState get state => _state;

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
      final noticeDays = billing.noticeDays <= 0 ? 30 : billing.noticeDays;
      final now = DateTime.now();
      final loans = await _repository.getLoansWithCustomer();

      final candidateAccounts = loans.where((entry) {
        final status = entry.loan.girviStatus;
        if (status == GirviStatus.auctioned) return true;
        if (status == GirviStatus.released ||
            status == GirviStatus.readyForDelivery) {
          return false;
        }
        return entry.loan.maturityDate != null &&
            now.isAfter(entry.loan.maturityDate!);
      }).toList();
      final actionHistory = await _noticeActionRepository.actionsByGirviIds(
        candidateAccounts.map((entry) => entry.loan.id).toList(),
      );

      final cases = candidateAccounts
          .map(
            (entry) => NoticeAuctionCase(
              account: entry,
              noticePeriodDays: noticeDays,
              now: now,
              latestAction: (actionHistory[entry.loan.id] ?? const []).isEmpty
                  ? null
                  : actionHistory[entry.loan.id]!.first,
              actionHistory: actionHistory[entry.loan.id] ?? const [],
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
      AppLogger.debug('Notice & Auction load failed: $error');
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Notice and auction records could not be loaded.',
      );
      notifyListeners();
    }
  }

  void setFilter(NoticeAuctionFilter filter) {
    _state = _state.copyWith(filter: filter);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    _applyFilters();
  }

  Future<bool> markAuctioned(NoticeAuctionCase item) async {
    try {
      final updated = await _repository.updateStatus(
        item.loan.id,
        GirviStatus.auctioned,
      );
      if (!updated) {
        _state = _state.copyWith(
          inlineMessage: 'Auction status could not be updated.',
        );
        notifyListeners();
        return false;
      }

      await _noticeActionRepository.recordAuctionMarked(girviId: item.loan.id);
      _state = _state.copyWith(
        inlineMessage: 'Ticket ${item.loan.ticketNo} marked as auctioned.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Notice & Auction mark auctioned failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Auction status could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordNoticeDraft(
    NoticeAuctionCase item,
    String noticeText,
  ) async {
    try {
      await _noticeActionRepository.recordNoticeDraft(
        girviId: item.loan.id,
        noticeText: noticeText,
      );
      _state = _state.copyWith(
        inlineMessage:
            'Legal notice prepared and copied for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Notice & Auction notice draft audit failed: $error');
      _state = _state.copyWith(
        inlineMessage:
            'Notice copied, but notice history could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordNoticePrepared(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    String noticeText,
  ) async {
    try {
      await _noticeActionRepository.recordNoticePrepared(
        girviId: item.loan.id,
        noticeType: noticeType,
        noticeText: noticeText,
      );
      _state = _state.copyWith(
        inlineMessage:
            '${noticeType.label} saved for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Notice & Auction notice stage audit failed: $error');
      _state = _state.copyWith(
        inlineMessage: '${noticeType.label} could not be saved.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeDisposalSettlement({
    required NoticeAuctionCase item,
    required double pledgedValuation,
    required double recoveredAmount,
    required double penaltyAmount,
    required String note,
  }) async {
    try {
      final settlementTotal = item.account.totalPayable + penaltyAmount;
      final balanceDue = recoveredAmount >= settlementTotal
          ? 0.0
          : settlementTotal - recoveredAmount;
      final surplus = recoveredAmount > settlementTotal
          ? recoveredAmount - settlementTotal
          : 0.0;

      final updated = await _repository.updateStatus(
        item.loan.id,
        GirviStatus.auctioned,
      );
      if (!updated) {
        _state = _state.copyWith(
          inlineMessage: 'Disposal settlement could not be closed.',
        );
        notifyListeners();
        return false;
      }

      await _noticeActionRepository.recordDisposalSettlement(
        girviId: item.loan.id,
        pledgedValuation: pledgedValuation,
        recoveredAmount: recoveredAmount,
        penaltyAmount: penaltyAmount,
        settlementTotal: settlementTotal,
        customerBalanceDue: balanceDue,
        customerSurplus: surplus,
        note: note,
      );

      _state = _state.copyWith(
        inlineMessage:
            'Disposal settlement closed for ticket ${item.loan.ticketNo}.',
      );
      notifyListeners();
      await load(keepInlineMessage: true);
      return true;
    } catch (error) {
      AppLogger.debug('Notice & Auction disposal settlement failed: $error');
      _state = _state.copyWith(
        inlineMessage: 'Disposal settlement could not be closed.',
      );
      notifyListeners();
      return false;
    }
  }

  void showInlineMessage(String message) {
    _state = _state.copyWith(inlineMessage: message);
    notifyListeners();
  }

  void dismissInlineMessage() {
    _state = _state.copyWith(clearInlineMessage: true);
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<NoticeAuctionCase>.from(_state.allCases);

    switch (_state.filter) {
      case NoticeAuctionFilter.firstNotice:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.firstNoticeDue)
            .toList();
        break;
      case NoticeAuctionFilter.secondNotice:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.secondNoticeDue)
            .toList();
        break;
      case NoticeAuctionFilter.finalNotice:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.finalNoticeDue)
            .toList();
        break;
      case NoticeAuctionFilter.disposalReady:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.disposalReady)
            .toList();
        break;
      case NoticeAuctionFilter.settled:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.settled)
            .toList();
        break;
      case NoticeAuctionFilter.all:
        result = result
            .where((item) => item.stage != NoticeAuctionStage.settled)
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
            item.stageLabel.toLowerCase().contains(query) ||
            (item.latestAction?.displayLabel.toLowerCase().contains(query) ??
                false);
      }).toList();
    }

    result.sort(_sortCases);
    _state = _state.copyWith(visibleCases: result, isLoading: false);
    notifyListeners();
  }

  NoticeAuctionStats _buildStats(
    List<NoticeAuctionCase> cases,
    DateTime now,
  ) {
    final activeCases = cases
        .where((item) => item.stage != NoticeAuctionStage.settled)
        .toList();

    return NoticeAuctionStats(
      totalCases: activeCases.length,
      noticeDueCount: activeCases.length,
      finalNoticeCount: activeCases
          .where((item) => item.stage == NoticeAuctionStage.finalNoticeDue)
          .length,
      disposalReadyCount: activeCases
          .where((item) => item.stage == NoticeAuctionStage.disposalReady)
          .length,
      settledCount: cases
          .where((item) => item.stage == NoticeAuctionStage.settled)
          .length,
      principalExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.account.principalDue,
      ),
      interestExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.account.netInterestDue,
      ),
      totalExposure: activeCases.fold(
        0,
        (sum, item) => sum + item.account.totalPayable,
      ),
      lastUpdatedAt: _timeFormat.format(now),
    );
  }

  int _sortCases(NoticeAuctionCase a, NoticeAuctionCase b) {
    final stageCompare = _stageRank(b.stage).compareTo(_stageRank(a.stage));
    if (stageCompare != 0) return stageCompare;
    final overdueCompare = b.overdueDays.compareTo(a.overdueDays);
    if (overdueCompare != 0) return overdueCompare;
    return b.account.totalPayable.compareTo(a.account.totalPayable);
  }

  int _stageRank(NoticeAuctionStage stage) {
    switch (stage) {
      case NoticeAuctionStage.disposalReady:
        return 5;
      case NoticeAuctionStage.finalNoticeDue:
        return 4;
      case NoticeAuctionStage.secondNoticeDue:
        return 3;
      case NoticeAuctionStage.firstNoticeDue:
        return 2;
      case NoticeAuctionStage.settled:
        return 1;
    }
  }
}
