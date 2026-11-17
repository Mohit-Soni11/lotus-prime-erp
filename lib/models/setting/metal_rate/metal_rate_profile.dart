part of 'metal_rate_model.dart';

class MetalRateProfile {
  final MetalRateMetal metal;
  final String marketSource;
  // Persisted JSON keys predate the per-kg silver market; silver values use kg.
  final double mcxRatePer10g;
  final double physicalMarketRatePer10g;
  final double marketRatePer10g;
  final double? oldMetalPurchaseRatePer10g;
  final double gstPercent;
  final double importDutyPercent;
  final double logisticsPercent;
  final double wastageBufferPercent;
  final double holdingCostPercent;
  final double competitiveDiscountPercent;
  final double minimumMarginPercent;
  final PricingPosture posture;
  final DateTime updatedAt;
  final List<MetalRateBrandBenchmark> brandBenchmarks;
  final List<MetalRatePurityPlan> purityPlans;

  const MetalRateProfile({
    required this.metal,
    required this.marketSource,
    required this.mcxRatePer10g,
    required this.physicalMarketRatePer10g,
    required this.marketRatePer10g,
    this.oldMetalPurchaseRatePer10g,
    required this.gstPercent,
    required this.importDutyPercent,
    required this.logisticsPercent,
    required this.wastageBufferPercent,
    required this.holdingCostPercent,
    required this.competitiveDiscountPercent,
    required this.minimumMarginPercent,
    required this.posture,
    required this.updatedAt,
    required this.brandBenchmarks,
    required this.purityPlans,
  });

  double get marketBaseRatePer10g {
    if (physicalMarketRatePer10g > 0) {
      return physicalMarketRatePer10g;
    }
    if (marketRatePer10g > 0) {
      return marketRatePer10g;
    }
    return 0.0;
  }

  bool isMarketBasePlan(MetalRatePurityPlan plan) {
    final primaryLabel = metal == MetalRateMetal.gold
        ? '24K'
        : purityPlans.isEmpty
            ? ''
            : purityPlans.first.label.toUpperCase().replaceAll('KT', 'K');
    final planLabel = plan.label.toUpperCase().replaceAll('KT', 'K');
    return planLabel == primaryLabel;
  }

  double marketParityRateFor(MetalRatePurityPlan plan) {
    final base = marketBaseRatePer10g;
    if (base <= 0) return 0;
    return isMarketBasePlan(plan) ? base : base * plan.purityFactor;
  }

  double get primaryShopRatePer10g {
    if (purityPlans.isEmpty) {
      return marketBaseRatePer10g;
    }
    final first = purityPlans.first;
    return effectiveSellingRateFor(first);
  }

  /// The counter rate applied to billing when no manual override is entered.
  /// Local 70% silver jewellery always requires its own entered rate.
  double effectiveSellingRateFor(MetalRatePurityPlan plan) {
    if (plan.manualDisplayRatePer10g > 0) {
      return plan.manualDisplayRatePer10g;
    }
    if (metal == MetalRateMetal.silver && plan.label == '700') {
      return 0;
    }
    return marketParityRateFor(plan);
  }

  double get primaryBuyRatePer10g {
    if (oldMetalPurchaseRatePer10g != null) {
      return oldMetalPurchaseRatePer10g!;
    }
    if (purityPlans.isEmpty) {
      return 0.0;
    }
    return purityPlans.first.buyRatePer10g;
  }

  MetalRateProfile copyWith({
    MetalRateMetal? metal,
    String? marketSource,
    double? mcxRatePer10g,
    double? physicalMarketRatePer10g,
    double? marketRatePer10g,
    double? oldMetalPurchaseRatePer10g,
    double? gstPercent,
    double? importDutyPercent,
    double? logisticsPercent,
    double? wastageBufferPercent,
    double? holdingCostPercent,
    double? competitiveDiscountPercent,
    double? minimumMarginPercent,
    PricingPosture? posture,
    DateTime? updatedAt,
    List<MetalRateBrandBenchmark>? brandBenchmarks,
    List<MetalRatePurityPlan>? purityPlans,
  }) {
    return MetalRateProfile(
      metal: metal ?? this.metal,
      marketSource: marketSource ?? this.marketSource,
      mcxRatePer10g: mcxRatePer10g ?? this.mcxRatePer10g,
      physicalMarketRatePer10g:
          physicalMarketRatePer10g ?? this.physicalMarketRatePer10g,
      marketRatePer10g: marketRatePer10g ?? this.marketRatePer10g,
      oldMetalPurchaseRatePer10g:
          oldMetalPurchaseRatePer10g ?? this.oldMetalPurchaseRatePer10g,
      gstPercent: gstPercent ?? this.gstPercent,
      importDutyPercent: importDutyPercent ?? this.importDutyPercent,
      logisticsPercent: logisticsPercent ?? this.logisticsPercent,
      wastageBufferPercent: wastageBufferPercent ?? this.wastageBufferPercent,
      holdingCostPercent: holdingCostPercent ?? this.holdingCostPercent,
      competitiveDiscountPercent:
          competitiveDiscountPercent ?? this.competitiveDiscountPercent,
      minimumMarginPercent: minimumMarginPercent ?? this.minimumMarginPercent,
      posture: posture ?? this.posture,
      updatedAt: updatedAt ?? this.updatedAt,
      brandBenchmarks: brandBenchmarks ?? this.brandBenchmarks,
      purityPlans: purityPlans ?? this.purityPlans,
    );
  }

  Map<String, dynamic> toJson() => {
        'metal': metal.key,
        'marketSource': marketSource,
        'mcxRatePer10g': mcxRatePer10g,
        'physicalMarketRatePer10g': physicalMarketRatePer10g,
        'marketRatePer10g': marketRatePer10g,
        'oldMetalPurchaseRatePer10g': oldMetalPurchaseRatePer10g,
        'gstPercent': gstPercent,
        'importDutyPercent': importDutyPercent,
        'logisticsPercent': logisticsPercent,
        'wastageBufferPercent': wastageBufferPercent,
        'holdingCostPercent': holdingCostPercent,
        'competitiveDiscountPercent': competitiveDiscountPercent,
        'minimumMarginPercent': minimumMarginPercent,
        'posture': posture.name,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'brandBenchmarks':
            brandBenchmarks.map((brand) => brand.toJson()).toList(),
        'purityPlans': purityPlans.map((plan) => plan.toJson()).toList(),
      };

  factory MetalRateProfile.fromJson(Map<String, dynamic> json) {
    final metal = MetalRateMetalX.fromKey(json['metal'] as String? ?? 'gold');
    return MetalRateProfile(
      metal: metal,
      marketSource: json['marketSource'] as String? ?? 'Manual',
      mcxRatePer10g: _toDouble(
        json['mcxRatePer10g'],
        fallback: _toDouble(json['marketRatePer10g']),
      ),
      physicalMarketRatePer10g: _toDouble(
        json['physicalMarketRatePer10g'],
        fallback: _toDouble(json['marketRatePer10g']),
      ),
      marketRatePer10g: _toDouble(json['marketRatePer10g']),
      oldMetalPurchaseRatePer10g: json['oldMetalPurchaseRatePer10g'] == null
          ? null
          : _toDouble(json['oldMetalPurchaseRatePer10g']),
      gstPercent: _toDouble(json['gstPercent']),
      importDutyPercent: _toDouble(json['importDutyPercent']),
      logisticsPercent: _toDouble(json['logisticsPercent']),
      wastageBufferPercent: _toDouble(json['wastageBufferPercent']),
      holdingCostPercent: _toDouble(json['holdingCostPercent']),
      competitiveDiscountPercent: _toDouble(json['competitiveDiscountPercent']),
      minimumMarginPercent: _toDouble(json['minimumMarginPercent']),
      posture: PricingPostureX.fromName(json['posture'] as String? ?? ''),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      brandBenchmarks: ((json['brandBenchmarks'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              MetalRateBrandBenchmark.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      purityPlans: _withSilverJewelleryPlan(
        metal,
        ((json['purityPlans'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) =>
                MetalRatePurityPlan.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      ),
    );
  }

  static MetalRateProfile defaultFor(MetalRateMetal metal) =>
      _defaultFor(metal);
}

List<MetalRatePurityPlan> _withSilverJewelleryPlan(
  MetalRateMetal metal,
  List<MetalRatePurityPlan> plans,
) {
  if (metal != MetalRateMetal.silver) {
    return plans;
  }
  final retained = List<MetalRatePurityPlan>.of(plans);
  if (retained.any((plan) => plan.label.trim() == '700')) {
    return retained;
  }
  return [
    ...retained,
    const MetalRatePurityPlan(
      label: '700',
      purityPercent: 70,
      supplierPremiumPercent: 0,
      targetMarginPercent: 0,
    ),
  ];
}
