class GirviNoticeActionTypes {
  GirviNoticeActionTypes._();

  static const noticeDraftCopied = 'NOTICE_DRAFT_COPIED';
  static const auctionMarked = 'AUCTION_MARKED';
}

class GirviNoticeAction {
  final int id;
  final int girviId;
  final String actionType;
  final String? noticeText;
  final String? actionNote;
  final DateTime actionAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GirviNoticeAction({
    required this.id,
    required this.girviId,
    required this.actionType,
    required this.actionAt,
    required this.createdAt,
    this.noticeText,
    this.actionNote,
    this.updatedAt,
  });

  String get displayLabel {
    switch (actionType) {
      case GirviNoticeActionTypes.noticeDraftCopied:
        return 'Legal notice prepared';
      case GirviNoticeActionTypes.auctionMarked:
        return 'Auction status recorded';
      default:
        return 'Notice activity recorded';
    }
  }
}
