part of 'metal_rate_model.dart';

MetalRateProfile _defaultFor(MetalRateMetal metal) {
  switch (metal) {
    case MetalRateMetal.gold:
      return MetalRateProfile(
        metal: metal,
        marketSource: 'Manual',
        mcxRatePer10g: 0,
        physicalMarketRatePer10g: 0,
        marketRatePer10g: 0,
        gstPercent: 0,
        importDutyPercent: 0.0,
        logisticsPercent: 0,
        wastageBufferPercent: 0,
        holdingCostPercent: 0,
        competitiveDiscountPercent: 0,
        minimumMarginPercent: 0,
        posture: PricingPosture.balanced,
        updatedAt: DateTime.now(),
        brandBenchmarks: const [],
        purityPlans: const [
          MetalRatePurityPlan(
            label: '24K',
            purityPercent: 99.9,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            manualDisplayRatePer10g: 0,
            buyRatePer10g: 0,
            supplierBillingPercent: 0,
            shopMarkupPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: '22K',
            purityPercent: 91.6,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            manualDisplayRatePer10g: 0,
            buyRatePer10g: 0,
            supplierBillingPercent: 0,
            shopMarkupPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: '18K',
            purityPercent: 75.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            manualDisplayRatePer10g: 0,
            buyRatePer10g: 0,
            supplierBillingPercent: 0,
            shopMarkupPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: '14K',
            purityPercent: 58.5,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            manualDisplayRatePer10g: 0,
            buyRatePer10g: 0,
            supplierBillingPercent: 0,
            shopMarkupPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: '9K',
            purityPercent: 37.5,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            manualDisplayRatePer10g: 0,
            buyRatePer10g: 0,
            supplierBillingPercent: 0,
            shopMarkupPercent: 0,
            makingChargePercent: 0,
          ),
        ],
      );
    case MetalRateMetal.silver:
      return _simpleDefault(
        metal: metal,
        source: 'Manual',
        rate: 0,
        gst: 0,
        margin: 0,
        purities: const [
          MetalRatePurityPlan(
            label: '999',
            purityPercent: 99.9,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePerGram: 0,
          ),
          MetalRatePurityPlan(
            label: '925',
            purityPercent: 92.5,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePerGram: 0,
          ),
          MetalRatePurityPlan(
            label: '800',
            purityPercent: 80.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePerGram: 0,
          ),
          MetalRatePurityPlan(
            label: '700',
            purityPercent: 70.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePerGram: 0,
          ),
        ],
      );
    case MetalRateMetal.diamond:
      return _simpleDefault(
        metal: metal,
        source: 'Manual',
        rate: 0,
        gst: 0,
        margin: 0,
        purities: const [
          MetalRatePurityPlan(
            label: 'Solitaire',
            purityPercent: 100,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: 'Studded 18K',
            purityPercent: 75.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: 'Lab Grown',
            purityPercent: 100,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
        ],
      );
    case MetalRateMetal.platinum:
      return _simpleDefault(
        metal: metal,
        source: 'Manual',
        rate: 0,
        gst: 0,
        margin: 0,
        purities: const [
          MetalRatePurityPlan(
            label: 'PT950',
            purityPercent: 95.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: 'PT900',
            purityPercent: 90.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
          MetalRatePurityPlan(
            label: 'PT850',
            purityPercent: 85.0,
            supplierPremiumPercent: 0,
            targetMarginPercent: 0,
            makingChargePercent: 0,
          ),
        ],
      );
  }
}

MetalRateProfile _simpleDefault({
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
    physicalMarketRatePer10g: rate,
    marketRatePer10g: rate,
    gstPercent: gst,
    importDutyPercent: 0.0,
    logisticsPercent: 0,
    wastageBufferPercent: 0,
    holdingCostPercent: 0,
    competitiveDiscountPercent: 0,
    minimumMarginPercent: margin,
    posture: PricingPosture.balanced,
    updatedAt: DateTime.now(),
    brandBenchmarks: const [],
    purityPlans: purities,
  );
}
