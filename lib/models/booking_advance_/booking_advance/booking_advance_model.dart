// =============================================================================
// FILE        : booking_advance_model.dart
// MODULE      : Sales → Booking & Advance
// LAYER       : Models
// DESCRIPTION : Data models for booking items and scrap/exchange metal.
//               ✅ v2 FIX: BookingScrapModel.totalValue now uses fineWt × rate
//                          instead of netWt × rate. Critical business logic fix.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/models/sales%20&%20orders/sales_pos_enums/sales_pos_enums.dart';

double _parse(String text) {
  if (text.isEmpty) return 0.0;
  return double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
}

// =============================================================================
// 1. BOOKING ITEM MODEL
//    Represents a single item being booked/ordered by the customer.
//    Pattern mirrors SaleItemModel from the Sales POS module.
// =============================================================================
class BookingItemModel extends ChangeNotifier {
  MetalType _metal;
  MakingChargeType _makingChargeType;

  final TextEditingController descCtrl   = TextEditingController();
  final TextEditingController pcsCtrl    = TextEditingController(text: '1');
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController grossCtrl  = TextEditingController();
  final TextEditingController lessCtrl   = TextEditingController();
  final TextEditingController rateCtrl   = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

  int    _pcs     = 1;
  double _grossWt = 0.0;
  double _lessWt  = 0.0;
  double _rate    = 0.0;
  double _making  = 0.0;
  double _tunch   = 0.0;

  BookingItemModel({
    MetalType metal = MetalType.gold,
    MakingChargeType makingChargeType = MakingChargeType.perGram,
  })  : _metal = metal,
        _makingChargeType = makingChargeType {

    pcsCtrl.addListener(() {
      final v = int.tryParse(pcsCtrl.text) ?? 1;
      if (_pcs != v) { _pcs = v; notifyListeners(); }
    });
    grossCtrl.addListener(() {
      final v = _parse(grossCtrl.text);
      if (_grossWt != v) { _grossWt = v; notifyListeners(); }
    });
    lessCtrl.addListener(() {
      final v = _parse(lessCtrl.text);
      if (_lessWt != v) { _lessWt = v; notifyListeners(); }
    });
    rateCtrl.addListener(() {
      final v = _parse(rateCtrl.text);
      if (_rate != v) { _rate = v; notifyListeners(); }
    });
    makingCtrl.addListener(() {
      final v = _parse(makingCtrl.text);
      if (_making != v) { _making = v; notifyListeners(); }
    });
    purityCtrl.addListener(() {
      final v = _parse(purityCtrl.text);
      if (_tunch != v) { _tunch = v; notifyListeners(); }
    });
  }

  // ── GETTERS ───────────────────────────────────────────────────────────────
  MetalType        get metal            => _metal;
  MakingChargeType get makingChargeType => _makingChargeType;

  int    get pcs    => _pcs;
  double get netWt  => _grossWt - _lessWt;
  double get rate   => _rate;
  double get tunch  => _tunch;
  double get fineWt => netWt * (_tunch / 100);

  double get makingAmt {
    switch (_makingChargeType) {
      case MakingChargeType.perGram:
        return netWt * _making;
      case MakingChargeType.perPiece:
        return _pcs * _making;
      case MakingChargeType.percentage:
        return (netWt * _rate) * (_making / 100);
      case MakingChargeType.perKg:
        return (netWt / 1000) * _making;
    }
  }

  double get metalValue => netWt * _rate;
  double get totalValue => metalValue + makingAmt;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  void updateMetal(MetalType m) {
    _metal = m;
    notifyListeners();
  }

  void toggleMakingChargeType() {
    switch (_makingChargeType) {
      case MakingChargeType.perGram:
        _makingChargeType = MakingChargeType.perPiece;
        break;
      case MakingChargeType.perPiece:
        _makingChargeType = MakingChargeType.percentage;
        break;
      case MakingChargeType.percentage:
        _makingChargeType = MakingChargeType.perGram;
        break;
      case MakingChargeType.perKg:
        _makingChargeType = MakingChargeType.perGram;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    descCtrl.dispose();
    pcsCtrl.dispose();
    purityCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();
    firstFieldFocus.dispose();
    super.dispose();
  }
}

// =============================================================================
// 2. BOOKING SCRAP MODEL
//    Represents old/scrap metal given by the customer as part of advance.
//    Pattern mirrors OldGoldItemModel from the Sales POS module.
//
//    ✅ v2 BUG FIX:
//    WRONG (v1): totalValue = netWt × rate
//    CORRECT:    totalValue = fineWt × rate
//
//    Reason: Customer gives old gold of 5.260g with 55% purity.
//    Fine (pure) weight = 5.260 × 55% = 2.893g.
//    Credit is given only for pure metal — not gross weight.
//    Previous calculation was over-crediting the customer significantly.
// =============================================================================
class BookingScrapModel extends ChangeNotifier {
  MetalType _metal;

  final TextEditingController descCtrl   = TextEditingController();
  final TextEditingController grossCtrl  = TextEditingController();
  final TextEditingController lessCtrl   = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController rateCtrl   = TextEditingController();

  final FocusNode firstFieldFocus = FocusNode();

  double _grossWt = 0.0;
  double _lessWt  = 0.0;
  double _purity  = 100.0;
  double _rate    = 0.0;

  BookingScrapModel({MetalType metal = MetalType.gold}) : _metal = metal {
    purityCtrl.text = '100';

    grossCtrl.addListener(() {
      final v = _parse(grossCtrl.text);
      if (_grossWt != v) { _grossWt = v; notifyListeners(); }
    });
    lessCtrl.addListener(() {
      final v = _parse(lessCtrl.text);
      if (_lessWt != v) { _lessWt = v; notifyListeners(); }
    });
    purityCtrl.addListener(() {
      final v = _parse(purityCtrl.text);
      if (_purity != v) { _purity = v; notifyListeners(); }
    });
    rateCtrl.addListener(() {
      final v = _parse(rateCtrl.text);
      if (_rate != v) { _rate = v; notifyListeners(); }
    });
  }

  // ── GETTERS ───────────────────────────────────────────────────────────────
  MetalType get metal  => _metal;
  double    get netWt  => _grossWt - _lessWt;
  double    get rate   => _rate;

  double get fineWt {
    // Silver without purity entry → treated as 100% fine
    if (_metal == MetalType.silver && purityCtrl.text.isEmpty) return netWt;
    return netWt * (_purity / 100);
  }

  // ✅ v2 FIX: fineWt × rate (was netWt × rate — incorrect business logic)
  double get totalValue => fineWt * _rate;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  void updateMetal(MetalType m) {
    _metal = m;
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