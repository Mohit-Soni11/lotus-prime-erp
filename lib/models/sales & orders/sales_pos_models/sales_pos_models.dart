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
  // Regex parsing is expensive. Only strip if absolutely necessary.
  String cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleanText) ?? 0.0;
}

class SaleItemModel extends ChangeNotifier {
  MetalType _metal;
  MakingChargeType _makingChargeType;
  bool _isLessPerPiece; 
  
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController pcsCtrl = TextEditingController(text: '1'); 
  final TextEditingController huidCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

  // --- CACHED NUMERIC STATES (For Zero-Lag Equality Checks) ---
  int _pcs = 1;
  double _grossWt = 0.0; 
  double _lessWt = 0.0;  
  double _rate = 0.0;
  double _makingInput = 0.0;
  double _tunch = 0.0;

  SaleItemModel({
    MetalType metal = MetalType.gold,
    MakingChargeType makingChargeType = MakingChargeType.perGram,
    bool isLessPerPiece = false,
  }) : _metal = metal,
       _makingChargeType = makingChargeType,
       _isLessPerPiece = isLessPerPiece {
       
    // 🚀 STRICT VALUE-EQUALITY LISTENERS
    pcsCtrl.addListener(() {
      final val = int.tryParse(pcsCtrl.text) ?? 1;
      if (_pcs != val) { _pcs = val; notifyListeners(); }
    });
    
    grossCtrl.addListener(() {
      final val = _parseSafeNumber(grossCtrl.text);
      if (_grossWt != val) { _grossWt = val; notifyListeners(); }
    });
    
    lessCtrl.addListener(() {
      final val = _parseSafeNumber(lessCtrl.text);
      if (_lessWt != val) { _lessWt = val; notifyListeners(); }
    });
    
    rateCtrl.addListener(() {
      final val = _parseSafeNumber(rateCtrl.text);
      if (_rate != val) { _rate = val; notifyListeners(); }
    });
    
    makingCtrl.addListener(() {
      final val = _parseSafeNumber(makingCtrl.text);
      if (_makingInput != val) { _makingInput = val; notifyListeners(); }
    });
    
    purityCtrl.addListener(() {
      final val = _parseSafeNumber(purityCtrl.text);
      if (_tunch != val) { _tunch = val; notifyListeners(); }
    });
  }

  // --- GETTERS ---
  MetalType get metal => _metal;
  MakingChargeType get makingChargeType => _makingChargeType;
  bool get isLessPerPiece => _isLessPerPiece;

  // --- CORE WEIGHT LOGIC ---
  int get pcs => _pcs;
  double get totalLessWt => _isLessPerPiece ? (_lessWt * _pcs) : _lessWt;
  double get netWt => _grossWt - totalLessWt;
  double get rate => _rate;
  double get tunch => _tunch;
  double get fineWt => netWt * (_tunch / 100);

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

  void toggleLessWeightType() {
    _isLessPerPiece = !_isLessPerPiece;
    notifyListeners();
  }

  void toggleMakingChargeType({required bool isWholesale}) {
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

  OldGoldItemModel({
    MetalType metal = MetalType.gold,
  }) : _metal = metal {
    purityCtrl.text = "100"; 
    
    // 🚀 STRICT VALUE-EQUALITY LISTENERS
    grossCtrl.addListener(() { 
      final val = _parseSafeNumber(grossCtrl.text);
      if (_grossWt != val) { _grossWt = val; notifyListeners(); }
    });
    
    lessCtrl.addListener(() { 
      final val = _parseSafeNumber(lessCtrl.text);
      if (_lessWt != val) { _lessWt = val; notifyListeners(); }
    });
    
    purityCtrl.addListener(() { 
      final val = _parseSafeNumber(purityCtrl.text);
      if (_purity != val) { _purity = val; notifyListeners(); }
    });
    
    rateCtrl.addListener(() { 
      final val = _parseSafeNumber(rateCtrl.text);
      if (_rate != val) { _rate = val; notifyListeners(); }
    });
  }

  MetalType get metal => _metal;
  double get netWt => _grossWt - _lessWt;
  double get rate => _rate;

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