import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/logging/app_logger.dart';
import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
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
      final latestActions = await _noticeActionRepository.latestByGirviIds(
        candidateAccounts.map((entry) => entry.loan.id).toList(),
      );

      final cases = candidateAccounts
          .map(
            (entry) => NoticeAuctionCase(
              account: entry,
              noticePeriodDays: noticeDays,
              now: now,
              latestAction: latestActions[entry.loan.id],
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
      case NoticeAuctionFilter.noticeDue:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.noticeDue)
            .toList();
        break;
      case NoticeAuctionFilter.auctionReview:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.auctionReview)
            .toList();
        break;
      case NoticeAuctionFilter.auctioned:
        result = result
            .where((item) => item.stage == NoticeAuctionStage.auctioned)
            .toList();
        break;
      case NoticeAuctionFilter.all:
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
    return NoticeAuctionStats(
      totalCases: cases.length,
      noticeDueCount: cases
          .where((item) => item.stage == NoticeAuctionStage.noticeDue)
          .length,
      auctionReviewCount: cases
          .where((item) => item.stage == NoticeAuctionStage.auctionReview)
          .length,
      auctionedCount: cases
          .where((item) => item.stage == NoticeAuctionStage.auctioned)
          .length,
      principalExposure: cases.fold(
        0,
        (sum, item) => sum + item.account.principalDue,
      ),
      interestExposure: cases.fold(
        0,
        (sum, item) => sum + item.account.netInterestDue,
      ),
      totalExposure: cases.fold(
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
      case NoticeAuctionStage.auctionReview:
        return 3;
      case NoticeAuctionStage.noticeDue:
        return 2;
      case NoticeAuctionStage.auctioned:
        return 1;
    }
  }

  @override
  void dispose() {
    unawaited(_db.close());
    super.dispose();
  }
}
