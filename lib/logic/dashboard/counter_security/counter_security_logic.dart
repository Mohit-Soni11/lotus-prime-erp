// =============================================================================
// FILE        : counter_security_logic.dart
// MODULE      : Dashboard / Counter Security Check
// LAYER       : Logic
// DESCRIPTION : Pure in-memory session logic — no DB needed.
//
//               3 ACTIONS:
//               1. lockAndIssue  → Step 1: Capture pieces and weight, then lock.
//               2. verifyReturn  → Step 2: Verify returned pieces and weight.
//               3. reset         → Clear the session and start fresh.
//
//               CALCULATION:
//               diffPcs    = issuePcs - returnPcs
//               diffWeight = issueWeight - returnWeight (3 decimal precision)
//               MATCHED    = diffPcs == 0 AND abs(diffWeight) <= 0.0005
//               MISMATCH   = any piece or weight difference.
//
//               Pattern: ChangeNotifier aligned with ShopCardLogic.
// =============================================================================

import 'package:flutter/foundation.dart';
import '../../../models/dashboard/counter_security_model.dart';

class CounterSecurityLogic extends ChangeNotifier {
  CounterSecurityModel _data = const CounterSecurityModel();
  CounterSecurityModel get data => _data;

  // ==========================================
  // METAL SELECT
  // ==========================================
  void selectMetal(SecurityMetal metal) {
    if (_data.isLocked) return; // Keep metal fixed while a session is active.
    _data = _data.copyWith(selectedMetal: metal);
    notifyListeners();
  }

  // ==========================================
  // STEP 1 — LOCK & ISSUE
  // ==========================================
  /// Returns error string if validation fails, null if success
  String? lockAndIssue({
    required String pcsStr,
    required String weightStr,
  }) {
    // Validation
    if (pcsStr.trim().isEmpty) return 'Enter pieces';
    if (weightStr.trim().isEmpty) return 'Enter weight';

    final int? pcs = int.tryParse(pcsStr.trim());
    if (pcs == null || pcs <= 0) return 'Enter a valid pieces count (1+)';

    final double? wt = double.tryParse(weightStr.trim());
    if (wt == null || wt <= 0) return 'Enter a valid weight (e.g. 15.250)';

    _data = _data.copyWith(
      state: SecuritySessionState.locked,
      issuePcs: pcs,
      issueWeight: _round3(wt),
    );
    notifyListeners();
    return null;
  }

  // ==========================================
  // STEP 2 — VERIFY RETURN
  // ==========================================
  String? verifyReturn({
    required String pcsStr,
    required String weightStr,
  }) {
    if (pcsStr.trim().isEmpty) return 'Enter returned pieces';
    if (weightStr.trim().isEmpty) return 'Enter scale weight';

    final int? retPcs = int.tryParse(pcsStr.trim());
    if (retPcs == null || retPcs < 0) return 'Enter a valid pieces count';

    final double? retWt = double.tryParse(weightStr.trim());
    if (retWt == null || retWt < 0) return 'Enter a valid weight';

    final int diffPcs = _data.issuePcs - retPcs;
    final double diffWt = _round3(_data.issueWeight - _round3(retWt));

    final bool matched = diffPcs == 0 && diffWt.abs() <= 0.0005;

    _data = _data.copyWith(
      state: SecuritySessionState.result,
      returnPcs: retPcs,
      returnWeight: _round3(retWt),
      result: matched ? SecurityResult.matched : SecurityResult.mismatch,
      diffPcs: diffPcs,
      diffWeight: diffWt,
    );
    notifyListeners();
    return null;
  }

  // ==========================================
  // RESET — Fresh session
  // ==========================================
  void reset() {
    _data = CounterSecurityModel(
      selectedMetal: _data.selectedMetal, // Preserve the selected metal.
    );
    notifyListeners();
  }

  // ==========================================
  // HELPER — 3 decimal rounding (jewellery standard)
  // ==========================================
  static double _round3(double val) {
    return (val * 1000).round() / 1000;
  }
}
