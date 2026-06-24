class GirviNoticeActionTypes {
  GirviNoticeActionTypes._();

  static const noticeDraftCopied = 'NOTICE_DRAFT_COPIED';
  static const firstNoticePrepared = 'FIRST_NOTICE_PREPARED';
  static const secondNoticePrepared = 'SECOND_NOTICE_PREPARED';
  static const finalNoticePrepared = 'FINAL_NOTICE_PREPARED';
  static const disposalSettled = 'DISPOSAL_SETTLED';
  static const auctionMarked = 'AUCTION_MARKED';
}

enum GirviNoticeType {
  first(1, 'First Notice', 'Initial settlement warning'),
  second(2, 'Second Notice', 'Final warning before forfeiture review'),
  finalNotice(
      3, 'Final Disposal Notice', 'Final redemption and disposal notice');

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
  final String? actionNote;
  final double pledgedValuation;
  final double recoveredAmount;
  final double penaltyAmount;
  final double settlementTotal;
  final double customerBalanceDue;
  final double customerSurplus;
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
    this.actionNote,
    this.pledgedValuation = 0,
    this.recoveredAmount = 0,
    this.penaltyAmount = 0,
    this.settlementTotal = 0,
    this.customerBalanceDue = 0,
    this.customerSurplus = 0,
    this.updatedAt,
  });

  bool get isNotice =>
      noticeStage != null ||
      actionType == GirviNoticeActionTypes.firstNoticePrepared ||
      actionType == GirviNoticeActionTypes.secondNoticePrepared ||
      actionType == GirviNoticeActionTypes.finalNoticePrepared ||
      actionType == GirviNoticeActionTypes.noticeDraftCopied;

  bool get isDisposalSettlement =>
      actionType == GirviNoticeActionTypes.disposalSettled;

  String get displayLabel {
    switch (actionType) {
      case GirviNoticeActionTypes.firstNoticePrepared:
        return 'First notice prepared';
      case GirviNoticeActionTypes.secondNoticePrepared:
        return 'Second notice prepared';
      case GirviNoticeActionTypes.finalNoticePrepared:
        return 'Final disposal notice prepared';
      case GirviNoticeActionTypes.disposalSettled:
        return 'Disposal settlement closed';
      case GirviNoticeActionTypes.noticeDraftCopied:
        return 'Legal notice prepared';
      case GirviNoticeActionTypes.auctionMarked:
        return 'Auction status recorded';
      default:
        return 'Notice activity recorded';
    }
  }
}
