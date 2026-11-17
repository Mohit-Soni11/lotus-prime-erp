part of 'metal_rate_model.dart';

class MetalRatePurityPlan {
  final String label;
  final double purityPercent;
  final double supplierPremiumPercent;
  final double targetMarginPercent;
  final double landedCostOverridePer10g;
  final double manualDisplayRatePer10g;
  final double buyRatePer10g;
  final double supplierBillingPercent;
  final double shopMarkupPercent;
  final double makingChargePercent;
  final double makingChargePerGram;

  const MetalRatePurityPlan({
    required this.label,
    required this.purityPercent,
    required this.supplierPremiumPercent,
    required this.targetMarginPercent,
    this.landedCostOverridePer10g = 0.0,
    this.manualDisplayRatePer10g = 0.0,
    this.buyRatePer10g = 0.0,
    this.supplierBillingPercent = 0.0,
    this.shopMarkupPercent = 0.0,
    this.makingChargePercent = 0.0,
    this.makingChargePerGram = 0.0,
  });

  double get purityFactor => purityPercent <= 0 ? 1.0 : purityPercent / 100.0;

  double get supplierBillingFactor {
    final effective =
        supplierBillingPercent > 0 ? supplierBillingPercent : purityPercent;
    return effective <= 0 ? purityFactor : effective / 100.0;
  }

  MetalRatePurityPlan copyWith({
    String? label,
    double? purityPercent,
    double? supplierPremiumPercent,
    double? targetMarginPercent,
    double? landedCostOverridePer10g,
    double? manualDisplayRatePer10g,
    double? buyRatePer10g,
    double? supplierBillingPercent,
    double? shopMarkupPercent,
    double? makingChargePercent,
    double? makingChargePerGram,
  }) {
    return MetalRatePurityPlan(
      label: label ?? this.label,
      purityPercent: purityPercent ?? this.purityPercent,
      supplierPremiumPercent:
          supplierPremiumPercent ?? this.supplierPremiumPercent,
      targetMarginPercent: targetMarginPercent ?? this.targetMarginPercent,
      landedCostOverridePer10g:
          landedCostOverridePer10g ?? this.landedCostOverridePer10g,
      manualDisplayRatePer10g:
          manualDisplayRatePer10g ?? this.manualDisplayRatePer10g,
      buyRatePer10g: buyRatePer10g ?? this.buyRatePer10g,
      supplierBillingPercent:
          supplierBillingPercent ?? this.supplierBillingPercent,
      shopMarkupPercent: shopMarkupPercent ?? this.shopMarkupPercent,
      makingChargePercent: makingChargePercent ?? this.makingChargePercent,
      makingChargePerGram: makingChargePerGram ?? this.makingChargePerGram,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'purityPercent': purityPercent,
        'supplierPremiumPercent': supplierPremiumPercent,
        'targetMarginPercent': targetMarginPercent,
        'landedCostOverridePer10g': landedCostOverridePer10g,
        'manualDisplayRatePer10g': manualDisplayRatePer10g,
        'buyRatePer10g': buyRatePer10g,
        'supplierBillingPercent': supplierBillingPercent,
        'shopMarkupPercent': shopMarkupPercent,
        'makingChargePercent': makingChargePercent,
        'makingChargePerGram': makingChargePerGram,
      };

  factory MetalRatePurityPlan.fromJson(Map<String, dynamic> json) {
    return MetalRatePurityPlan(
      label: json['label'] as String? ?? 'Standard',
      purityPercent: _toDouble(json['purityPercent'], fallback: 100.0),
      supplierPremiumPercent: _toDouble(json['supplierPremiumPercent']),
      targetMarginPercent: _toDouble(json['targetMarginPercent']),
      landedCostOverridePer10g: _toDouble(json['landedCostOverridePer10g']),
      manualDisplayRatePer10g: _toDouble(json['manualDisplayRatePer10g']),
      buyRatePer10g: _toDouble(json['buyRatePer10g']),
      supplierBillingPercent: _toDouble(json['supplierBillingPercent']),
      shopMarkupPercent: _toDouble(json['shopMarkupPercent']),
      makingChargePercent: _toDouble(json['makingChargePercent']),
      makingChargePerGram: _toDouble(json['makingChargePerGram']),
    );
  }
}
