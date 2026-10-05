class GirviNoticeActionTypes {
  GirviNoticeActionTypes._();

  static const noticeDraftCopied = 'NOTICE_DRAFT_COPIED';
  static const firstNoticePrepared = 'FIRST_NOTICE_PREPARED';
  static const secondNoticePrepared = 'SECOND_NOTICE_PREPARED';
  static const finalNoticePrepared = 'FINAL_NOTICE_PREPARED';
  static const noticePdfSaved = 'NOTICE_PDF_SAVED';
  static const noticePdfPrinted = 'NOTICE_PDF_PRINTED';
  static const noticePdfShared = 'NOTICE_PDF_SHARED';
  static const noticeDeliveryRecorded = 'NOTICE_DELIVERY_RECORDED';
  static const collateralRecoveryInitiated = 'COLLATERAL_RECOVERY_INITIATED';
  static const disposalSettled = 'DISPOSAL_SETTLED';
  static const auctionMarked = 'AUCTION_MARKED';
}

enum GirviNoticeType {
  first(1, 'First Notice', 'Initial account contact'),
  second(2, 'Second Notice', 'Follow-up before final recovery review'),
  finalNotice(3, 'Final Notice', 'Final redemption and recovery notice');

  const GirviNoticeType(this.stage, this.label, this.subtitle);

  final int stage;
  final String label;
  final String subtitle;

  String get actionType {
    switch (this) {
      case GirviNoticeType.first:
        return GirviNoticeActionTypes.firstNoticePrepared;
      case GirviNoticeType.second:
        return GirviNoticeActionTypes.secondNoticePrepared;
      case GirviNoticeType.finalNotice:
        return GirviNoticeActionTypes.finalNoticePrepared;
    }
  }

  static GirviNoticeType fromStage(int stage) {
    return GirviNoticeType.values.firstWhere(
      (type) => type.stage == stage,
      orElse: () => GirviNoticeType.first,
    );
  }
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

  bool get isNoticePreparation =>
      actionType == GirviNoticeActionTypes.secondNoticePrepared ||
      actionType == GirviNoticeActionTypes.finalNoticePrepared ||
      actionType == GirviNoticeActionTypes.firstNoticePrepared;

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
      case GirviNoticeActionTypes.firstNoticePrepared:
        return 'First notice prepared';
      case GirviNoticeActionTypes.secondNoticePrepared:
        return 'Second notice prepared';
      case GirviNoticeActionTypes.finalNoticePrepared:
        return 'Final notice prepared';
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
