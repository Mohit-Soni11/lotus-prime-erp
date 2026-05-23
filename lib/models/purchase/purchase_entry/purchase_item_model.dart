import 'package:flutter/material.dart';

import '../purchase_enums/purchase_enums.dart';

String _formatMasterInput(double value) {
  if (value <= 0) return '';
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    return rounded.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class PurchaseItemModel extends ChangeNotifier {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

  PurchaseMetalType metal;
  bool _isApplyingMasterRate = false;
  bool _rateFromMetalRateMaster = false;
  String? _rateSourceLabel;

  PurchaseItemModel({this.metal = PurchaseMetalType.gold}) {
    purityCtrl.text = '100';
    _addListeners();
  }

  void _addListeners() {
    grossCtrl.addListener(_recalc);
    lessCtrl.addListener(_recalc);
    purityCtrl.addListener(_recalc);
    rateCtrl.addListener(() {
      _trackManualRate();
      _recalc();
    });
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
  bool get rateFromMetalRateMaster => _rateFromMetalRateMaster;
  String? get rateSourceLabel => _rateSourceLabel;

  bool get hasContent =>
      descCtrl.text.trim().isNotEmpty ||
      grossCtrl.text.trim().isNotEmpty ||
      lessCtrl.text.trim().isNotEmpty ||
      rateCtrl.text.trim().isNotEmpty;

  bool get isValidEntry => netWt > 0 && rate > 0;

  bool applyMasterRate({
    required double rate,
    required String sourceLabel,
    bool force = false,
  }) {
    if (rate <= 0) {
      return false;
    }
    final hasManualRate =
        rateCtrl.text.trim().isNotEmpty && !_rateFromMetalRateMaster;
    if (hasManualRate && !force) {
      return false;
    }

    final formatted = _formatMasterInput(rate);
    _isApplyingMasterRate = true;
    rateCtrl.text = formatted;
    rateCtrl.selection = TextSelection.collapsed(offset: formatted.length);
    _isApplyingMasterRate = false;

    _rateFromMetalRateMaster = true;
    _rateSourceLabel = sourceLabel;
    notifyListeners();
    return true;
  }

  void clearMasterRateIfOwned() {
    if (!_rateFromMetalRateMaster) {
      return;
    }
    _isApplyingMasterRate = true;
    rateCtrl.clear();
    _isApplyingMasterRate = false;
    _rateFromMetalRateMaster = false;
    _rateSourceLabel = null;
    notifyListeners();
  }

  double _parseNumeric(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  void _trackManualRate() {
    if (_isApplyingMasterRate) {
      return;
    }
    _rateFromMetalRateMaster = false;
    _rateSourceLabel = null;
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
