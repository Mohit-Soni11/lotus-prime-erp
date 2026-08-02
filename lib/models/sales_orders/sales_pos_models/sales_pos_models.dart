import 'package:flutter/material.dart';

import '../../../features/sales_pos/domain/services/pos_item_unit_profile.dart';
import '../../../features/sales_pos/domain/services/pos_number_formatter.dart';
import '../../../features/sales_pos/domain/services/pos_number_parser.dart';
import '../../../features/sales_pos/domain/services/pos_weight_math.dart';
import '../sales_pos_enums/sales_pos_enums.dart';

double _parseSafeNumber(String text) {
  return PosNumberParser.parseNonNegative(text);
}

//  Converts purity labels to their effective fine percentages.
// "22KT"  91.67%, "925"  92.5%, "75.5"  75.5% (custom input)
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
  return PosNumberFormatter.compact(value);
}

double _roundWeight3(double value) {
  return PosWeightMath.roundToThreeDecimals(value);
}

class SaleItemModel extends ChangeNotifier {
  static const int _maxPieceWiseHuidSlots = 12;

  MetalType _metal;
  MakingChargeType _makingChargeType;
  bool _isLessPerPiece;
  PosItemUnitProfile _unitProfile = PosItemUnitProfile.pieces;
  int? _linkedStockItemId;
  int? _linkedStockUnitId;
  String? _linkedStockSku;
  double _linkedStockUnitCost = 0.0;
  bool _isApplyingSmartQuantity = false;
  bool _isApplyingStockReferenceSnapshot = false;
  bool _quantityManuallyChanged = false;
  bool _unitProfileManuallySet = false;

  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController pcsCtrl = TextEditingController(text: '1');
  final TextEditingController huidCtrl = TextEditingController();
  final List<TextEditingController> _extraHuidCtrls = [];
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode(); // description
  //  Focus nodes support predictable Tab and Enter navigation.
  final FocusNode pcsFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final List<FocusNode> _extraHuidFocusNodes = [];
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
  String? _invoiceHsnCode;
  //  Store purity as the display label, such as "22KT" or "925".
  String _tunchLabel = '';

  SaleItemModel({
    MetalType metal = MetalType.gold,
    MakingChargeType makingChargeType = MakingChargeType.perGram,
    bool isLessPerPiece = false,
  })  : _metal = metal,
        _makingChargeType = makingChargeType,
        _isLessPerPiece = isLessPerPiece {
    descCtrl.addListener(() {
      _clearStockReferenceOnManualEdit();
      _applySmartUnitFromDescription();
    });

    //  Value equality listeners
    pcsCtrl.addListener(() {
      //  Quantity is constrained to positive whole numbers.
      final val = (int.tryParse(pcsCtrl.text) ?? 1).clamp(1, 9999);
      if (!_isApplyingSmartQuantity) {
        _quantityManuallyChanged = true;
      }
      if (!_isApplyingSmartQuantity) {
        _clearStockReferenceOnManualEdit();
      }
      if (_pcs != val) {
        _pcs = val;
        _syncHuidInputsWithPieceCount();
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

    // Track label string ("22KT","925") not stripped number
    purityCtrl.addListener(() {
      final label = purityCtrl.text;
      if (_tunchLabel != label) {
        _clearStockReferenceOnManualEdit();
        _tunchLabel = label;
        notifyListeners();
      }
    });
  }

  // --- GETTERS ---
  MetalType get metal => _metal;
  MakingChargeType get makingChargeType => _makingChargeType;
  bool get isLessPerPiece => _isLessPerPiece;
  PosItemUnitProfile get unitProfile => _unitProfile;
  String get unitDisplayName => _unitProfile.displayName;
  String get unitShortName => _unitProfile.shortName;
  List<PosItemUnitProfile> get availableUnitProfiles =>
      PosItemUnitProfile.invoiceOptionsForMetal(_metal);
  int? get linkedStockItemId => _linkedStockItemId;
  int? get linkedStockUnitId => _linkedStockUnitId;
  String? get linkedStockSku => _linkedStockSku;
  double get linkedStockUnitCost => _linkedStockUnitCost;
  bool get hasLinkedStock => _linkedStockItemId != null;
  bool get hasStockCost => _linkedStockUnitCost > 0;
  double get stockProfitAmount =>
      hasStockCost ? totalValue - _linkedStockUnitCost : 0.0;
  bool get isBelowStockCost =>
      hasStockCost && totalValue < _linkedStockUnitCost;
  bool get isAtStockCost =>
      hasStockCost && (totalValue - _linkedStockUnitCost).abs() <= 0.5;
  bool get shouldWarnStockCost => isBelowStockCost || isAtStockCost;
  bool get rateFromMetalRateMaster => _rateFromMetalRateMaster;
  bool get makingFromMetalRateMaster => _makingFromMetalRateMaster;
  String? get rateSourceLabel => _rateSourceLabel;
  String? get makingSourceLabel => _makingSourceLabel;
  String? get invoiceHsnCode => _invoiceHsnCode;

  // --- CORE WEIGHT LOGIC ---
  int get pcs => _pcs;
  int get huidSlotCount {
    if (!_unitProfile.usesPieceWiseHuid) return 1;
    final stockPieceCount = _pcs * _unitProfile.stockPiecesPerUnit;
    final expectedPieces = stockPieceCount > _unitProfile.stockPiecesPerUnit
        ? stockPieceCount
        : _unitProfile.stockPiecesPerUnit;
    if (expectedPieces <= 1 || expectedPieces > _maxPieceWiseHuidSlots) {
      return 1;
    }
    return expectedPieces;
  }

  List<TextEditingController> get huidControllers =>
      List.unmodifiable([huidCtrl, ..._extraHuidCtrls]);

  List<FocusNode> get huidFocusNodes =>
      List.unmodifiable([huidFocus, ..._extraHuidFocusNodes]);

  List<String> get huidValues {
    final values = <String>[];
    for (final controller in huidControllers) {
      values.addAll(_splitHuidText(controller.text));
    }
    return values;
  }

  String get huidText => huidValues.join(', ');
  String get primaryHuidText => huidValues.isEmpty ? '' : huidValues.first;

  double get totalLessWt => _isLessPerPiece ? (_lessWt * _pcs) : _lessWt;
  //  Net weight is clamped at zero when deductions exceed gross weight.
  double get netWt => (_grossWt - totalLessWt).clamp(0.0, double.infinity);
  double get rate => _rate;
  //  Fine weight uses the percentage mapped from the purity label.
  double get tunch => _purityLabelToPercent(_tunchLabel);
  double get fineWt => _roundWeight3(netWt * (tunch / 100));

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
        return _makingInput * netWt;
      case MakingChargeType.percentage:
        return (netWt * _rate) * (_makingInput / 100);
    }
  }

  // --- ACTIONS ---
  void updateMetal(MetalType newMetal) {
    if (_metal != newMetal) {
      _clearStockReferenceOnManualEdit();
      _metal = newMetal;
      if (!availableUnitProfiles
          .any((unit) => unit.code == _unitProfile.code)) {
        _unitProfile = PosItemUnitProfile.pieces;
        _unitProfileManuallySet = false;
      }
      _applySmartUnitFromDescription(notify: false);
      notifyListeners();
    }
  }

  void setUnitProfile(PosItemUnitProfile profile) {
    if (!availableUnitProfiles.any((unit) => unit.code == profile.code)) {
      return;
    }
    _unitProfileManuallySet = true;
    _applyUnitProfile(profile);
  }

  void setInvoiceHsnCode(String? value) {
    final normalized = value?.trim();
    _invoiceHsnCode =
        normalized == null || normalized.isEmpty ? null : normalized;
  }

  void setHuidText(String value) {
    setHuidValues(_splitHuidText(value));
  }

  void setHuidValues(List<String> values) {
    _clearStockReferenceOnManualEdit();
    final normalizedValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    _syncHuidInputsWithPieceCount();
    final controllers = huidControllers;
    for (var index = 0; index < controllers.length; index++) {
      final text =
          index < normalizedValues.length ? normalizedValues[index] : '';
      if (controllers[index].text != text) {
        controllers[index].text = text;
      }
    }
    if (controllers.length == 1 && normalizedValues.length > 1) {
      huidCtrl.text = normalizedValues.join(', ');
    }
    notifyListeners();
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
    int? stockUnitId,
    double stockUnitCost = 0.0,
  }) {
    final normalizedSku = sku.trim();
    final didChange = _linkedStockItemId != stockItemId ||
        _linkedStockUnitId != stockUnitId ||
        _linkedStockSku != normalizedSku ||
        _linkedStockUnitCost != stockUnitCost;
    _linkedStockItemId = stockItemId;
    _linkedStockUnitId = stockUnitId;
    _linkedStockSku = normalizedSku;
    _linkedStockUnitCost = stockUnitCost;
    if (didChange) {
      notifyListeners();
    }
  }

  void applyStockReferenceSnapshot({
    required List<String> huids,
    required double grossWeight,
    required double lessWeight,
    required int stockItemId,
    required String sku,
    int? stockUnitId,
    double stockUnitCost = 0.0,
  }) {
    _isApplyingStockReferenceSnapshot = true;
    try {
      setHuidValues(huids);
      grossCtrl.text = PosNumberFormatter.compact(grossWeight);
      lessCtrl.text = PosNumberFormatter.compact(lessWeight);
      attachStockReference(
        stockItemId: stockItemId,
        stockUnitId: stockUnitId,
        stockUnitCost: stockUnitCost,
        sku: sku,
      );
    } finally {
      _isApplyingStockReferenceSnapshot = false;
    }
  }

  void clearStockReference() {
    if (_linkedStockItemId == null &&
        _linkedStockUnitId == null &&
        _linkedStockSku == null &&
        _linkedStockUnitCost <= 0) {
      return;
    }
    _linkedStockItemId = null;
    _linkedStockUnitId = null;
    _linkedStockSku = null;
    _linkedStockUnitCost = 0.0;
    notifyListeners();
  }

  void _clearStockReferenceOnManualEdit() {
    if (_isApplyingStockReferenceSnapshot) {
      return;
    }
    clearStockReference();
  }

  void _applySmartUnitFromDescription({bool notify = true}) {
    if (_unitProfileManuallySet) {
      return;
    }
    final next = PosItemUnitProfile.infer(
      metal: _metal,
      itemName: descCtrl.text,
    );
    if (next.code == _unitProfile.code) {
      return;
    }

    _applyUnitProfile(next, notify: notify);
  }

  void _applyUnitProfile(
    PosItemUnitProfile next, {
    bool notify = true,
  }) {
    if (next.code == _unitProfile.code) {
      _syncHuidInputsWithPieceCount();
      if (notify) {
        notifyListeners();
      }
      return;
    }

    final previousDefaultPieces = _unitProfile.defaultPieceCount;
    _unitProfile = next;
    final canApplyDefaultQuantity = !_quantityManuallyChanged ||
        pcsCtrl.text.trim().isEmpty ||
        _pcs == previousDefaultPieces;

    if (canApplyDefaultQuantity) {
      _isApplyingSmartQuantity = true;
      pcsCtrl.text = next.defaultPieceCount.toString();
      pcsCtrl.selection = TextSelection.collapsed(offset: pcsCtrl.text.length);
      _isApplyingSmartQuantity = false;
      _quantityManuallyChanged = false;
      _pcs = next.defaultPieceCount;
    }
    _syncHuidInputsWithPieceCount();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncHuidInputsWithPieceCount() {
    final targetCount = huidSlotCount;
    final existingValues = huidValues;
    while (_extraHuidCtrls.length < targetCount - 1) {
      final controller = TextEditingController();
      _extraHuidCtrls.add(controller);
      _extraHuidFocusNodes.add(FocusNode());
    }
    while (_extraHuidCtrls.length > targetCount - 1) {
      final controller = _extraHuidCtrls.removeLast();
      controller.dispose();
      _extraHuidFocusNodes.removeLast().dispose();
    }
    _applyHuidValuesToVisibleInputs(existingValues);
  }

  void _applyHuidValuesToVisibleInputs(List<String> values) {
    if (values.isEmpty) return;
    final controllers = huidControllers;
    if (controllers.length == 1 && values.length > 1) {
      if (huidCtrl.text != values.join(', ')) {
        huidCtrl.text = values.join(', ');
      }
      return;
    }
    for (var index = 0; index < controllers.length; index++) {
      final nextText = index < values.length ? values[index] : '';
      if (controllers[index].text != nextText) {
        controllers[index].text = nextText;
      }
    }
  }

  List<String> _splitHuidText(String value) {
    return value
        .split(RegExp(r'[,;/\s]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void dispose() {
    descCtrl.dispose();
    pcsCtrl.dispose();
    huidCtrl.dispose();
    for (final controller in _extraHuidCtrls) {
      controller.dispose();
    }
    purityCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();
    firstFieldFocus.dispose();
    //  Dispose field focus nodes.
    pcsFocus.dispose();
    huidFocus.dispose();
    for (final focusNode in _extraHuidFocusNodes) {
      focusNode.dispose();
    }
    purityFocus.dispose();
    grossFocus.dispose();
    lessFocus.dispose();
    rateFocus.dispose();
    makingFocus.dispose();
    super.dispose();
  }
}

class TradeInItemModel extends ChangeNotifier {
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

  TradeInItemModel({
    MetalType metal = MetalType.gold,
  }) : _metal = metal {
    purityCtrl.text = "100";

    //  Value equality listeners
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
  double get netWt => (_grossWt - _lessWt).clamp(0.0, double.infinity);
  double get rate => _rate;
  double get purityPercent => _purity;
  bool get rateFromMetalRateMaster => _rateFromMetalRateMaster;
  String? get rateSourceLabel => _rateSourceLabel;

  double get fineWt {
    return _roundWeight3(netWt * (_purity / 100));
  }

  double get totalValue {
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
