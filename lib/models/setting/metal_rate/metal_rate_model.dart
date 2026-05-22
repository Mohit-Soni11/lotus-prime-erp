// =============================================================================
// FILE        : lib/models/setting/metal_rate/metal_rate_model.dart
// MODULE      : Metal Rate Setting
// LAYER       : Models
// DESCRIPTION : Immutable pricing models and smart-rate calculations.
// =============================================================================

import 'dart:math' as math;

enum MetalRateMetal { gold, silver, diamond, platinum }

extension MetalRateMetalX on MetalRateMetal {
  String get key => name;

  String get label {
    switch (this) {
      case MetalRateMetal.gold:
        return 'Gold';
      case MetalRateMetal.silver:
        return 'Silver';
      case MetalRateMetal.diamond:
        return 'Diamond';
      case MetalRateMetal.platinum:
        return 'Platinum';
    }
  }

  String get assetPath {
    switch (this) {
      case MetalRateMetal.gold:
        return 'lib/logo/gold.jpeg';
      case MetalRateMetal.silver:
      case MetalRateMetal.platinum:
        return 'lib/logo/silver and platinum .jpeg';
      case MetalRateMetal.diamond:
        return 'lib/logo/diamond .jpeg';
    }
  }

  static MetalRateMetal fromKey(String key) {
    return MetalRateMetal.values.firstWhere(
      (metal) => metal.key == key.toLowerCase(),
      orElse: () => MetalRateMetal.gold,
    );
  }
}

enum PricingPosture { defensive, balanced, growth }

extension PricingPostureX on PricingPosture {
  String get label {
    switch (this) {
      case PricingPosture.defensive:
        return 'Defensive';
      case PricingPosture.balanced:
        return 'Balanced';
      case PricingPosture.growth:
        return 'Growth';
    }
  }

  double get brandBlend {
    switch (this) {
      case PricingPosture.defensive:
        return 0.32;
      case PricingPosture.balanced:
        return 0.44;
      case PricingPosture.growth:
        return 0.56;
    }
  }

  static PricingPosture fromName(String value) {
    return PricingPosture.values.firstWhere(
      (posture) => posture.name == value,
      orElse: () => PricingPosture.balanced,
    );
  }
}

class MetalRateBrandBenchmark {
  final String brandName;
  final double referenceRatePer10g;
  final double makingLowPercent;
  final double makingHighPercent;
  final Map<String, double> rateByPurity;
  final Map<String, double> makingByPurity;
  final String notes;

  const MetalRateBrandBenchmark({
    required this.brandName,
    required this.referenceRatePer10g,
    required this.makingLowPercent,
    required this.makingHighPercent,
    this.rateByPurity = const {},
    this.makingByPurity = const {},
    this.notes = '',
  });

  double get averageMakingPercent =>
      (makingLowPercent + makingHighPercent) / 2.0;

  double rateFor(MetalRatePurityPlan plan) {
    final saved = rateByPurity[_purityKey(plan.label)] ?? 0.0;
    if (saved > 0) {
      return saved;
    }
    return referenceRatePer10g * plan.purityFactor;
  }

  double makingFor(MetalRatePurityPlan plan) {
    final saved = makingByPurity[_purityKey(plan.label)] ?? 0.0;
    if (saved > 0) {
      return saved;
    }
    return averageMakingPercent;
  }

  MetalRateBrandBenchmark copyWith({
    String? brandName,
    double? referenceRatePer10g,
    double? makingLowPercent,
    double? makingHighPercent,
    Map<String, double>? rateByPurity,
    Map<String, double>? makingByPurity,
    String? notes,
  }) {
    return MetalRateBrandBenchmark(
      brandName: brandName ?? this.brandName,
      referenceRatePer10g: referenceRatePer10g ?? this.referenceRatePer10g,
      makingLowPercent: makingLowPercent ?? this.makingLowPercent,
      makingHighPercent: makingHighPercent ?? this.makingHighPercent,
      rateByPurity: rateByPurity ?? this.rateByPurity,
      makingByPurity: makingByPurity ?? this.makingByPurity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'brandName': brandName,
        'referenceRatePer10g': referenceRatePer10g,
        'makingLowPercent': makingLowPercent,
        'makingHighPercent': makingHighPercent,
        'rateByPurity': rateByPurity,
        'makingByPurity': makingByPurity,
        'notes': notes,
      };

  factory MetalRateBrandBenchmark.fromJson(Map<String, dynamic> json) {
    return MetalRateBrandBenchmark(
      brandName: json['brandName'] as String? ?? 'Brand',
      referenceRatePer10g: _toDouble(json['referenceRatePer10g']),
      makingLowPercent: _toDouble(json['makingLowPercent']),
      makingHighPercent: _toDouble(json['makingHighPercent']),
      rateByPurity: _toDoubleMap(json['rateByPurity']),
      makingByPurity: _toDoubleMap(json['makingByPurity']),
      notes: json['notes'] as String? ?? '',
    );
  }
}

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
    this.shopMarkupPercent = 4.0,
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
      targetMarginPercent:
          _toDouble(json['targetMarginPercent'], fallback: 4.0),
      landedCostOverridePer10g: _toDouble(json['landedCostOverridePer10g']),
      manualDisplayRatePer10g: _toDouble(json['manualDisplayRatePer10g']),
      buyRatePer10g: _toDouble(json['buyRatePer10g']),
      supplierBillingPercent: _toDouble(json['supplierBillingPercent']),
      shopMarkupPercent: _toDouble(json['shopMarkupPercent'], fallback: 4.0),
      makingChargePercent: _toDouble(json['makingChargePercent']),
      makingChargePerGram: _toDouble(json['makingChargePerGram']),
    );
  }
}

class MetalRateRecommendation {
  final String label;
  final double mcxRatePer10g;
  final double physicalRatePer10g;
  final double marketRatePer10g;
  final double landedCostPer10g;
  final double safeMinimumPer10g;
  final double brandAveragePer10g;
  final double brandMakingPercent;
  final double suggestedRatePer10g;
  final double marginPercent;
  final double cheaperThanBrandPercent;
  final double suggestedMakingPercent;
  final double suggestedMakingPerGram;
  final double selectedMakingPercent;
  final double selectedMakingPerGram;
  final double customerTotalPer10g;
  final bool usesCostOverride;
  final bool usesManualDisplayRate;
  final bool usesManualMaking;
  final bool belowBrandAverage;
  final String guardrail;

  const MetalRateRecommendation({
    required this.label,
    required this.mcxRatePer10g,
    required this.physicalRatePer10g,
    required this.marketRatePer10g,
    required this.landedCostPer10g,
    required this.safeMinimumPer10g,
    required this.brandAveragePer10g,
    required this.brandMakingPercent,
    required this.suggestedRatePer10g,
    required this.marginPercent,
    required this.cheaperThanBrandPercent,
    required this.suggestedMakingPercent,
    required this.suggestedMakingPerGram,
    required this.selectedMakingPercent,
    required this.selectedMakingPerGram,
    required this.customerTotalPer10g,
    required this.usesCostOverride,
    required this.usesManualDisplayRate,
    required this.usesManualMaking,
    required this.belowBrandAverage,
    required this.guardrail,
  });
}

class MetalRateProfile {
  final MetalRateMetal metal;
  final String marketSource;
  final double mcxRatePer10g;
  final double physicalMarketRatePer10g;
  final double marketRatePer10g;
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
    final mcx = mcxRatePer10g > 0 ? mcxRatePer10g : marketRatePer10g;
    final physical = physicalMarketRatePer10g > 0
        ? physicalMarketRatePer10g
        : marketRatePer10g;
    if (mcx <= 0 && physical <= 0) {
      return marketRatePer10g;
    }
    if (mcx <= 0) {
      return physical;
    }
    if (physical <= 0) {
      return mcx;
    }
    return (mcx * 0.45) + (physical * 0.55);
  }

  double brandAverageRateFor(MetalRatePurityPlan plan) {
    final valid = brandBenchmarks
        .map((brand) => brand.rateFor(plan))
        .where((rate) => rate > 0)
        .toList(growable: false);
    if (valid.isEmpty) {
      return 0.0;
    }
    return valid.fold<double>(0.0, (sum, rate) => sum + rate) / valid.length;
  }

  double averageBrandMakingFor(MetalRatePurityPlan plan) {
    final valid = brandBenchmarks
        .map((brand) => brand.makingFor(plan))
        .where((making) => making > 0)
        .toList(growable: false);
    if (valid.isEmpty) {
      return 0.0;
    }
    return valid.fold<double>(0.0, (sum, making) => sum + making) /
        valid.length;
  }

  double get brandAverageRatePer10g {
    final plan = MetalRatePurityPlan(
      label: '24K',
      purityPercent: 99.9,
      supplierPremiumPercent: 0,
      targetMarginPercent: minimumMarginPercent,
    );
    return brandAverageRateFor(plan);
  }

  double get averageBrandMakingPercent {
    final plan = MetalRatePurityPlan(
      label: '24K',
      purityPercent: 99.9,
      supplierPremiumPercent: 0,
      targetMarginPercent: minimumMarginPercent,
    );
    return averageBrandMakingFor(plan);
  }

  double get primaryShopRatePer10g {
    if (purityPlans.isEmpty) {
      return marketBaseRatePer10g;
    }
    final first = purityPlans.first;
    return first.manualDisplayRatePer10g > 0
        ? first.manualDisplayRatePer10g
        : marketBaseRatePer10g * first.purityFactor;
  }

  double get primaryBuyRatePer10g {
    if (purityPlans.isEmpty) {
      return 0.0;
    }
    return purityPlans.first.buyRatePer10g;
  }

  double get supplierBaseRatePer10g {
    if (physicalMarketRatePer10g > 0) {
      return physicalMarketRatePer10g;
    }
    if (mcxRatePer10g > 0) {
      return mcxRatePer10g;
    }
    return marketBaseRatePer10g;
  }

  double supplierCostFor(MetalRatePurityPlan plan) =>
      supplierBaseRatePer10g * plan.supplierBillingFactor;

  double suggestedShopRateFor(MetalRatePurityPlan plan) =>
      _roundRetail(supplierCostFor(plan) * (1 + plan.shopMarkupPercent / 100));

  double get allInOverheadPercent =>
      gstPercent +
      importDutyPercent +
      logisticsPercent +
      wastageBufferPercent +
      holdingCostPercent;

  MetalRateRecommendation recommendationFor(MetalRatePurityPlan plan) {
    final mcx = (mcxRatePer10g > 0 ? mcxRatePer10g : marketBaseRatePer10g) *
        plan.purityFactor;
    final physical = (physicalMarketRatePer10g > 0
            ? physicalMarketRatePer10g
            : marketBaseRatePer10g) *
        plan.purityFactor;
    final market = marketBaseRatePer10g * plan.purityFactor;
    final brandAverage = brandAverageRateFor(plan);
    final brand = brandAverage <= 0 ? market : brandAverage;
    final brandMaking = averageBrandMakingFor(plan);
    final calculatedLanded = market *
        (1 + (allInOverheadPercent + plan.supplierPremiumPercent) / 100.0);
    final landed = plan.landedCostOverridePer10g > 0
        ? plan.landedCostOverridePer10g
        : calculatedLanded;
    final safe = landed *
        (1 + math.max(minimumMarginPercent, plan.targetMarginPercent) / 100.0);
    final competitiveCeiling =
        brand * (1 - (competitiveDiscountPercent / 100.0));
    final blended = (safe * (1 - posture.brandBlend)) +
        (competitiveCeiling * posture.brandBlend);
    final automatic = math.max(safe, math.min(blended, competitiveCeiling));
    final suggested = plan.manualDisplayRatePer10g > 0
        ? plan.manualDisplayRatePer10g
        : _roundRetail(automatic);
    final suggestedMakingPercent = _suggestedMakingPercent(
      brandMaking: brandMaking,
      plan: plan,
      posture: posture,
    );
    final selectedMakingPercent = plan.makingChargePercent > 0
        ? plan.makingChargePercent
        : suggestedMakingPercent;
    final selectedMakingPerGram = plan.makingChargePerGram > 0
        ? plan.makingChargePerGram
        : (suggested / 10.0) * (selectedMakingPercent / 100.0);
    final suggestedMakingPerGram =
        (suggested / 10.0) * (suggestedMakingPercent / 100.0);
    final makingPer10g = selectedMakingPerGram * 10.0;
    final customerTotal = suggested + makingPer10g;
    final margin =
        landed <= 0 ? 0.0 : ((customerTotal - landed) / landed) * 100.0;
    final brandPosition =
        brand <= 0 ? 0.0 : ((brand - suggested) / brand) * 100.0;
    final guardrail = margin < minimumMarginPercent
        ? 'Review'
        : brandPosition < -0.5
            ? 'Premium'
            : 'Safe';

    return MetalRateRecommendation(
      label: plan.label,
      mcxRatePer10g: mcx,
      physicalRatePer10g: physical,
      marketRatePer10g: market,
      landedCostPer10g: landed,
      safeMinimumPer10g: safe,
      brandAveragePer10g: brand,
      brandMakingPercent: brandMaking,
      suggestedRatePer10g: suggested,
      marginPercent: margin,
      cheaperThanBrandPercent: brandPosition,
      suggestedMakingPercent: suggestedMakingPercent,
      suggestedMakingPerGram: suggestedMakingPerGram,
      selectedMakingPercent: selectedMakingPercent,
      selectedMakingPerGram: selectedMakingPerGram,
      customerTotalPer10g: customerTotal,
      usesCostOverride: plan.landedCostOverridePer10g > 0,
      usesManualDisplayRate: plan.manualDisplayRatePer10g > 0,
      usesManualMaking:
          plan.makingChargePercent > 0 || plan.makingChargePerGram > 0,
      belowBrandAverage: suggested <= brand,
      guardrail: guardrail,
    );
  }

  List<MetalRateRecommendation> get recommendations =>
      purityPlans.map(recommendationFor).toList(growable: false);

  MetalRateProfile copyWith({
    MetalRateMetal? metal,
    String? marketSource,
    double? mcxRatePer10g,
    double? physicalMarketRatePer10g,
    double? marketRatePer10g,
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
    return MetalRateProfile(
      metal: MetalRateMetalX.fromKey(json['metal'] as String? ?? 'gold'),
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
      gstPercent: _toDouble(json['gstPercent'], fallback: 3.0),
      importDutyPercent: _toDouble(json['importDutyPercent']),
      logisticsPercent: _toDouble(json['logisticsPercent']),
      wastageBufferPercent: _toDouble(json['wastageBufferPercent']),
      holdingCostPercent: _toDouble(json['holdingCostPercent']),
      competitiveDiscountPercent:
          _toDouble(json['competitiveDiscountPercent'], fallback: 1.2),
      minimumMarginPercent:
          _toDouble(json['minimumMarginPercent'], fallback: 3.0),
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
      purityPlans: ((json['purityPlans'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              MetalRatePurityPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static MetalRateProfile defaultFor(MetalRateMetal metal) {
    switch (metal) {
      case MetalRateMetal.gold:
        return MetalRateProfile(
          metal: metal,
          marketSource: 'MCX / Local Bullion Manual',
          mcxRatePer10g: 72500,
          physicalMarketRatePer10g: 72800,
          marketRatePer10g: 72665,
          gstPercent: 3.0,
          importDutyPercent: 0.0,
          logisticsPercent: 0.35,
          wastageBufferPercent: 0.75,
          holdingCostPercent: 0.45,
          competitiveDiscountPercent: 1.4,
          minimumMarginPercent: 3.25,
          posture: PricingPosture.balanced,
          updatedAt: DateTime.now(),
          brandBenchmarks: _defaultGoldBenchmarks(),
          purityPlans: const [
            MetalRatePurityPlan(
              label: '24K',
              purityPercent: 99.9,
              supplierPremiumPercent: 2.0,
              targetMarginPercent: 3.2,
              manualDisplayRatePer10g: 72800,
              buyRatePer10g: 71400,
              supplierBillingPercent: 100.0,
              shopMarkupPercent: 4.0,
              makingChargePercent: 4.0,
            ),
            MetalRatePurityPlan(
              label: '22K',
              purityPercent: 91.6,
              supplierPremiumPercent: 4.5,
              targetMarginPercent: 4.0,
              manualDisplayRatePer10g: 66700,
              buyRatePer10g: 65400,
              supplierBillingPercent: 92.0,
              shopMarkupPercent: 4.0,
              makingChargePercent: 6.0,
            ),
            MetalRatePurityPlan(
              label: '18K',
              purityPercent: 75.0,
              supplierPremiumPercent: 5.0,
              targetMarginPercent: 4.5,
              manualDisplayRatePer10g: 54600,
              buyRatePer10g: 53500,
              supplierBillingPercent: 80.0,
              shopMarkupPercent: 4.0,
              makingChargePercent: 7.5,
            ),
            MetalRatePurityPlan(
              label: '14K',
              purityPercent: 58.5,
              supplierPremiumPercent: 5.8,
              targetMarginPercent: 5.0,
              manualDisplayRatePer10g: 42600,
              buyRatePer10g: 41700,
              supplierBillingPercent: 62.0,
              shopMarkupPercent: 4.0,
              makingChargePercent: 8.5,
            ),
            MetalRatePurityPlan(
              label: '9K',
              purityPercent: 37.5,
              supplierPremiumPercent: 6.5,
              targetMarginPercent: 6.0,
              manualDisplayRatePer10g: 27300,
              buyRatePer10g: 26700,
              supplierBillingPercent: 40.0,
              shopMarkupPercent: 4.0,
              makingChargePercent: 10.0,
            ),
          ],
        );
      case MetalRateMetal.silver:
        return _simpleDefault(
          metal: metal,
          source: 'Silver Spot / Local Bullion Manual',
          rate: 920,
          gst: 3.0,
          margin: 5.0,
          purities: const [
            MetalRatePurityPlan(
              label: '999',
              purityPercent: 99.9,
              supplierPremiumPercent: 2.0,
              targetMarginPercent: 4.5,
              makingChargePerGram: 28,
            ),
            MetalRatePurityPlan(
              label: '925',
              purityPercent: 92.5,
              supplierPremiumPercent: 3.0,
              targetMarginPercent: 5.0,
              makingChargePerGram: 35,
            ),
            MetalRatePurityPlan(
              label: '800',
              purityPercent: 80.0,
              supplierPremiumPercent: 3.5,
              targetMarginPercent: 5.5,
              makingChargePerGram: 42,
            ),
          ],
        );
      case MetalRateMetal.diamond:
        return _simpleDefault(
          metal: metal,
          source: 'Diamond Counter Benchmark Manual',
          rate: 58500,
          gst: 3.0,
          margin: 9.0,
          purities: const [
            MetalRatePurityPlan(
              label: 'Solitaire',
              purityPercent: 100,
              supplierPremiumPercent: 6.0,
              targetMarginPercent: 10.0,
              makingChargePercent: 12.0,
            ),
            MetalRatePurityPlan(
              label: 'Studded 18K',
              purityPercent: 75.0,
              supplierPremiumPercent: 5.5,
              targetMarginPercent: 8.5,
              makingChargePercent: 10.0,
            ),
            MetalRatePurityPlan(
              label: 'Lab Grown',
              purityPercent: 100,
              supplierPremiumPercent: 4.0,
              targetMarginPercent: 7.0,
              makingChargePercent: 9.0,
            ),
          ],
        );
      case MetalRateMetal.platinum:
        return _simpleDefault(
          metal: metal,
          source: 'Platinum Spot / Local Supplier Manual',
          rate: 33500,
          gst: 3.0,
          margin: 6.0,
          purities: const [
            MetalRatePurityPlan(
              label: 'PT950',
              purityPercent: 95.0,
              supplierPremiumPercent: 4.0,
              targetMarginPercent: 6.5,
              makingChargePercent: 8.0,
            ),
            MetalRatePurityPlan(
              label: 'PT900',
              purityPercent: 90.0,
              supplierPremiumPercent: 4.2,
              targetMarginPercent: 6.8,
              makingChargePercent: 8.5,
            ),
            MetalRatePurityPlan(
              label: 'PT850',
              purityPercent: 85.0,
              supplierPremiumPercent: 4.5,
              targetMarginPercent: 7.0,
              makingChargePercent: 9.0,
            ),
          ],
        );
    }
  }

  static MetalRateProfile _simpleDefault({
    required MetalRateMetal metal,
    required String source,
    required double rate,
    required double gst,
    required double margin,
    required List<MetalRatePurityPlan> purities,
  }) {
    return MetalRateProfile(
      metal: metal,
      marketSource: source,
      mcxRatePer10g: rate,
      physicalMarketRatePer10g: rate * 1.004,
      marketRatePer10g: rate,
      gstPercent: gst,
      importDutyPercent: 0.0,
      logisticsPercent: 0.45,
      wastageBufferPercent: 0.65,
      holdingCostPercent: 0.50,
      competitiveDiscountPercent: 1.0,
      minimumMarginPercent: margin,
      posture: PricingPosture.balanced,
      updatedAt: DateTime.now(),
      brandBenchmarks: _defaultGenericBenchmarks(metal, rate),
      purityPlans: purities,
    );
  }
}

double _roundRetail(double value) {
  if (value <= 0) {
    return 0.0;
  }
  final rounded = (value / 10).ceil() * 10;
  return rounded.toDouble();
}

class MetalRateHistoryEntry {
  final MetalRateProfile profile;
  final DateTime changedAt;
  final String source;

  const MetalRateHistoryEntry({
    required this.profile,
    required this.changedAt,
    required this.source,
  });
}

double _toDouble(Object? value, {double fallback = 0.0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
  }
  return fallback;
}

Map<String, double> _toDoubleMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map(
    (key, item) => MapEntry(_purityKey(key.toString()), _toDouble(item)),
  );
}

String _purityKey(String value) {
  final cleaned = value.trim().toUpperCase().replaceAll('KT', 'K');
  return cleaned;
}

double _suggestedMakingPercent({
  required double brandMaking,
  required MetalRatePurityPlan plan,
  required PricingPosture posture,
}) {
  if (brandMaking <= 0) {
    return math.max(plan.targetMarginPercent, 4.0);
  }
  final multiplier = switch (posture) {
    PricingPosture.defensive => 0.58,
    PricingPosture.balanced => 0.64,
    PricingPosture.growth => 0.70,
  };
  return math.max(plan.targetMarginPercent, brandMaking * multiplier);
}

List<MetalRateBrandBenchmark> _defaultGoldBenchmarks() {
  return [
    _brandBenchmark(
      name: 'Tanishq',
      rate24: 73850,
      makingLow: 8,
      makingHigh: 24,
      notes: 'Premium national benchmark',
    ),
    _brandBenchmark(
      name: 'Malabar Gold',
      rate24: 73680,
      makingLow: 7,
      makingHigh: 22,
    ),
    _brandBenchmark(
      name: 'Kalyan Jewellers',
      rate24: 73740,
      makingLow: 8,
      makingHigh: 21,
    ),
    _brandBenchmark(
      name: 'Joyalukkas',
      rate24: 73620,
      makingLow: 7,
      makingHigh: 22,
    ),
    _brandBenchmark(
      name: 'Senco Gold',
      rate24: 73560,
      makingLow: 7,
      makingHigh: 20,
    ),
    _brandBenchmark(
      name: 'PC Jeweller',
      rate24: 73480,
      makingLow: 7,
      makingHigh: 19,
    ),
    _brandBenchmark(
      name: 'Reliance Jewels',
      rate24: 73590,
      makingLow: 7,
      makingHigh: 21,
    ),
    _brandBenchmark(
      name: 'CaratLane',
      rate24: 73920,
      makingLow: 9,
      makingHigh: 26,
    ),
    _brandBenchmark(
      name: 'BlueStone',
      rate24: 73810,
      makingLow: 9,
      makingHigh: 25,
    ),
    _brandBenchmark(
      name: 'Local Premium',
      rate24: 73350,
      makingLow: 5,
      makingHigh: 16,
      notes: 'Area competitor benchmark',
    ),
  ];
}

MetalRateBrandBenchmark _brandBenchmark({
  required String name,
  required double rate24,
  required double makingLow,
  required double makingHigh,
  String notes = '',
}) {
  final average = (makingLow + makingHigh) / 2.0;
  return MetalRateBrandBenchmark(
    brandName: name,
    referenceRatePer10g: rate24,
    makingLowPercent: makingLow,
    makingHighPercent: makingHigh,
    rateByPurity: _purityRateMap(rate24),
    makingByPurity: {
      '24K': math.max(2.0, average - 2.0),
      '22K': average,
      '18K': average + 1.5,
      '14K': average + 2.5,
      '9K': average + 3.5,
    },
    notes: notes,
  );
}

Map<String, double> _purityRateMap(double rate24) {
  return {
    '24K': _roundRetail(rate24 * 0.999),
    '22K': _roundRetail(rate24 * 0.916),
    '18K': _roundRetail(rate24 * 0.750),
    '14K': _roundRetail(rate24 * 0.585),
    '9K': _roundRetail(rate24 * 0.375),
  };
}

List<MetalRateBrandBenchmark> _defaultGenericBenchmarks(
  MetalRateMetal metal,
  double rate,
) {
  return [
    _brandBenchmark(
      name: '${metal.label} Premium',
      rate24: rate * 1.035,
      makingLow: 6,
      makingHigh: 18,
    ),
    _brandBenchmark(
      name: '${metal.label} Retail',
      rate24: rate * 1.025,
      makingLow: 5,
      makingHigh: 15,
    ),
    _brandBenchmark(
      name: 'Local Benchmark',
      rate24: rate * 1.015,
      makingLow: 4,
      makingHigh: 12,
    ),
  ];
}
