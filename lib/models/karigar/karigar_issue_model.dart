// =============================================================================
// FILE        : karigar_issue_model.dart
// MODULE      : Karigar
// LAYER       : Models
// DESCRIPTION : Rich model combining a KarigarIssue row with its associated
//               KarigarMaster. Provides computed business properties used
//               across the Pending Jobs and Hisaab screens.
//               Also contains KarigarTxnEntry — a polymorphic ledger entry
//               used in the Karigar Hisaab transaction timeline.
// =============================================================================

import 'karigar_enums/karigar_enums.dart';

// =============================================================================
// JOINED MODEL: Issue + Karigar (used in Pending Jobs & Hisaab)
// =============================================================================

class KarigarIssueWithKarigar {
  final int id;
  final String issueNumber;
  final int karigarId;
  final String karigarName;
  final String karigarPhone;
  final DateTime issueDate;
  final String itemDescription;
  final String itemCategory;
  final int quantity;
  final String metalType;
  final String? purity;
  final double grossWeightIssued;
  final double netWeightIssued;
  final DateTime? expectedDelivery;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const KarigarIssueWithKarigar({
    required this.id,
    required this.issueNumber,
    required this.karigarId,
    required this.karigarName,
    required this.karigarPhone,
    required this.issueDate,
    required this.itemDescription,
    required this.itemCategory,
    required this.quantity,
    required this.metalType,
    this.purity,
    required this.grossWeightIssued,
    required this.netWeightIssued,
    this.expectedDelivery,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  // ── COMPUTED PROPERTIES ────────────────────────────────────────────────────

  IssueStatus get statusEnum => IssueStatus.fromLabel(status);

  /// True when the expected delivery date has passed and the job is still open.
  bool get isOverdue {
    if (expectedDelivery == null) return false;
    if (!statusEnum.isActive) return false;
    return DateTime.now().isAfter(expectedDelivery!);
  }

  /// Calendar days since the issue was created.
  int get daysPending {
    return DateTime.now().difference(issueDate).inDays;
  }

  /// Calendar days past the expected delivery (0 if not overdue).
  int get daysOverdue {
    if (!isOverdue || expectedDelivery == null) return 0;
    return DateTime.now().difference(expectedDelivery!).inDays;
  }

  /// Short metal + purity summary for display chips.
  String get metalDisplay {
    if (purity != null && purity!.isNotEmpty) return '$metalType • $purity';
    return metalType;
  }

  /// Karigar initials for avatar.
  String get karigarInitials {
    final parts = karigarName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return karigarName
        .substring(0, karigarName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}

// =============================================================================
// JOINED MODEL: Receipt + Issue + Karigar (used in Hisaab)
// =============================================================================

class KarigarReceiptWithDetails {
  final int id;
  final String receiptNumber;
  final int issueId;
  final String issueNumber;
  final int karigarId;
  final String karigarName;
  final DateTime receiptDate;
  final int quantityReceived;
  final double grossWeightReceived;
  final double stoneWeight;
  final double netWeightReceived;
  final double wastageWeight;
  final double wastagePercent;
  final String makingChargesType;
  final double makingChargeRate;
  final double makingChargesAmount;
  final String paymentStatus;
  final double paidAmount;
  final String? notes;
  final DateTime createdAt;

  const KarigarReceiptWithDetails({
    required this.id,
    required this.receiptNumber,
    required this.issueId,
    required this.issueNumber,
    required this.karigarId,
    required this.karigarName,
    required this.receiptDate,
    required this.quantityReceived,
    required this.grossWeightReceived,
    required this.stoneWeight,
    required this.netWeightReceived,
    required this.wastageWeight,
    required this.wastagePercent,
    required this.makingChargesType,
    required this.makingChargeRate,
    required this.makingChargesAmount,
    required this.paymentStatus,
    required this.paidAmount,
    this.notes,
    required this.createdAt,
  });

  KarigarPaymentStatus get paymentStatusEnum =>
      KarigarPaymentStatus.fromLabel(paymentStatus);

  double get balanceDue => makingChargesAmount - paidAmount;

  bool get isHighWastage => wastagePercent > 2.0;
}

// =============================================================================
// POLYMORPHIC LEDGER ENTRY: Used in Karigar Hisaab Timeline
// =============================================================================

class KarigarTxnEntry {
  final KarigarTxnType type;
  final DateTime date;
  final KarigarIssueWithKarigar? issue;
  final KarigarReceiptWithDetails? receipt;

  const KarigarTxnEntry._({
    required this.type,
    required this.date,
    this.issue,
    this.receipt,
  });

  factory KarigarTxnEntry.fromIssue(KarigarIssueWithKarigar i) =>
      KarigarTxnEntry._(
        type: KarigarTxnType.issue,
        date: i.issueDate,
        issue: i,
        receipt: null,
      );

  factory KarigarTxnEntry.fromReceipt(KarigarReceiptWithDetails r) =>
      KarigarTxnEntry._(
        type: KarigarTxnType.receipt,
        date: r.receiptDate,
        issue: null,
        receipt: r,
      );

  bool get isIssue => type == KarigarTxnType.issue;
  bool get isReceipt => type == KarigarTxnType.receipt;
}
