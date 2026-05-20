// =============================================================================
// FILE        : counter_security_model.dart
// MODULE      : Dashboard / Counter Security Check
// LAYER       : Models
// DESCRIPTION : Session-based model — DB nahi, sirf in-memory state.
//
//               3 STATES:
//               idle    → Kuch nahi hua, input ready
//               locked  → Step 1 done, items diye gaye, Step 2 ready
//               result  → Step 2 done, MATCHED ya MISMATCH
//
//               METALS: GOLD | SILVER | PLATINUM | DIAMOND
// =============================================================================

enum SecuritySessionState { idle, locked, result }

enum SecurityMetal { gold, silver, platinum, diamond }

enum SecurityResult { matched, mismatch }

extension SecurityMetalExt on SecurityMetal {
  String get label {
    switch (this) {
      case SecurityMetal.gold:
        return 'GOLD';
      case SecurityMetal.silver:
        return 'SILVER';
      case SecurityMetal.platinum:
        return 'PLATINUM';
      case SecurityMetal.diamond:
        return 'DIAMOND';
    }
  }

  String get emoji {
    switch (this) {
      case SecurityMetal.gold:
        return '🥇';
      case SecurityMetal.silver:
        return '🥈';
      case SecurityMetal.platinum:
        return '💎';
      case SecurityMetal.diamond:
        return '💍';
    }
  }
}

/// Ek session ka complete data
class CounterSecurityModel {
  final SecuritySessionState state;
  final SecurityMetal selectedMetal;

  // Step 1 — Diya
  final int issuePcs;
  final double issueWeight;

  // Step 2 — Wapas aaya
  final int returnPcs;
  final double returnWeight;

  // Result
  final SecurityResult? result;
  final int diffPcs;
  final double diffWeight; // + = missing, - = extra

  const CounterSecurityModel({
    this.state = SecuritySessionState.idle,
    this.selectedMetal = SecurityMetal.gold,
    this.issuePcs = 0,
    this.issueWeight = 0.0,
    this.returnPcs = 0,
    this.returnWeight = 0.0,
    this.result,
    this.diffPcs = 0,
    this.diffWeight = 0.0,
  });

  CounterSecurityModel copyWith({
    SecuritySessionState? state,
    SecurityMetal? selectedMetal,
    int? issuePcs,
    double? issueWeight,
    int? returnPcs,
    double? returnWeight,
    SecurityResult? result,
    int? diffPcs,
    double? diffWeight,
  }) {
    return CounterSecurityModel(
      state: state ?? this.state,
      selectedMetal: selectedMetal ?? this.selectedMetal,
      issuePcs: issuePcs ?? this.issuePcs,
      issueWeight: issueWeight ?? this.issueWeight,
      returnPcs: returnPcs ?? this.returnPcs,
      returnWeight: returnWeight ?? this.returnWeight,
      result: result ?? this.result,
      diffPcs: diffPcs ?? this.diffPcs,
      diffWeight: diffWeight ?? this.diffWeight,
    );
  }

  bool get isIdle => state == SecuritySessionState.idle;
  bool get isLocked => state == SecuritySessionState.locked;
  bool get hasResult => state == SecuritySessionState.result;
  bool get isMatched => result == SecurityResult.matched;

  /// Badge text — locked state mein dikhega
  String get lockedBadgeText =>
      '${selectedMetal.label}  |  $issuePcs Pcs  |  ${issueWeight.toStringAsFixed(3)} gm';

  /// Diff weight string — 3 decimal
  String get diffWeightStr => diffWeight.abs().toStringAsFixed(3);

  /// Result message — mismatch ke liye
  String get mismatchMessage {
    final parts = <String>[];
    if (diffPcs != 0) {
      parts.add('$diffPcs Pcs Missing');
    }
    if (diffWeight > 0.0005) {
      parts.add('$diffWeightStr gm KAM HAI (Missing)');
    } else if (diffWeight < -0.0005) {
      parts.add('${diffWeight.abs().toStringAsFixed(3)} gm ZYADA HAI (Extra)');
    }
    return parts.isEmpty ? 'Weight Mismatch!' : parts.join('  |  ');
  }
}
