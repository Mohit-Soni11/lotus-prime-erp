import 'girvi_notice_history.dart';

class GirviNoticeActionTypes {
  GirviNoticeActionTypes._();

  static const noticeDraftCopied = 'NOTICE_DRAFT_COPIED';
  static const noticePrepared = 'NOTICE_PREPARED';
  static const preparationTypes = [
    noticePrepared,
    ...GirviNoticeHistory.preparationTypes,
  ];
  static const noticePdfSaved = 'NOTICE_PDF_SAVED';
  static const noticePdfPrinted = 'NOTICE_PDF_PRINTED';
  static const noticePdfShared = 'NOTICE_PDF_SHARED';
  static const noticeDeliveryRecorded = 'NOTICE_DELIVERY_RECORDED';
  static const collateralRecoveryInitiated = 'COLLATERAL_RECOVERY_INITIATED';
  static const disposalSettled = 'DISPOSAL_SETTLED';
  static const auctionMarked = 'AUCTION_MARKED';
}

enum GirviNoticeType {
  formal(1, 'Formal Notice', 'Pledge account payment and recovery notice');

  const GirviNoticeType(this.stage, this.label, this.subtitle);
  final int stage;
  final String label;
  final String subtitle;
  String get actionType => GirviNoticeActionTypes.noticePrepared;
}

enum GirviNoticeLanguage {
  hindi('Hindi', 'Hindi Notice', 'hindi'),
  english('English', 'English Notice', 'english');

  const GirviNoticeLanguage(this.label, this.actionLabel, this.fileLabel);

  final String label;
  final String actionLabel;
  final String fileLabel;
}

class GirviNoticeAction {
  final int id;
  final int girviId;
  final String actionType;
  final int? noticeActionId;
  final int? noticeStage;
  final String? noticeText;
  final String? documentHash;
  final String? actionNote;
  final String? performedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? noticeDeadlineAt;
  final double pledgedValuation;
  final double recoveredAmount;
  final double penaltyAmount;
  final double settlementTotal;
  final double customerBalanceDue;
  final double customerSurplus;
  final String? deliveryChannel;
  final String? deliveryStatus;
  final String? deliveryReference;
  final DateTime? deliveredAt;
  final DateTime actionAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GirviNoticeAction({
    required this.id,
    required this.girviId,
    required this.actionType,
    this.noticeActionId,
    required this.actionAt,
    required this.createdAt,
    this.noticeStage,
    this.noticeText,
    this.documentHash,
    this.actionNote,
    this.performedBy,
    this.approvedBy,
    this.approvedAt,
    this.noticeDeadlineAt,
    this.pledgedValuation = 0,
    this.recoveredAmount = 0,
    this.penaltyAmount = 0,
    this.settlementTotal = 0,
    this.customerBalanceDue = 0,
    this.customerSurplus = 0,
    this.deliveryChannel,
    this.deliveryStatus,
    this.deliveryReference,
    this.deliveredAt,
    this.updatedAt,
  });

  bool get isFormalNoticePreparation =>
      actionType == GirviNoticeActionTypes.noticePrepared;

  bool get isLegacyNoticePreparation =>
      GirviNoticeHistory.preparationTypes.contains(actionType);

  bool get isLegacyFinalNotice =>
      actionType == GirviNoticeHistory.finalPrepared;

  int? get resolvedNoticeStage =>
      noticeStage ??
      (isFormalNoticePreparation ? 1 : GirviNoticeHistory.stageFor(actionType));

  String get noticeLabel => isLegacyNoticePreparation
      ? GirviNoticeHistory.title(resolvedNoticeStage) ?? 'Earlier Notice'
      : GirviNoticeType.formal.label;

  bool get isNoticePreparation =>
      GirviNoticeActionTypes.preparationTypes.contains(actionType);

  bool get isNoticeDeliveryProof =>
      actionType == GirviNoticeActionTypes.noticePdfSaved ||
      actionType == GirviNoticeActionTypes.noticePdfPrinted ||
      actionType == GirviNoticeActionTypes.noticePdfShared ||
      actionType == GirviNoticeActionTypes.noticeDeliveryRecorded ||
      deliveryStatus != null;

  bool get isNotice => isNoticePreparation || isNoticeDeliveryProof;

  bool get isDisposalSettlement =>
      actionType == GirviNoticeActionTypes.disposalSettled;

  bool get isCollateralRecoveryInitiated =>
      actionType == GirviNoticeActionTypes.collateralRecoveryInitiated;

  String get displayLabel {
    switch (actionType) {
      case GirviNoticeActionTypes.noticePrepared:
        return 'Formal notice prepared';
      case GirviNoticeHistory.firstPrepared:
      case GirviNoticeHistory.secondPrepared:
      case GirviNoticeHistory.finalPrepared:
        return '$noticeLabel prepared (legacy)';
      case GirviNoticeActionTypes.noticePdfSaved:
        return 'Notice PDF saved';
      case GirviNoticeActionTypes.noticePdfPrinted:
        return 'Notice PDF printed';
      case GirviNoticeActionTypes.noticePdfShared:
        return 'Notice PDF shared';
      case GirviNoticeActionTypes.noticeDeliveryRecorded:
        return 'Notice delivery recorded';
      case GirviNoticeActionTypes.collateralRecoveryInitiated:
        return 'Collateral recovery initiated';
      case GirviNoticeActionTypes.disposalSettled:
        return 'Recovery settlement closed';
      case GirviNoticeActionTypes.noticeDraftCopied:
        return 'Legal notice draft copied';
      case GirviNoticeActionTypes.auctionMarked:
        return 'Closed status recorded';
      default:
        return 'Notice activity recorded';
    }
  }

  String get deliveryProofLabel {
    final status = deliveryStatus?.trim();
    final channel = deliveryChannel?.trim();
    if (status != null && status.isNotEmpty) {
      if (channel != null && channel.isNotEmpty) return '$status via $channel';
      return status;
    }
    return displayLabel;
  }
}
