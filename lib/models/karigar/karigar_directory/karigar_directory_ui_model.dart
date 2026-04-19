// =============================================================================
// FILE        : karigar_directory_ui_model.dart
// MODULE      : Karigar → Karigar Directory
// LAYER       : Models
// DESCRIPTION : UI-friendly model for the Karigar Directory list.
//               Wraps KarigarMaster with computed display helpers
//               and aggregated job/balance stats.
// =============================================================================

import '../karigar_enums/karigar_enums.dart';

// =============================================================================
// 1. LIST ITEM MODEL
// =============================================================================

class KarigarDirectoryItemModel {
  final int      id;
  final String   name;
  final String   phone;
  final String?  alternatePhone;
  final String   specialization;
  final String   rateType;
  final double   rateAmount;
  final String?  address;
  final String?  city;
  final double   openingBalance;
  final bool     isActive;
  final String?  notes;
  final DateTime createdAt;

  // Aggregated from issues + receipts
  final int    activeJobCount;
  final int    overdueJobCount;
  final double outstandingBalance;
  final double totalWeightPending; // grams

  const KarigarDirectoryItemModel({
    required this.id,
    required this.name,
    required this.phone,
    this.alternatePhone,
    required this.specialization,
    required this.rateType,
    required this.rateAmount,
    this.address,
    this.city,
    required this.openingBalance,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.activeJobCount,
    required this.overdueJobCount,
    required this.outstandingBalance,
    required this.totalWeightPending,
  });

  // ── COMPUTED ──────────────────────────────────────────────────────────────

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get locationDisplay {
    if (address != null && city != null) return '$address, $city';
    if (city != null) return city!;
    if (address != null) return address!;
    return '—';
  }

  String get rateDisplay {
    final formatted = rateAmount.toStringAsFixed(2);
    switch (KarigarRateType.fromLabel(rateType)) {
      case KarigarRateType.perGram:  return '₹$formatted/g';
      case KarigarRateType.perPiece: return '₹$formatted/pc';
      case KarigarRateType.percent:  return '$formatted%';
    }
  }

  bool get hasActiveJobs    => activeJobCount > 0;
  bool get hasOverdueJobs   => overdueJobCount > 0;
  bool get hasOutstanding   => outstandingBalance > 0;

  String get memberSince {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }
}

// =============================================================================
// 2. STATS MODEL (for header dashboard)
// =============================================================================

class KarigarDirectoryStatsModel {
  final int    totalActive;
  final int    totalInactive;
  final int    newThisMonth;
  final int    withActiveJobs;
  final double totalOutstanding;
  final bool   isLoading;

  const KarigarDirectoryStatsModel({
    required this.totalActive,
    required this.totalInactive,
    required this.newThisMonth,
    required this.withActiveJobs,
    required this.totalOutstanding,
    this.isLoading = false,
  });

  factory KarigarDirectoryStatsModel.loading() =>
      const KarigarDirectoryStatsModel(
        totalActive:      0,
        totalInactive:    0,
        newThisMonth:     0,
        withActiveJobs:   0,
        totalOutstanding: 0.0,
        isLoading:        true,
      );

  factory KarigarDirectoryStatsModel.empty() =>
      const KarigarDirectoryStatsModel(
        totalActive:      0,
        totalInactive:    0,
        newThisMonth:     0,
        withActiveJobs:   0,
        totalOutstanding: 0.0,
      );
}
