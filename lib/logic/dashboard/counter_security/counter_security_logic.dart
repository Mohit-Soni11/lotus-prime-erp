// =============================================================================
// FILE        : counter_security_logic.dart
// MODULE      : Dashboard / Counter Security Check
// LAYER       : Logic
// DESCRIPTION : Pure in-memory session logic — no DB needed.
//
//               3 ACTIONS:
//               1. lockAndIssue  → Step 1: Pieces + Weight note karo, LOCK karo
//               2. verifyReturn  → Step 2: Return pieces + weight verify karo
//               3. reset         → Session clear karo, fresh start
//
//               CALCULATION:
//               diffPcs    = issuePcs - returnPcs
//               diffWeight = issueWeight - returnWeight (3 decimal precision)
//               MATCHED    = diffPcs == 0 AND abs(diffWeight) <= 0.0005
//               MISMATCH   = koi bhi difference
//
//               Pattern: ChangeNotifier (ShopCardLogic jaisa)
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
    if (_data.isLocked) return; // Session active hai to change nahi
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
    if (pcsStr.trim().isEmpty) return 'Pieces enter karo';
    if (weightStr.trim().isEmpty) return 'Weight enter karo';

    final int? pcs = int.tryParse(pcsStr.trim());
    if (pcs == null || pcs <= 0) return 'Valid pieces number dalo (1+)';

    final double? wt = double.tryParse(weightStr.trim());
    if (wt == null || wt <= 0) return 'Valid weight dalo (e.g. 15.250)';

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
    if (pcsStr.trim().isEmpty) return 'Return pieces enter karo';
    if (weightStr.trim().isEmpty) return 'Scale weight enter karo';

    final int? retPcs = int.tryParse(pcsStr.trim());
    if (retPcs == null || retPcs < 0) return 'Valid pieces dalo';

    final double? retWt = double.tryParse(weightStr.trim());
    if (retWt == null || retWt < 0) return 'Valid weight dalo';

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
      selectedMetal: _data.selectedMetal, // Metal choice yaad rakhte hain
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
