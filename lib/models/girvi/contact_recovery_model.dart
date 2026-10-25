import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/girvi/girvi_theme.dart';
import 'girvi_enums.dart';
import 'girvi_customer_response_model.dart';
import 'girvi_loan_model.dart';
import 'girvi_interest_period_snapshot.dart';
import 'girvi_notice_action_model.dart';
import 'girvi_notice_document_record_model.dart';
import 'girvi_notice_review_period.dart';
import 'girvi_recovery_eligibility.dart';
import 'girvi_recovery_disposition.dart';

part 'contact_recovery_state.dart';

enum ContactRecoveryStage {
  noticeRequired,
  noticePending,
  disposalReady,
  recoveryInProgress,
  settled,
}

enum RecoverySettlementPaymentMethod {
  cash('CASH', 'Cash', false),
  upi('UPI', 'UPI', true),
  neft('NEFT', 'NEFT', true),
  rtgs('RTGS', 'RTGS', true),
  imps('IMPS', 'IMPS', true),
  cheque('CHEQUE', 'Cheque', true);

  const RecoverySettlementPaymentMethod(
    this.dbValue,
    this.label,
    this.requiresBankAccount,
  );

  final String dbValue;
  final String label;
  final bool requiresBankAccount;
}

class RecoveryBankAccountOption {
  const RecoveryBankAccountOption({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;
}

class ContactRecoveryCase {
  final GirviLoanWithCustomer account;
  final int noticePeriodDays;
  final DateTime now;
  final GirviNoticeAction? latestAction;
  final List<GirviNoticeAction> actionHistory;
  final List<GirviPaymentModel> paymentHistory;
  final List<GirviInterestPeriodSnapshot> interestPeriodSnapshots;
  final List<String> itemPhotoPaths;
  final List<GirviCustomerResponse> customerResponses;
  final List<GirviNoticeDocumentRecord> noticeDocuments;
  final GirviRecoveryDisposition? recoveryDisposition;

  const ContactRecoveryCase({
    required this.account,
    required this.noticePeriodDays,
    required this.now,
    this.latestAction,
    this.actionHistory = const [],
    this.paymentHistory = const [],
    this.interestPeriodSnapshots = const [],
    this.itemPhotoPaths = const [],
    this.customerResponses = const [],
    this.noticeDocuments = const [],
    this.recoveryDisposition,
  });

  GirviLoanModel get loan => account.loan;

  bool get isRecoveryClosed => loan.girviStatus == GirviStatus.auctioned;

  bool get hasOutstandingBalance {
    final payable = account.interestQuoteAt(now).totalPayable;
    return payable.isFinite && payable > 0.01;
  }

  bool get hasNoticeActivity => latestAction != null;

  bool get hasItemPhotos =>
      itemPhotoPaths.any((path) => path.trim().isNotEmpty);

  /// Newest first. Only responses linked to a current formal notice appear.
  List<GirviCustomerResponse> get responseTimeline {
    final formalIds = noticeActions.map((action) => action.id).toSet();
    if (formalIds.isEmpty) return const [];
    return customerResponses
        .where((response) => formalIds.contains(response.noticeActionId))
        .toList(growable: false);
  }

  List<GirviCustomerResponse> get openCustomerFollowUps => responseTimeline
      .where(
          (response) => response.requiresFollowUpDate && response.status.isOpen)
      .toList(growable: false);

  List<GirviCustomerResponse> get missedCustomerFollowUps =>
      openCustomerFollowUps
          .where((response) => response.isDueOn(now))
          .toList(growable: false);

  List<GirviCustomerResponse> get currentNoticeResponses {
    final notice = recoveryNoticeAction;
    if (notice == null) return const [];
    final responses = responsesForNotice(notice).toList()
      ..sort((left, right) {
        final date = right.receivedAt.compareTo(left.receivedAt);
        return date != 0 ? date : right.id.compareTo(left.id);
      });
    return responses;
  }

  GirviCustomerResponse? get latestCustomerResponse =>
      currentNoticeResponses.isEmpty ? null : currentNoticeResponses.first;

  /// An explicit recovery request from the latest reply allows immediate
  /// review; unresolved visit and extension dates otherwise remain protected.
  bool get customerAuthorisedRecovery =>
      latestCustomerResponse?.kind.authorisesRecovery ?? false;

  DateTime? get customerFollowUpUntil {
    DateTime? latestDate;
    for (final response in currentNoticeResponses) {
      final due = response.promiseDueAt;
      if (!response.requiresFollowUpDate ||
          !response.status.isOpen ||
          due == null) {
        continue;
      }
      if (latestDate == null || due.isAfter(latestDate)) latestDate = due;
    }
    return latestDate;
  }

  DateTime? get recoveryAvailableAt {
    final notice = recoveryNoticeAction;
    if (notice == null) return null;
    final response = latestCustomerResponse;
    final delivery = firstDispatchActionForNotice(notice);
    return GirviRecoveryEligibility.availableAt(
      deliveredAt: delivery?.deliveredAt ?? delivery?.actionAt,
      noticeDeadline: recoveryReviewAvailableAt,
      responseKind: response?.kind,
      followUpDate: customerFollowUpUntil,
    );
  }

  bool get isRecoveryReady {
    final availableAt = recoveryAvailableAt;
    return availableAt != null && !now.isBefore(availableAt);
  }

  String get recoveryBlockedMessage {
    if (!hasNoticeDispatch) {
      return 'Confirm customer delivery before starting collateral recovery.';
    }
    final response = latestCustomerResponse;
    final followUpUntil = customerFollowUpUntil;
    final availableAt = recoveryAvailableAt;
    if (followUpUntil != null &&
        availableAt != null &&
        now.isBefore(availableAt) &&
        availableAt.isAfter(recoveryReviewAvailableAt ?? now)) {
      return '${response!.kind.label} is active through ${_dateLabel(followUpUntil)}.';
    }
    final deadline = recoveryReviewAvailableAt;
    if (deadline != null && now.isBefore(deadline)) {
      return 'Collateral recovery is available after ${_dateLabel(deadline)}.';
    }
    return 'Collateral recovery is not available for this account.';
  }

  List<GirviNoticeDocumentRecord> documentsForNoticeAction(int actionId) =>
      noticeDocuments
          .where((document) => document.noticeActionId == actionId)
          .toList(growable: false);

  GirviNoticeDocumentRecord? documentForNoticeAction(
    int actionId,
    GirviNoticeLanguage language,
  ) {
    for (final document in noticeDocuments) {
      if (document.noticeActionId == actionId &&
          document.language == language) {
        return document;
      }
    }
    return null;
  }

  List<GirviNoticeAction> get noticeActions =>
      actionHistory.where((action) => action.isNoticePreparation).toList();

  List<GirviNoticeAction> get noticeDeliveryProofActions =>
      actionHistory.where((action) => action.isNoticeDeliveryProof).toList();

  List<GirviNoticeAction> get noticePdfActivityActions =>
      actionHistory.where((action) => action.isNoticePdfActivity).toList();

  List<GirviNoticeAction> get preparedNoticeActions {
    final notices = noticeActions.toList()
      ..sort((a, b) {
        final date = a.actionAt.compareTo(b.actionAt);
        return date != 0 ? date : a.id.compareTo(b.id);
      });
    return notices;
  }

  GirviNoticeAction? get formalNoticeAction {
    for (final action in preparedNoticeActions.reversed) {
      if (action.isFormalNoticePreparation) return action;
    }
    return null;
  }

  bool get requiresCorrectedFormalNotice {
    final approved = formalNoticeAction;
    if (approved == null ||
        hasCollateralRecoveryInitiated ||
        isRecoveryClosed) {
      return false;
    }
    final englishText = documentForNoticeAction(
          approved.id,
          GirviNoticeLanguage.english,
        )?.noticeText ??
        approved.noticeText ??
        '';
    return englishText.contains('Simple Interest Breakdown') &&
        GirviLoanModel.chargeableMonthsBetween(
              loan.startDate,
              loan.releaseDate ?? now,
            ) >
            GirviLoanModel.compoundCycleMonths;
  }

  List<GirviNoticeAction> get earlierFormalNoticeActions =>
      preparedNoticeActions
          .where((action) =>
              action.isFormalNoticePreparation &&
              action.id != formalNoticeAction?.id)
          .toList(growable: false);

  GirviNoticeAction? get recoveryNoticeAction => formalNoticeAction;

  List<GirviCustomerResponse> responsesForNotice(GirviNoticeAction notice) =>
      customerResponses
          .where((response) => response.noticeActionId == notice.id)
          .toList(growable: false);

  List<GirviNoticeAction> _deliveryProofsForNotice(GirviNoticeAction notice) {
    final hashes = {
      if (notice.documentHash != null) notice.documentHash,
      for (final document in documentsForNoticeAction(notice.id))
        document.documentHash,
    };
    final proofs = noticeDeliveryProofActions
        .where((proof) => (proof.noticeActionId != null
            ? proof.noticeActionId == notice.id
            : !proof.actionAt.isBefore(notice.actionAt) &&
                hashes.contains(proof.documentHash)))
        .toList()
      ..sort((a, b) => b.actionAt.compareTo(a.actionAt));
    return proofs;
  }

  GirviNoticeAction? latestDeliveryProofForNotice(GirviNoticeAction notice) {
    final proofs = _deliveryProofsForNotice(notice);
    return proofs.isEmpty ? null : proofs.first;
  }

  GirviNoticeAction? firstDeliveryProofForNotice(GirviNoticeAction notice) {
    final proofs = _deliveryProofsForNotice(notice);
    if (proofs.isEmpty) return null;
    return proofs.reduce((first, proof) {
      final firstAt = first.deliveredAt ?? first.actionAt;
      final proofAt = proof.deliveredAt ?? proof.actionAt;
      return proofAt.isBefore(firstAt) ? proof : first;
    });
  }

  /// Only confirmed customer delivery starts the response period. PDF output
  /// alone cannot prove that the customer received the notice.
  List<GirviNoticeAction> _dispatchActionsForNotice(GirviNoticeAction notice) {
    final actions = _deliveryProofsForNotice(notice);
    actions.sort((a, b) {
      final aAt = a.deliveredAt ?? a.actionAt;
      final bAt = b.deliveredAt ?? b.actionAt;
      return aAt.compareTo(bAt);
    });
    return actions;
  }

  GirviNoticeAction? firstDispatchActionForNotice(GirviNoticeAction notice) {
    final actions = _dispatchActionsForNotice(notice);
    return actions.isEmpty ? null : actions.first;
  }

  GirviNoticeAction? latestPdfActivityForNotice(GirviNoticeAction notice) {
    final activities = noticePdfActivityActions
        .where((action) => action.noticeActionId == notice.id)
        .toList()
      ..sort((a, b) => b.actionAt.compareTo(a.actionAt));
    return activities.isEmpty ? null : activities.first;
  }

  bool get hasVerifiedInterestTimeline => interestPeriodSnapshots.isNotEmpty;

  double get verifiedGrossInterest => interestPeriodSnapshots.fold<double>(
        0,
        (sum, snapshot) => sum + snapshot.periodInterest,
      );

  double get verifiedInterestDue {
    final due = verifiedGrossInterest -
        account.interestPaidTotal -
        account.interestDiscountTotal;
    return due <= 0 ? 0 : due;
  }

  double get verifiedTotalPayable => account.principalDue + verifiedInterestDue;

  int get verifiedChargeableInterestMonths => interestPeriodSnapshots.fold<int>(
        0,
        (sum, snapshot) => sum + snapshot.chargeableMonths,
      );

  bool get hasDisposalSettlement =>
      actionHistory.any((action) => action.isDisposalSettlement);

  DateTime? get recoveryClosedAt {
    final settlements = actionHistory
        .where((action) => action.isDisposalSettlement)
        .toList()
      ..sort((a, b) => b.actionAt.compareTo(a.actionAt));
    return settlements.isEmpty ? null : settlements.first.actionAt;
  }

  bool get hasCollateralRecoveryInitiated {
    final notice = formalNoticeAction;
    if (notice == null) return false;
    return actionHistory.any((action) =>
        action.isCollateralRecoveryInitiated &&
        (action.noticeActionId == notice.id ||
            (action.noticeActionId == null &&
                !action.actionAt.isBefore(notice.actionAt))));
  }

  GirviNoticeType? get nextNoticeType =>
      (formalNoticeAction == null || requiresCorrectedFormalNotice) &&
              !hasDisposalSettlement &&
              !hasCollateralRecoveryInitiated &&
              !isRecoveryClosed
          ? GirviNoticeType.formal
          : null;

  bool get canPrepareNotice => nextNoticeType != null && hasOutstandingBalance;

  DateTime? get recoveryReviewAvailableAt {
    final notice = recoveryNoticeAction;
    if (notice == null) return null;
    final dispatch = firstDispatchActionForNotice(notice);
    return GirviNoticeReviewPeriod.deadline(
      approvedAt: notice.actionAt,
      approvedDeadline: notice.noticeDeadlineAt,
      deliveredAt: dispatch?.deliveredAt ?? dispatch?.actionAt,
      fallbackDays: noticePeriodDays,
    );
  }

  bool get isNoticePeriodComplete {
    final deadline = recoveryReviewAvailableAt;
    return deadline != null && !now.isBefore(deadline);
  }

  bool get hasNoticeDispatch {
    final notice = recoveryNoticeAction;
    return notice != null && firstDispatchActionForNotice(notice) != null;
  }

  bool get canInitiateCollateralRecovery =>
      hasOutstandingBalance &&
      !hasDisposalSettlement &&
      !hasCollateralRecoveryInitiated &&
      !isRecoveryClosed &&
      !requiresCorrectedFormalNotice &&
      hasNoticeDispatch &&
      isRecoveryReady;

  bool get canCloseDisposal =>
      !hasDisposalSettlement &&
      hasCollateralRecoveryInitiated &&
      !isRecoveryClosed &&
      stage == ContactRecoveryStage.recoveryInProgress;

  int get overdueDays {
    final maturity = loan.maturityDate;
    if (maturity == null) return 0;
    return math.max(
        0,
        DateUtils.dateOnly(now)
            .difference(
              DateUtils.dateOnly(maturity),
            )
            .inDays);
  }

  GirviElapsedPeriod get loanAgePeriod => GirviLoanModel.elapsedPeriodBetween(
        loan.startDate,
        recoveryClosedAt ?? now,
      );

  String get loanAgeLabel => loanAgePeriod.displayLabel;

  String get loanAgeMonthsDaysLabel => _monthsDaysLabel(loanAgePeriod);

  int get chargeableInterestMonths => GirviLoanModel.chargeableMonthsBetween(
        loan.startDate,
        recoveryClosedAt ?? now,
      );

  String get chargeableInterestMonthsLabel {
    final months = chargeableInterestMonths;
    return '$months chargeable month${months == 1 ? '' : 's'}';
  }

  List<GirviInterestBreakdownLine> get compoundInterestBreakdown {
    if (GirviInterestCalculationType.isSimple(account.interestType)) {
      return const [];
    }
    return [
      for (final snapshot in interestPeriodSnapshots) snapshot.breakdownLine,
    ];
  }

  double get recordedMonthlyInterestAmount => interestPeriodSnapshots.isEmpty
      ? 0
      : interestPeriodSnapshots.first.interestPerMonth;

  double get recordedInterestClosingAmount => interestPeriodSnapshots.isEmpty
      ? 0
      : interestPeriodSnapshots.last.closingAmount;

  GirviElapsedPeriod get overdueAgePeriod {
    final maturity = loan.maturityDate;
    if (maturity == null) {
      return const GirviElapsedPeriod(years: 0, months: 0, days: 0);
    }
    return GirviLoanModel.elapsedPeriodBetween(
      maturity,
      recoveryClosedAt ?? now,
    );
  }

  String get overdueAgeLabel => overdueAgePeriod.displayLabel;

  String get overdueAgeMonthsDaysLabel => _monthsDaysLabel(overdueAgePeriod);

  String get noticeStatusLabel =>
      recoveryNoticeAction == null ? 'Not prepared' : 'Approved';

  String get noticeProgressLabel => switch (stage) {
        ContactRecoveryStage.settled =>
          '${recoveryDisposition?.label ?? 'Recovery'} Closed',
        ContactRecoveryStage.recoveryInProgress => 'Recovery',
        ContactRecoveryStage.disposalReady => 'Review due',
        _ => noticeStatusLabel,
      };

  String _dateLabel(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day.toString().padLeft(2, '0')} '
        '${months[value.month - 1]} ${value.year}';
  }

  String _monthsDaysLabel(GirviElapsedPeriod period) {
    final months = (period.years * 12) + period.months;
    final parts = <String>[
      if (months > 0) '$months month${months == 1 ? '' : 's'}',
      if (period.days > 0 || months == 0)
        '${period.days} day${period.days == 1 ? '' : 's'}',
    ];
    return parts.join(' ');
  }

  ContactRecoveryStage get stage {
    if (isRecoveryClosed || hasDisposalSettlement) {
      return ContactRecoveryStage.settled;
    }
    if (hasCollateralRecoveryInitiated) {
      return ContactRecoveryStage.recoveryInProgress;
    }
    if (recoveryNoticeAction == null) {
      return ContactRecoveryStage.noticeRequired;
    }
    return isRecoveryReady
        ? ContactRecoveryStage.disposalReady
        : ContactRecoveryStage.noticePending;
  }

  String get stageLabel => switch (stage) {
        ContactRecoveryStage.noticeRequired => 'Notice Required',
        ContactRecoveryStage.noticePending => 'Notice in Progress',
        ContactRecoveryStage.disposalReady => 'Ready for Review',
        ContactRecoveryStage.recoveryInProgress => 'In Recovery',
        ContactRecoveryStage.settled => 'Closed',
      };

  String get stageDescription => switch (stage) {
        ContactRecoveryStage.noticeRequired =>
          'Prepare one formal notice. Customer replies are recorded against the saved notice.',
        ContactRecoveryStage.noticePending => hasNoticeDispatch
            ? recoveryBlockedMessage
            : 'Issue the notice and confirm customer delivery to start the response period.',
        ContactRecoveryStage.disposalReady => customerAuthorisedRecovery
            ? 'Customer requested recovery settlement. Review the account before approving recovery.'
            : hasNoticeDispatch
                ? 'The notice period has ended. Review payments and customer replies before approving recovery.'
                : 'Confirm notice delivery before approving recovery.',
        ContactRecoveryStage.recoveryInProgress =>
          'Collateral is in recovery. Record the recovered value to close the case.',
        ContactRecoveryStage.settled =>
          'Notice and recovery workflow is closed.',
      };

  Color get accentColor => switch (stage) {
        ContactRecoveryStage.noticeRequired => GirviColors.warning,
        ContactRecoveryStage.noticePending => GirviColors.info,
        ContactRecoveryStage.disposalReady => GirviColors.danger,
        ContactRecoveryStage.recoveryInProgress => GirviColors.brandGold,
        ContactRecoveryStage.settled => GirviColors.success,
      };

  Color get accentBg => switch (stage) {
        ContactRecoveryStage.noticeRequired => GirviColors.warningBg,
        ContactRecoveryStage.noticePending => GirviColors.infoBg,
        ContactRecoveryStage.disposalReady => GirviColors.dangerBg,
        ContactRecoveryStage.recoveryInProgress => GirviColors.brandGoldLight,
        ContactRecoveryStage.settled => GirviColors.successBg,
      };
}
