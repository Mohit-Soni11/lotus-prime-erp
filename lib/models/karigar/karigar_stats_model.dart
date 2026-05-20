// =============================================================================
// FILE        : karigar_stats_model.dart
// MODULE      : Karigar
// LAYER       : Models
// DESCRIPTION : Pure-data models for karigar statistics.
//               KarigarStatsModel      — per-karigar financial & weight summary.
//               OverallKarigarStats    — aggregate stats for Pending Jobs header.
// =============================================================================

// =============================================================================
// 1. PER-KARIGAR STATS (used in Hisaab left panel + summary cards)
// =============================================================================

class KarigarStatsModel {
  /// Total gross weight ever issued to this karigar (grams).
  final double totalIssuedWeight;

  /// Total net weight received back from this karigar (grams).
  final double totalReceivedWeight;

  /// Metal still with karigar: issuedNet - receivedNet (grams).
  final double pendingWeight;

  /// Sum of all making charges billed (Rs).
  final double totalMakingCharges;

  /// Sum of all payments made to karigar (Rs).
  final double totalPaid;

  /// Outstanding balance = charges - paid + openingBalance (Rs).
  final double outstandingBalance;

  /// Total number of issue transactions ever.
  final int totalIssues;

  /// Open issues (Pending or In Progress).
  final int activeIssues;

  /// Completed issues.
  final int completedIssues;

  /// Issues past expected delivery and still open.
  final int overdueIssues;

  const KarigarStatsModel({
    required this.totalIssuedWeight,
    required this.totalReceivedWeight,
    required this.pendingWeight,
    required this.totalMakingCharges,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.totalIssues,
    required this.activeIssues,
    required this.completedIssues,
    required this.overdueIssues,
  });

  factory KarigarStatsModel.empty() => const KarigarStatsModel(
        totalIssuedWeight: 0.0,
        totalReceivedWeight: 0.0,
        pendingWeight: 0.0,
        totalMakingCharges: 0.0,
        totalPaid: 0.0,
        outstandingBalance: 0.0,
        totalIssues: 0,
        activeIssues: 0,
        completedIssues: 0,
        overdueIssues: 0,
      );
}

// =============================================================================
// 2. OVERALL STATS (used in Pending Jobs screen header cards)
// =============================================================================

class OverallKarigarStats {
  /// Total active karigars in the system.
  final int totalKarigars;

  /// Total open jobs across all karigars.
  final int totalActiveJobs;

  /// Total jobs past expected delivery date.
  final int totalOverdueJobs;

  /// Total gross weight currently with all karigars (grams).
  final double totalWeightWithKarigar;

  /// Total outstanding payment due (Rs).
  final double totalOutstanding;

  const OverallKarigarStats({
    required this.totalKarigars,
    required this.totalActiveJobs,
    required this.totalOverdueJobs,
    required this.totalWeightWithKarigar,
    required this.totalOutstanding,
  });

  factory OverallKarigarStats.empty() => const OverallKarigarStats(
        totalKarigars: 0,
        totalActiveJobs: 0,
        totalOverdueJobs: 0,
        totalWeightWithKarigar: 0.0,
        totalOutstanding: 0.0,
      );
}
