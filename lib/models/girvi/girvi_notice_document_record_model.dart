import 'girvi_notice_action_model.dart';

class GirviNoticeDocumentRecord {
  const GirviNoticeDocumentRecord({
    required this.id,
    required this.girviId,
    required this.noticeActionId,
    required this.noticeStage,
    required this.language,
    required this.noticeText,
    required this.documentHash,
    required this.wasManuallyEdited,
    required this.createdAt,
    this.generatedText,
    this.approvedBy,
    this.approvedAt,
    this.updatedAt,
  });

  final int id;
  final int girviId;
  final int noticeActionId;
  final int noticeStage;
  final GirviNoticeLanguage language;
  final String noticeText;
  final String documentHash;
  final String? generatedText;
  final bool wasManuallyEdited;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
