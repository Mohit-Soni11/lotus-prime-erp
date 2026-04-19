// =============================================================================
// FILE        : purchase_item_model.dart
// MODULE      : Purchase Entry
// LAYER       : Models
// DESCRIPTION : Single purchased item row. ChangeNotifier for zero-lag UI.
// =============================================================================

import 'package:flutter/material.dart';
import '../purchase_enums/purchase_enums.dart';

class PurchaseItemModel extends ChangeNotifier {
  // Controllers
  final TextEditingController descCtrl       = TextEditingController();
  final TextEditingController grossCtrl      = TextEditingController();
  final TextEditingController lessCtrl       = TextEditingController();
  final TextEditingController purityCtrl     = TextEditingController();
  final TextEditingController rateCtrl       = TextEditingController();

  // Focus nodes
  final FocusNode firstFieldFocus = FocusNode();

  // State
  PurchaseMetalType metal;

  PurchaseItemModel({this.metal = PurchaseMetalType.gold}) {
    purityCtrl.text = '100';
    _addListeners();
  }

  void _addListeners() {
    grossCtrl.addListener(_recalc);
    lessCtrl.addListener(_recalc);
    purityCtrl.addListener(_recalc);
    rateCtrl.addListener(_recalc);
  }

  void _recalc() => notifyListeners();

  void updateMetal(PurchaseMetalType newMetal) {
    metal = newMetal;
    notifyListeners();
  }

  // ── Computed values ───────────────────────────────────────────
  double get grossWt   => double.tryParse(grossCtrl.text) ?? 0.0;
  double get lessWt    => double.tryParse(lessCtrl.text)  ?? 0.0;
  double get netWt     => (grossWt - lessWt).clamp(0.0, double.infinity);
  double get purity    => double.tryParse(purityCtrl.text) ?? 0.0;
  double get fineWt    => metal == PurchaseMetalType.diamond
      ? netWt * (purity / 100.0)
      : netWt * (purity / 100.0);
  double get rate      => double.tryParse(rateCtrl.text) ?? 0.0;
  double get totalValue => fineWt * rate;

  @override
  void dispose() {
    descCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    purityCtrl.dispose();
    rateCtrl.dispose();
    firstFieldFocus.dispose();
    super.dispose();
  }
}
