// =============================================================================
// FILE        : lib/repositories/setting/metal_rate/metal_rate_quote_service.dart
// MODULE      : Metal Rate Setting
// LAYER       : Application Service
// DESCRIPTION : Shared quote resolver for billing, purchase and metal workflows.
// =============================================================================

import '../../../models/setting/metal_rate/metal_rate_model.dart';
import 'metal_rate_repository.dart';

enum MetalRateQuoteSide { selling, buying }

class MetalRateQuote {
  final MetalRateMetal metal;
  final MetalRateQuoteSide side;
  final String purityLabel;
  final double purityPercent;
  final double ratePer10g;
  final double billingRate;
  final String billingUnit;
  final double makingChargePercent;
  final double makingChargePerGram;
  final DateTime updatedAt;
  final String source;

  const MetalRateQuote({
    required this.metal,
    required this.side,
    required this.purityLabel,
    required this.purityPercent,
    required this.ratePer10g,
    required this.billingRate,
    required this.billingUnit,
    required this.makingChargePercent,
    required this.makingChargePerGram,
    required this.updatedAt,
    required this.source,
  });

  bool get hasRate => billingRate > 0;

  String get rateSourceLabel =>
      '${source.trim().isEmpty ? 'Metal Rate Master' : source} - $purityLabel';
}

class MetalRateQuoteService {
  final MetalRateRepository _repository;

  MetalRateQuoteService({MetalRateRepository? repository})
      : _repository = repository ?? MetalRateRepository();

  Future<MetalRateQuote?> sellingQuote({
    required MetalRateMetal metal,
    String? purityLabel,
    double? purityPercent,
  }) {
    return _resolveQuote(
      metal: metal,
      side: MetalRateQuoteSide.selling,
      purityLabel: purityLabel,
      purityPercent: purityPercent,
    );
  }

  Future<MetalRateQuote?> buyingQuote({
    required MetalRateMetal metal,
    String? purityLabel,
    double? purityPercent,
  }) {
    return _resolveQuote(
      metal: metal,
      side: MetalRateQuoteSide.buying,
      purityLabel: purityLabel,
      purityPercent: purityPercent,
    );
  }

  Future<Map<MetalRateMetal, MetalRateQuote>> defaultSellingQuotes() async {
    final quotes = <MetalRateMetal, MetalRateQuote>{};
    for (final metal in MetalRateMetal.values) {
      final quote = await sellingQuote(metal: metal);
      if (quote != null && quote.hasRate) {
        quotes[metal] = quote;
      }
    }
    return quotes;
  }

  Future<MetalRateQuote?> _resolveQuote({
    required MetalRateMetal metal,
    required MetalRateQuoteSide side,
    String? purityLabel,
    double? purityPercent,
  }) async {
    final profile = await _repository.loadProfile(metal);
    if (profile.purityPlans.isEmpty) {
      return null;
    }

    final plan = _findBestPlan(
      profile: profile,
      purityLabel: purityLabel,
      purityPercent: purityPercent,
    );
    if (plan == null) {
      return null;
    }

    final ratePer10g = side == MetalRateQuoteSide.selling
        ? _sellingRatePer10g(profile, plan)
        : plan.buyRatePer10g;

    if (ratePer10g <= 0) {
      return null;
    }

    return MetalRateQuote(
      metal: metal,
      side: side,
      purityLabel: plan.label,
      purityPercent: plan.purityPercent,
      ratePer10g: ratePer10g,
      billingRate: _billingRate(metal, ratePer10g),
      billingUnit: metal == MetalRateMetal.diamond ? 'ct' : 'g',
      makingChargePercent: plan.makingChargePercent,
      makingChargePerGram: plan.makingChargePerGram,
      updatedAt: profile.updatedAt,
      source: profile.marketSource,
    );
  }

  MetalRatePurityPlan? _findBestPlan({
    required MetalRateProfile profile,
    String? purityLabel,
    double? purityPercent,
  }) {
    final plans = profile.purityPlans;
    if (plans.isEmpty) {
      return null;
    }

    final labelKey = _normalisePurityKey(purityLabel ?? '');
    if (labelKey.isNotEmpty) {
      for (final plan in plans) {
        if (_normalisePurityKey(plan.label) == labelKey) {
          return plan;
        }
      }
    }

    final parsedPercent =
        purityPercent ?? _parsePurityPercent(purityLabel ?? '');
    if (parsedPercent != null && parsedPercent > 0) {
      MetalRatePurityPlan? closest;
      var closestGap = double.infinity;

      for (final plan in plans) {
        final gap = (plan.purityPercent - parsedPercent).abs();
        if (gap < closestGap) {
          closest = plan;
          closestGap = gap;
        }
      }

      if (closest != null && closestGap <= 7.5) {
        return closest;
      }
    }

    return purityLabel == null || purityLabel.trim().isEmpty
        ? plans.first
        : null;
  }

  double _sellingRatePer10g(
    MetalRateProfile profile,
    MetalRatePurityPlan plan,
  ) {
    if (plan.manualDisplayRatePer10g > 0) {
      return plan.manualDisplayRatePer10g;
    }
    if (profile.marketBaseRatePer10g <= 0) {
      return 0.0;
    }
    return profile.marketBaseRatePer10g * plan.purityFactor;
  }

  double _billingRate(MetalRateMetal metal, double ratePer10g) {
    if (metal == MetalRateMetal.diamond) {
      return ratePer10g;
    }
    return ratePer10g / 10.0;
  }
}

String _normalisePurityKey(String value) {
  var cleaned = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty) {
    return '';
  }
  cleaned = cleaned.replaceAll('KT', 'K');
  if (cleaned.startsWith('PT')) {
    cleaned = cleaned.substring(2);
  }
  if (cleaned.endsWith('PT')) {
    cleaned = cleaned.substring(0, cleaned.length - 2);
  }
  return cleaned;
}

double? _parsePurityPercent(String value) {
  final cleaned = value.trim().toUpperCase();
  if (cleaned.isEmpty) {
    return null;
  }

  const clarityAsFullPurity = {
    'VVS1': 100.0,
    'VVS2': 100.0,
    'VS1': 100.0,
    'VS2': 100.0,
    'SI1': 100.0,
    'SI2': 100.0,
  };
  final clarity = clarityAsFullPurity[cleaned];
  if (clarity != null) {
    return clarity;
  }

  final caratMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*K(T)?$').firstMatch(cleaned);
  if (caratMatch != null) {
    final carat = double.tryParse(caratMatch.group(1)!);
    if (carat != null && carat > 0) {
      return (carat / 24.0) * 100.0;
    }
  }

  final hallmark = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
  if (hallmark == null) {
    return null;
  }

  final number = double.tryParse(hallmark.group(1)!);
  if (number == null || number <= 0) {
    return null;
  }

  if (number > 100 && number <= 1000) {
    return number / 10.0;
  }
  return number.clamp(0.0, 100.0);
}
