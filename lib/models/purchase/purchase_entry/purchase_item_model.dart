import 'package:flutter/material.dart';

import '../purchase_enums/purchase_enums.dart';

class PurchaseItemModel extends ChangeNotifier {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

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

  double get grossWt => _parseNumeric(grossCtrl.text);
  double get lessWt => _parseNumeric(lessCtrl.text);
  double get netWt => (grossWt - lessWt).clamp(0.0, double.infinity);
  double get purity => _parseNumeric(purityCtrl.text);
  double get fineWt => netWt * (purity / 100.0);
  double get rate => _parseNumeric(rateCtrl.text);
  double get totalValue => fineWt * rate;

  bool get hasContent =>
      descCtrl.text.trim().isNotEmpty ||
      grossCtrl.text.trim().isNotEmpty ||
      lessCtrl.text.trim().isNotEmpty ||
      rateCtrl.text.trim().isNotEmpty;

  bool get isValidEntry => netWt > 0 && rate > 0;

  double _parseNumeric(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

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
