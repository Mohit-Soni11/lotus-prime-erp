// =============================================================================
// FILE        : karigar_enums.dart
// MODULE      : Karigar
// LAYER       : Models / Enums
// DESCRIPTION : Single source of truth for all Karigar module enumerations.
//               Covers artisan specialization, rate types, job statuses,
//               payment statuses, and UI filter types.
// =============================================================================

// ── 1. KARIGAR SPECIALIZATION ─────────────────────────────────────────────────
enum KarigarSpecialization {
  goldWork('Gold Work'),
  silverWork('Silver Work'),
  diamondWork('Diamond Work'),
  platinumWork('Platinum Work'),
  allMetals('All Metals'),
  polishWork('Polish Work'),
  stoneSetting('Stone Setting'),
  casting('Casting'),
  other('Other');

  final String label;
  const KarigarSpecialization(this.label);

  static KarigarSpecialization fromLabel(String l) =>
      KarigarSpecialization.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarSpecialization.allMetals,
      );
}

// ── 2. KARIGAR RATE TYPE ──────────────────────────────────────────────────────
enum KarigarRateType {
  perGram('Per Gram (Rs/g)'),
  perPiece('Per Piece (Rs)'),
  percent('Percentage (%)');

  final String label;
  const KarigarRateType(this.label);

  static KarigarRateType fromLabel(String l) =>
      KarigarRateType.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarRateType.perGram,
      );
}

// ── 3. ISSUE STATUS ───────────────────────────────────────────────────────────
enum IssueStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const IssueStatus(this.label);

  /// Returns true if the job is still open and trackable.
  bool get isActive => this == pending || this == inProgress;

  static IssueStatus fromLabel(String l) => IssueStatus.values.firstWhere(
        (e) => e.label == l,
        orElse: () => IssueStatus.pending,
      );
}

// ── 4. PAYMENT STATUS ─────────────────────────────────────────────────────────
enum KarigarPaymentStatus {
  unpaid('Unpaid'),
  partial('Partial'),
  paid('Paid');

  final String label;
  const KarigarPaymentStatus(this.label);

  static KarigarPaymentStatus fromLabel(String l) =>
      KarigarPaymentStatus.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarPaymentStatus.unpaid,
      );
}

// ── 5. MAKING CHARGES TYPE ────────────────────────────────────────────────────
enum KarigarMakingType {
  perGram('Per Gram (Rs/g)'),
  perPiece('Per Piece (Rs)'),
  percent('Percentage (%)');

  final String label;
  const KarigarMakingType(this.label);

  static KarigarMakingType fromLabel(String l) =>
      KarigarMakingType.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarMakingType.perGram,
      );
}

// ── 6. METAL TYPE (Karigar context) ──────────────────────────────────────────
enum KarigarMetalType {
  gold('Gold'),
  silver('Silver'),
  platinum('Platinum'),
  mixed('Mixed');

  final String label;
  const KarigarMetalType(this.label);

  static KarigarMetalType fromLabel(String l) =>
      KarigarMetalType.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarMetalType.gold,
      );
}

// ── 7. ITEM CATEGORY ─────────────────────────────────────────────────────────
enum KarigarItemCategory {
  ring('Ring'),
  necklace('Necklace'),
  bangle('Bangle'),
  earring('Earring'),
  pendant('Pendant'),
  bracelet('Bracelet'),
  chain('Chain'),
  anklet('Anklet'),
  mangalsutra('Mangalsutra'),
  set_('Set'),
  other('Other');

  final String label;
  const KarigarItemCategory(this.label);

  static KarigarItemCategory fromLabel(String l) =>
      KarigarItemCategory.values.firstWhere(
        (e) => e.label == l,
        orElse: () => KarigarItemCategory.other,
      );
}

// ── 8. PENDING JOBS FILTER ───────────────────────────────────────────────────
enum PendingJobsFilter {
  all('All'),
  pending('Pending'),
  inProgress('In Progress'),
  overdue('Overdue');

  final String label;
  const PendingJobsFilter(this.label);
}

// ── 9. KARIGAR TRANSACTION TYPE (Hisaab Ledger) ──────────────────────────────
enum KarigarTxnType {
  issue,
  receipt,
}

// ── 10. GOLD PURITY OPTIONS (for karigar context) ────────────────────────────
enum KarigarGoldPurity {
  k24('24K (999)'),
  k22('22K (916)'),
  k18('18K (750)'),
  k14('14K (585)'),
  other('Other');

  final String label;
  const KarigarGoldPurity(this.label);
}

enum KarigarSilverPurity {
  s999('999 (Pure)'),
  s925('925 (Sterling)'),
  s800('800'),
  other('Other');

  final String label;
  const KarigarSilverPurity(this.label);
}
