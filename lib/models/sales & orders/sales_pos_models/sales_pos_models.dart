// ==========================================
// FILE: sales_pos_models.dart
// TYPE: Core Data Models (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-Lag Data Models. Implements Value-Equality checks
//              to prevent UI rebuild spam on non-value keystrokes.
// ==========================================

import 'package:flutter/material.dart';
import '../sales_pos_enums/sales_pos_enums.dart';

// 🚀 ARCHITECTURE FIX: Optimized Parser
double _parseSafeNumber(String text) {
  if (text.isEmpty) return 0.0;
  String cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleanText) ?? 0.0;
}

// ✅ BUG FIX: Purity label → actual fine percentage
// "22KT" → 91.67%, "925" → 92.5%, "75.5" → 75.5% (custom input)
double _purityLabelToPercent(String label) {
  const map = <String, double>{
    '24KT': 99.9,
    '22KT': 91.67,
    '18KT': 75.0,
    '14KT': 58.3,
    '9KT': 37.5,
    '999': 99.9,
    '925': 92.5,
    '800': 80.0,
    '950PT': 95.0,
    '900PT': 90.0,
    '850PT': 85.0,
    'VVS1': 100.0,
    'VVS2': 100.0,
    'VS1': 100.0,
    'VS2': 100.0,
    'SI1': 100.0,
    'SI2': 100.0,
  };
  final cleaned = label.trim().toUpperCase();
  if (map.containsKey(cleaned)) return map[cleaned]!;
  // User typed raw percentage (e.g. "91.67" or "75")
  final raw = _parseSafeNumber(label);
  return raw.clamp(0.0, 100.0);
}

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

class SaleItemModel extends ChangeNotifier {
  MetalType _metal;
  MakingChargeType _makingChargeType;
  bool _isLessPerPiece;
  int? _linkedStockItemId;
  String? _linkedStockSku;

  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController pcsCtrl = TextEditingController(text: '1');
  final TextEditingController huidCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode(); // description
  // ✅ FIX: FocusNode for every field — proper Tab/Enter navigation
  final FocusNode pcsFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final FocusNode purityFocus = FocusNode();
  final FocusNode grossFocus = FocusNode();
  final FocusNode lessFocus = FocusNode();
  final FocusNode rateFocus = FocusNode();
  final FocusNode makingFocus = FocusNode();

  // --- CACHED NUMERIC STATES (For Zero-Lag Equality Checks) ---
  int _pcs = 1;
  double _grossWt = 0.0;
  double _lessWt = 0.0;
  double _rate = 0.0;
  double _makingInput = 0.0;
  bool _isApplyingMasterRate = false;
  bool _isApplyingMasterMaking = false;
  bool _rateFromMetalRateMaster = false;
  bool _makingFromMetalRateMaster = false;
  String? _rateSourceLabel;
  String? _makingSourceLabel;
  // ✅ FIX: Track purity as label string ("22KT","925") not stripped number
  String _tunchLabel = '';

  SaleItemModel({
    MetalType metal = MetalType.gold,
    MakingChargeType makingChargeType = MakingChargeType.perGram,
    bool isLessPerPiece = false,
  })  : _metal = metal,
        _makingChargeType = makingChargeType,
        _isLessPerPiece = isLessPerPiece {
    // 🚀 STRICT VALUE-EQUALITY LISTENERS
    pcsCtrl.addListener(() {
      // ✅ FIX: pcs min=1, integers only — 0 or negative makes no sense
      final val = (int.tryParse(pcsCtrl.text) ?? 1).clamp(1, 9999);
      if (_pcs != val) {
        _pcs = val;
        notifyListeners();
      }
    });

    grossCtrl.addListener(() {
      final val = _parseSafeNumber(grossCtrl.text);
      if (_grossWt != val) {
        _grossWt = val;
        notifyListeners();
      }
    });

    lessCtrl.addListener(() {
      final val = _parseSafeNumber(lessCtrl.text);
      if (_lessWt != val) {
        _lessWt = val;
        notifyListeners();
      }
    });

    rateCtrl.addListener(() {
      final val = _parseSafeNumber(rateCtrl.text);
      if (_rate != val) {
        _rate = val;
        if (!_isApplyingMasterRate) {
          _rateFromMetalRateMaster = false;
          _rateSourceLabel = null;
        }
        notifyListeners();
      }
    });

    makingCtrl.addListener(() {
      final val = _parseSafeNumber(makingCtrl.text);
      if (_makingInput != val) {
        _makingInput = val;
        if (!_isApplyingMasterMaking) {
          _makingFromMetalRateMaster = false;
          _makingSourceLabel = null;
        }
        notifyListeners();
      }
    });

    // ✅ FIX: Track label string ("22KT","925") not stripped number
    purityCtrl.addListener(() {
      final label = purityCtrl.text;
      if (_tunchLabel != label) {
        _tunchLabel = label;
        notifyListeners();
      }
    });
  }

  // --- GETTERS ---
  MetalType get metal => _metal;
  MakingChargeType get makingChargeType => _makingChargeType;
  bool get isLessPerPiece => _isLessPerPiece;
  int? get linkedStockItemId => _linkedStockItemId;
  String? get linkedStockSku => _linkedStockSku;
  bool get hasLinkedStock => _linkedStockItemId != null;
  bool get rateFromMetalRateMaster => _rateFromMetalRateMaster;
  bool get makingFromMetalRateMaster => _makingFromMetalRateMaster;
  String? get rateSourceLabel => _rateSourceLabel;
  String? get makingSourceLabel => _makingSourceLabel;

  // --- CORE WEIGHT LOGIC ---
  int get pcs => _pcs;
  double get totalLessWt => _isLessPerPiece ? (_lessWt * _pcs) : _lessWt;
  // ✅ FIX: netWt cannot go below zero (less > gross scenario)
  double get netWt => (_grossWt - totalLessWt).clamp(0.0, double.infinity);
  double get rate => _rate;
  // ✅ FIX: Use proper fine% from label — "22KT"=91.67%, "925"=92.5%
  double get tunch => _purityLabelToPercent(_tunchLabel);
  double get fineWt => netWt * (tunch / 100);

  // --- RETAIL LOGIC ---
  double get makingAmt {
    switch (_makingChargeType) {
      case MakingChargeType.percentage:
        return (netWt * _rate) * (_makingInput / 100);
      case MakingChargeType.perKg:
        return _makingInput * (netWt / 1000);
      case MakingChargeType.perGram:
        return _makingInput * netWt;
      case MakingChargeType.perPiece:
        return _makingInput * _pcs;
    }
  }

  double get totalValue => (netWt * _rate) + makingAmt;

  // --- WHOLESALE LOGIC ---
  double get wholesaleLabourAmt {
    switch (_makingChargeType) {
      case MakingChargeType.perPiece:
        return _makingInput * _pcs;
      case MakingChargeType.perKg:
        return _makingInput * (netWt / 1000);
      case MakingChargeType.perGram:
      case MakingChargeType.percentage: // Fallback for invalid state
        return _makingInput * netWt;
    }
  }

  // --- ACTIONS ---
  void updateMetal(MetalType newMetal) {
    if (_metal != newMetal) {
      _metal = newMetal;
      notifyListeners();
    }
  }

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

    _rate = rate;
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
    _rate = 0.0;
    _rateFromMetalRateMaster = false;
    _rateSourceLabel = null;
    notifyListeners();
  }

  bool applyMasterMaking({
    required double makingPercent,
    required double makingPerGram,
    required String sourceLabel,
    bool force = false,
  }) {
    if (makingPercent <= 0 && makingPerGram <= 0) {
      return false;
    }
    final hasManualMaking =
        makingCtrl.text.trim().isNotEmpty && !_makingFromMetalRateMaster;
    if (hasManualMaking && !force) {
      return false;
    }

    final usePerGram = makingPerGram > 0;
    _makingChargeType =
        usePerGram ? MakingChargeType.perGram : MakingChargeType.percentage;
    final value = usePerGram ? makingPerGram : makingPercent;
    final formatted = _formatMasterInput(value);

    _isApplyingMasterMaking = true;
    makingCtrl.text = formatted;
    makingCtrl.selection = TextSelection.collapsed(offset: formatted.length);
    _isApplyingMasterMaking = false;

    _makingInput = value;
    _makingFromMetalRateMaster = true;
    _makingSourceLabel = sourceLabel;
    notifyListeners();
    return true;
  }

  void clearMasterMakingIfOwned() {
    if (!_makingFromMetalRateMaster) {
      return;
    }
    _isApplyingMasterMaking = true;
    makingCtrl.clear();
    _isApplyingMasterMaking = false;
    _makingInput = 0.0;
    _makingFromMetalRateMaster = false;
    _makingSourceLabel = null;
    notifyListeners();
  }

  void toggleLessWeightType() {
    _isLessPerPiece = !_isLessPerPiece;
    notifyListeners();
  }

  void toggleMakingChargeType({required bool isWholesale}) {
    _makingFromMetalRateMaster = false;
    _makingSourceLabel = null;
    if (isWholesale) {
      // Wholesale: Only perGram -> perKg -> perPiece
      if (_makingChargeType == MakingChargeType.perGram) {
        _makingChargeType = MakingChargeType.perKg;
      } else if (_makingChargeType == MakingChargeType.perKg) {
        _makingChargeType = MakingChargeType.perPiece;
      } else {
        _makingChargeType = MakingChargeType.perGram;
      }
    } else {
      // Retail: Only perGram -> perPiece -> percentage
      if (_makingChargeType == MakingChargeType.perGram) {
        _makingChargeType = MakingChargeType.perPiece;
      } else if (_makingChargeType == MakingChargeType.perPiece) {
        _makingChargeType = MakingChargeType.percentage;
      } else {
        _makingChargeType = MakingChargeType.perGram;
      }
    }
    notifyListeners();
  }

  void attachStockReference({
    required int stockItemId,
    required String sku,
  }) {
    final normalizedSku = sku.trim();
    final didChange =
        _linkedStockItemId != stockItemId || _linkedStockSku != normalizedSku;
    _linkedStockItemId = stockItemId;
    _linkedStockSku = normalizedSku;
    if (didChange) {
      notifyListeners();
    }
  }

  void clearStockReference() {
    if (_linkedStockItemId == null && _linkedStockSku == null) {
      return;
    }
    _linkedStockItemId = null;
    _linkedStockSku = null;
    notifyListeners();
  }

  @override
  void dispose() {
    descCtrl.dispose();
    pcsCtrl.dispose();
    huidCtrl.dispose();
    purityCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();
    firstFieldFocus.dispose();
    // ✅ FIX: Dispose all field FocusNodes
    pcsFocus.dispose();
    huidFocus.dispose();
    purityFocus.dispose();
    grossFocus.dispose();
    lessFocus.dispose();
    rateFocus.dispose();
    makingFocus.dispose();
    super.dispose();
  }
}

class OldGoldItemModel extends ChangeNotifier {
  MetalType _metal;

  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

  // --- CACHED NUMERIC STATES ---
  double _grossWt = 0.0;
  double _lessWt = 0.0;
  double _purity = 100.0;
  double _rate = 0.0;
  bool _isApplyingMasterRate = false;
  bool _rateFromMetalRateMaster = false;
  String? _rateSourceLabel;

  OldGoldItemModel({
    MetalType metal = MetalType.gold,
  }) : _metal = metal {
    purityCtrl.text = "100";

    // 🚀 STRICT VALUE-EQUALITY LISTENERS
    grossCtrl.addListener(() {
      final val = _parseSafeNumber(grossCtrl.text);
      if (_grossWt != val) {
        _grossWt = val;
        notifyListeners();
      }
    });

    lessCtrl.addListener(() {
      final val = _parseSafeNumber(lessCtrl.text);
      if (_lessWt != val) {
        _lessWt = val;
        notifyListeners();
      }
    });

    purityCtrl.addListener(() {
      final val = _parseSafeNumber(purityCtrl.text);
      if (_purity != val) {
        _purity = val;
        notifyListeners();
      }
    });

    rateCtrl.addListener(() {
      final val = _parseSafeNumber(rateCtrl.text);
      if (_rate != val) {
        _rate = val;
        if (!_isApplyingMasterRate) {
          _rateFromMetalRateMaster = false;
          _rateSourceLabel = null;
        }
        notifyListeners();
      }
    });
  }

  MetalType get metal => _metal;
  double get netWt => _grossWt - _lessWt;
  double get rate => _rate;
  double get purityPercent => _purity;
  bool get rateFromMetalRateMaster => _rateFromMetalRateMaster;
  String? get rateSourceLabel => _rateSourceLabel;

  double get fineWt {
    if (_metal == MetalType.silver && purityCtrl.text.isEmpty) {
      return netWt;
    }
    return netWt * (_purity / 100);
  }

  double get totalValue {
    if (_metal == MetalType.silver && purityCtrl.text.isEmpty) {
      return netWt * _rate;
    }
    return fineWt * _rate;
  }

  void updateMetal(MetalType newMetal) {
    if (_metal != newMetal) {
      _metal = newMetal;

      // Smart Auto-fill for UX
      if (newMetal == MetalType.silver) {
        purityCtrl.clear();
      } else if (purityCtrl.text.isEmpty) {
        purityCtrl.text = "100";
      }
      notifyListeners();
    }
  }

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

    _rate = rate;
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
    _rate = 0.0;
    _rateFromMetalRateMaster = false;
    _rateSourceLabel = null;
    notifyListeners();
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
