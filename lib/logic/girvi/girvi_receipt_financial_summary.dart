import '../../models/girvi/girvi_invoice_draft.dart';

/// Cash collected over a pledge's lifetime, grouped by collection stage.
class GirviReceiptFinancialSummary {
  const GirviReceiptFinancialSummary({
    required this.priorPrincipal,
    required this.priorInterest,
    required this.settlementPrincipal,
    required this.settlementInterest,
    required this.discount,
    required this.settlementModes,
    required this.interestEntries,
  });

  final double priorPrincipal;
  final double priorInterest;
  final double settlementPrincipal;
  final double settlementInterest;
  final double discount;
  final String settlementModes;
  final List<GirviInvoiceLedgerEntry> interestEntries;

  double get principalReceived => priorPrincipal + settlementPrincipal;
  double get interestReceived => priorInterest + settlementInterest;
  double get previouslyCollected => priorPrincipal + priorInterest;
  double get collectedAtSettlement => settlementPrincipal + settlementInterest;
  double get totalReceived => principalReceived + interestReceived;

  factory GirviReceiptFinancialSummary.fromDraft(GirviInvoiceDraft draft) {
    var priorPrincipal = 0.0;
    var priorInterest = 0.0;
    var settlementPrincipal = 0.0;
    var settlementInterest = 0.0;
    var ledgerDiscount = 0.0;
    var hasAllocatedSettlement = false;
    final modes = <String>{};
    final interestEntries = <GirviInvoiceLedgerEntry>[];

    for (final entry in draft.ledgerEntries) {
      final principal = principalFromEntry(entry);
      final interest = interestFromEntry(entry);
      final settlement = isSettlementEntry(entry);
      ledgerDiscount += entry.discountAmount;
      if (interest > 0.005) interestEntries.add(entry);

      if (settlement) {
        settlementPrincipal += principal;
        settlementInterest += interest;
        hasAllocatedSettlement |= principal > 0.005 || interest > 0.005;
        if (entry.modeLabel.trim().isNotEmpty) {
          modes.add(entry.modeLabel.trim());
        }
      } else {
        priorPrincipal += principal;
        priorInterest += interest;
      }
    }

    // Older receipts can carry release totals without component ledger rows.
    if (draft.isReleaseReceipt && !hasAllocatedSettlement) {
      settlementPrincipal = draft.releasePrincipal ?? 0;
      settlementInterest = draft.releaseInterest ?? 0;
    }

    return GirviReceiptFinancialSummary(
      priorPrincipal: priorPrincipal,
      priorInterest: priorInterest,
      settlementPrincipal: settlementPrincipal,
      settlementInterest: settlementInterest,
      discount: ledgerDiscount > 0.005
          ? ledgerDiscount
          : (draft.releaseDiscount ?? 0),
      settlementModes: modes.isNotEmpty
          ? modes.join(', ')
          : (draft.releasePaymentMode ?? '').trim(),
      interestEntries: List.unmodifiable(interestEntries),
    );
  }

  static bool isSettlementEntry(GirviInvoiceLedgerEntry entry) {
    final type = entry.typeLabel.toLowerCase();
    return type.contains('release') || type.contains('settlement');
  }

  static double principalFromEntry(GirviInvoiceLedgerEntry entry) {
    if (entry.principalAmount > 0) return entry.principalAmount;
    final legacyPrincipalOnly =
        entry.typeLabel.toLowerCase().contains('principal') &&
            entry.interestAmount <= 0;
    return legacyPrincipalOnly
        ? entry.amount.clamp(0, double.infinity).toDouble()
        : 0;
  }

  static double interestFromEntry(GirviInvoiceLedgerEntry entry) {
    if (entry.interestAmount > 0) return entry.interestAmount;
    final legacyInterestOnly =
        entry.typeLabel.toLowerCase().contains('interest') &&
            entry.principalAmount <= 0 &&
            entry.discountAmount <= 0;
    return legacyInterestOnly
        ? entry.amount.clamp(0, double.infinity).toDouble()
        : 0;
  }
}
