// ==========================================
// FILE: pos_hold_bill_model.dart
// TYPE: Data Model
// AUTHOR: Senior System Architect
// DESCRIPTION: Serializable blueprint for saving and restoring a parked POS
//              invoice snapshot across screen exits and app restarts.
// ==========================================

import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';

class PosHoldBillModel {
  final String holdId;
  final DateTime holdTime;
  final int? selectedCustomerId;
  final String customerName;
  final String customerMobile;
  final String customerCity;
  final String customerPan;
  final String customerGst;
  final BillingMode billingMode;
  final BillType billType;
  final OldGoldAdjustMode oldGoldMode;
  final DiscountType discountType;
  final DateTime? promiseDate;
  final String discountInput;
  final String cashInput;
  final String upiInput;
  final String cardInput;
  final String advanceInput;
  final String goldBhawInput;
  final String silverBhawInput;
  final String platinumBhawInput;
  final String diamondBhawInput;
  final double grandTotal;
  final List<PosHoldSaleItemSnapshot> savedSaleItems;
  final List<PosHoldOldMetalSnapshot> savedOldMetalItems;

  const PosHoldBillModel({
    required this.holdId,
    required this.holdTime,
    required this.selectedCustomerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    required this.customerPan,
    required this.customerGst,
    required this.billingMode,
    required this.billType,
    required this.oldGoldMode,
    required this.discountType,
    required this.promiseDate,
    required this.discountInput,
    required this.cashInput,
    required this.upiInput,
    required this.cardInput,
    required this.advanceInput,
    required this.goldBhawInput,
    required this.silverBhawInput,
    required this.platinumBhawInput,
    required this.diamondBhawInput,
    required this.grandTotal,
    required this.savedSaleItems,
    required this.savedOldMetalItems,
  });

  int get totalItems => savedSaleItems.length + savedOldMetalItems.length;

  Map<String, dynamic> toJson() {
    return {
      'holdId': holdId,
      'holdTime': holdTime.toIso8601String(),
      'selectedCustomerId': selectedCustomerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'customerCity': customerCity,
      'customerPan': customerPan,
      'customerGst': customerGst,
      'billingMode': billingMode.name,
      'billType': billType.name,
      'oldGoldMode': oldGoldMode.name,
      'discountType': discountType.name,
      'promiseDate': promiseDate?.toIso8601String(),
      'discountInput': discountInput,
      'cashInput': cashInput,
      'upiInput': upiInput,
      'cardInput': cardInput,
      'advanceInput': advanceInput,
      'goldBhawInput': goldBhawInput,
      'silverBhawInput': silverBhawInput,
      'platinumBhawInput': platinumBhawInput,
      'diamondBhawInput': diamondBhawInput,
      'grandTotal': grandTotal,
      'savedSaleItems': savedSaleItems.map((item) => item.toJson()).toList(),
      'savedOldMetalItems':
          savedOldMetalItems.map((item) => item.toJson()).toList(),
    };
  }

  factory PosHoldBillModel.fromJson(Map<String, dynamic> json) {
    final rawSaleItems = (json['savedSaleItems'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final rawOldMetalItems =
        (json['savedOldMetalItems'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>();

    return PosHoldBillModel(
      holdId: (json['holdId'] ?? '').toString(),
      holdTime: DateTime.tryParse((json['holdTime'] ?? '').toString()) ??
          DateTime.now(),
      selectedCustomerId: json['selectedCustomerId'] as int?,
      customerName: (json['customerName'] ?? '').toString(),
      customerMobile: (json['customerMobile'] ?? '').toString(),
      customerCity: (json['customerCity'] ?? '').toString(),
      customerPan: (json['customerPan'] ?? '').toString(),
      customerGst: (json['customerGst'] ?? '').toString(),
      billingMode: _billingModeFromName((json['billingMode'] ?? '').toString()),
      billType: _billTypeFromName((json['billType'] ?? '').toString()),
      oldGoldMode: _oldGoldModeFromName((json['oldGoldMode'] ?? '').toString()),
      discountType:
          _discountTypeFromName((json['discountType'] ?? '').toString()),
      promiseDate: DateTime.tryParse((json['promiseDate'] ?? '').toString()),
      discountInput: (json['discountInput'] ?? '').toString(),
      cashInput: (json['cashInput'] ?? '').toString(),
      upiInput: (json['upiInput'] ?? '').toString(),
      cardInput: (json['cardInput'] ?? '').toString(),
      advanceInput: (json['advanceInput'] ?? '').toString(),
      goldBhawInput: (json['goldBhawInput'] ?? '').toString(),
      silverBhawInput: (json['silverBhawInput'] ?? '').toString(),
      platinumBhawInput: (json['platinumBhawInput'] ?? '').toString(),
      diamondBhawInput: (json['diamondBhawInput'] ?? '').toString(),
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      savedSaleItems: rawSaleItems
          .map(PosHoldSaleItemSnapshot.fromJson)
          .toList(growable: false),
      savedOldMetalItems: rawOldMetalItems
          .map(PosHoldOldMetalSnapshot.fromJson)
          .toList(growable: false),
    );
  }

  static BillingMode _billingModeFromName(String name) {
    return BillingMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => BillingMode.retail,
    );
  }

  static BillType _billTypeFromName(String name) {
    return BillType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => BillType.normal,
    );
  }

  static OldGoldAdjustMode _oldGoldModeFromName(String name) {
    return OldGoldAdjustMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => OldGoldAdjustMode.cashAdjust,
    );
  }

  static DiscountType _discountTypeFromName(String name) {
    return DiscountType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => DiscountType.percentage,
    );
  }
}

class PosHoldSaleItemSnapshot {
  final MetalType metal;
  final MakingChargeType makingChargeType;
  final bool isLessPerPiece;
  final int? stockItemId;
  final String stockSku;
  final String description;
  final String pcsInput;
  final String huid;
  final String purity;
  final String grossInput;
  final String lessInput;
  final String rateInput;
  final String makingInput;

  const PosHoldSaleItemSnapshot({
    required this.metal,
    required this.makingChargeType,
    required this.isLessPerPiece,
    required this.stockItemId,
    required this.stockSku,
    required this.description,
    required this.pcsInput,
    required this.huid,
    required this.purity,
    required this.grossInput,
    required this.lessInput,
    required this.rateInput,
    required this.makingInput,
  });

  factory PosHoldSaleItemSnapshot.capture(SaleItemModel item) {
    return PosHoldSaleItemSnapshot(
      metal: item.metal,
      makingChargeType: item.makingChargeType,
      isLessPerPiece: item.isLessPerPiece,
      stockItemId: item.linkedStockItemId,
      stockSku: item.linkedStockSku ?? '',
      description: item.descCtrl.text,
      pcsInput: item.pcsCtrl.text,
      huid: item.huidCtrl.text,
      purity: item.purityCtrl.text,
      grossInput: item.grossCtrl.text,
      lessInput: item.lessCtrl.text,
      rateInput: item.rateCtrl.text,
      makingInput: item.makingCtrl.text,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metal': metal.name,
      'makingChargeType': makingChargeType.name,
      'isLessPerPiece': isLessPerPiece,
      'stockItemId': stockItemId,
      'stockSku': stockSku,
      'description': description,
      'pcsInput': pcsInput,
      'huid': huid,
      'purity': purity,
      'grossInput': grossInput,
      'lessInput': lessInput,
      'rateInput': rateInput,
      'makingInput': makingInput,
    };
  }

  factory PosHoldSaleItemSnapshot.fromJson(Map<String, dynamic> json) {
    return PosHoldSaleItemSnapshot(
      metal: MetalType.values.firstWhere(
        (value) => value.name == (json['metal'] ?? '').toString(),
        orElse: () => MetalType.gold,
      ),
      makingChargeType: MakingChargeType.values.firstWhere(
        (value) => value.name == (json['makingChargeType'] ?? '').toString(),
        orElse: () => MakingChargeType.perGram,
      ),
      isLessPerPiece: json['isLessPerPiece'] == true,
      stockItemId: (json['stockItemId'] as num?)?.toInt(),
      stockSku: (json['stockSku'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      pcsInput: (json['pcsInput'] ?? '1').toString(),
      huid: (json['huid'] ?? '').toString(),
      purity: (json['purity'] ?? '').toString(),
      grossInput: (json['grossInput'] ?? '').toString(),
      lessInput: (json['lessInput'] ?? '').toString(),
      rateInput: (json['rateInput'] ?? '').toString(),
      makingInput: (json['makingInput'] ?? '').toString(),
    );
  }

  SaleItemModel restore() {
    final item = SaleItemModel(
      metal: metal,
      makingChargeType: makingChargeType,
      isLessPerPiece: isLessPerPiece,
    );
    item.descCtrl.text = description;
    item.pcsCtrl.text = pcsInput.isEmpty ? '1' : pcsInput;
    item.huidCtrl.text = huid;
    item.purityCtrl.text = purity;
    item.grossCtrl.text = grossInput;
    item.lessCtrl.text = lessInput;
    item.rateCtrl.text = rateInput;
    item.makingCtrl.text = makingInput;
    if (stockItemId != null && stockSku.trim().isNotEmpty) {
      item.attachStockReference(
        stockItemId: stockItemId!,
        sku: stockSku,
      );
    }
    return item;
  }
}

class PosHoldOldMetalSnapshot {
  final MetalType metal;
  final String description;
  final String grossInput;
  final String lessInput;
  final String purityInput;
  final String rateInput;

  const PosHoldOldMetalSnapshot({
    required this.metal,
    required this.description,
    required this.grossInput,
    required this.lessInput,
    required this.purityInput,
    required this.rateInput,
  });

  factory PosHoldOldMetalSnapshot.capture(OldGoldItemModel item) {
    return PosHoldOldMetalSnapshot(
      metal: item.metal,
      description: item.descCtrl.text,
      grossInput: item.grossCtrl.text,
      lessInput: item.lessCtrl.text,
      purityInput: item.purityCtrl.text,
      rateInput: item.rateCtrl.text,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metal': metal.name,
      'description': description,
      'grossInput': grossInput,
      'lessInput': lessInput,
      'purityInput': purityInput,
      'rateInput': rateInput,
    };
  }

  factory PosHoldOldMetalSnapshot.fromJson(Map<String, dynamic> json) {
    return PosHoldOldMetalSnapshot(
      metal: MetalType.values.firstWhere(
        (value) => value.name == (json['metal'] ?? '').toString(),
        orElse: () => MetalType.gold,
      ),
      description: (json['description'] ?? '').toString(),
      grossInput: (json['grossInput'] ?? '').toString(),
      lessInput: (json['lessInput'] ?? '').toString(),
      purityInput: (json['purityInput'] ?? '').toString(),
      rateInput: (json['rateInput'] ?? '').toString(),
    );
  }

  OldGoldItemModel restore() {
    final item = OldGoldItemModel(metal: metal);
    item.descCtrl.text = description;
    item.grossCtrl.text = grossInput;
    item.lessCtrl.text = lessInput;
    item.purityCtrl.text = purityInput;
    item.rateCtrl.text = rateInput;
    return item;
  }
}
