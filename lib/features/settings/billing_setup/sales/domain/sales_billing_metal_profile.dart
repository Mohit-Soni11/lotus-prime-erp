import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';

enum SalesBillingFieldKey {
  pieces,
  grossWeight,
  lessWeight,
  netWeight,
  purity,
  rate,
  makingCharges,
  makingChargeType,
  stoneDetails,
  stoneValue,
  totalValue,
  huid,
  wastage,
  oldGoldLine,
  diamondClarity,
  certificationNo,
  diamondCarats,
  diamondPieces,
  metalWeight,
  fineWeight,
  gstBreakup,
  hsnCode,
}

class SalesBillingFieldDefinition {
  final SalesBillingFieldKey key;
  final String label;
  final String description;

  const SalesBillingFieldDefinition({
    required this.key,
    required this.label,
    required this.description,
  });
}

class SalesBillingMetalProfile {
  final String metal;
  final String title;
  final String subtitle;
  final String shortDescription;

  const SalesBillingMetalProfile({
    required this.metal,
    required this.title,
    required this.subtitle,
    required this.shortDescription,
  });
}

class SalesBillingMetalProfiles {
  SalesBillingMetalProfiles._();

  static const List<SalesBillingMetalProfile> all = [
    SalesBillingMetalProfile(
      metal: BillingMetal.gold,
      title: 'Gold',
      subtitle: 'HUID, old gold exchange, purity, making, and buyback rules.',
      shortDescription: 'Hallmark compliant invoice controls.',
    ),
    SalesBillingMetalProfile(
      metal: BillingMetal.silver,
      title: 'Silver',
      subtitle: 'Fast counter billing fields, purity, rate, and footer copy.',
      shortDescription: 'Silver invoice defaults.',
    ),
    SalesBillingMetalProfile(
      metal: BillingMetal.diamond,
      title: 'Diamond',
      subtitle: 'Carat, clarity, certificate, stone value, and premium terms.',
      shortDescription: 'Diamond item display controls.',
    ),
    SalesBillingMetalProfile(
      metal: BillingMetal.platinum,
      title: 'Platinum',
      subtitle: 'Purity, weight, premium making, and buyback policy.',
      shortDescription: 'Platinum invoice rules.',
    ),
  ];

  static SalesBillingMetalProfile byMetal(String metal) {
    return all.firstWhere(
      (profile) => profile.metal == metal,
      orElse: () => all.first,
    );
  }

  static List<SalesBillingFieldDefinition> fieldsFor(String metal) {
    final fields = <SalesBillingFieldDefinition>[
      const SalesBillingFieldDefinition(
        key: SalesBillingFieldKey.pieces,
        label: 'Pieces',
        description: 'Number of pieces in the item row.',
      ),
      const SalesBillingFieldDefinition(
        key: SalesBillingFieldKey.grossWeight,
        label: 'Gross Weight',
        description: 'Total weight before deductions.',
      ),
    ];

    if (metal != BillingMetal.diamond) {
      fields.addAll(const [
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.lessWeight,
          label: 'Less Weight',
          description: 'Stone, beading, or other deducted weight.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.netWeight,
          label: 'Net Weight',
          description: 'Final billable weight after deductions.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.purity,
          label: 'Purity',
          description: 'Purity such as 22KT, 925, or 950PT.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.rate,
          label: 'Rate',
          description: 'Metal rate shown on the invoice.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.makingCharges,
          label: 'Making Amount',
          description: 'Calculated making charge amount.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.makingChargeType,
          label: 'Making Rate Type',
          description: 'Making entry such as percentage or per gram.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.fineWeight,
          label: 'Fine Weight',
          description: 'Calculated fine weight for purity-led billing.',
        ),
      ]);
    }

    if (metal == BillingMetal.gold) {
      fields.addAll(const [
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.huid,
          label: 'HUID Number',
          description: 'BIS hallmark number for compliant gold billing.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.wastage,
          label: 'Wastage',
          description: 'Wastage percentage as a separate invoice line.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.oldGoldLine,
          label: 'Old Gold Exchange',
          description: 'Exchange deduction when customer gives old gold.',
        ),
      ]);
    }

    if (metal == BillingMetal.diamond) {
      fields.addAll(const [
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.metalWeight,
          label: 'Metal Frame Weight',
          description: 'Weight of the gold, silver, or platinum setting.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.diamondCarats,
          label: 'Diamond Carats',
          description: 'Total diamond weight in carats.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.diamondPieces,
          label: 'Diamond Pieces',
          description: 'Number of diamond pieces.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.diamondClarity,
          label: 'Clarity Grade',
          description: 'VVS1, VS1, SI1, and similar quality grades.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.certificationNo,
          label: 'Certificate Number',
          description: 'GIA, IGI, HRD, or internal certificate number.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.makingCharges,
          label: 'Making Amount',
          description: 'Calculated making charge amount.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.makingChargeType,
          label: 'Making Rate Type',
          description: 'Making entry such as percentage or fixed amount.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.rate,
          label: 'Rate',
          description: 'Diamond rate shown on the invoice.',
        ),
      ]);
    }

    if (metal != BillingMetal.diamond) {
      fields.addAll(const [
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.stoneDetails,
          label: 'Stone Details',
          description: 'Stone type, carat, pieces, and description.',
        ),
        SalesBillingFieldDefinition(
          key: SalesBillingFieldKey.stoneValue,
          label: 'Stone Value',
          description: 'Stone value as a separate invoice amount.',
        ),
      ]);
    }

    fields.addAll(const [
      SalesBillingFieldDefinition(
        key: SalesBillingFieldKey.gstBreakup,
        label: 'GST Breakup',
        description: 'Separate CGST and SGST lines on the invoice.',
      ),
      SalesBillingFieldDefinition(
        key: SalesBillingFieldKey.hsnCode,
        label: 'HSN Code',
        description: 'HSN code line for compliance reporting.',
      ),
      SalesBillingFieldDefinition(
        key: SalesBillingFieldKey.totalValue,
        label: 'Total Value',
        description: 'Final item total on the invoice row.',
      ),
    ]);

    return fields;
  }

  static int activeFieldCount(SalesBillingModel model) {
    return fieldsFor(model.metal)
        .where((field) => valueFor(model, field.key))
        .length;
  }

  static bool valueFor(
    SalesBillingModel model,
    SalesBillingFieldKey key,
  ) {
    switch (key) {
      case SalesBillingFieldKey.pieces:
        return model.showPieces;
      case SalesBillingFieldKey.grossWeight:
        return model.showGrossWeight;
      case SalesBillingFieldKey.lessWeight:
        return model.showLessWeight;
      case SalesBillingFieldKey.netWeight:
        return model.showNetWeight;
      case SalesBillingFieldKey.purity:
        return model.showPurity;
      case SalesBillingFieldKey.rate:
        return model.showRate;
      case SalesBillingFieldKey.makingCharges:
        return model.showMakingCharges;
      case SalesBillingFieldKey.makingChargeType:
        return model.showMakingChargeType;
      case SalesBillingFieldKey.stoneDetails:
        return model.showStoneDetails;
      case SalesBillingFieldKey.stoneValue:
        return model.showStoneValue;
      case SalesBillingFieldKey.totalValue:
        return model.showTotalValue;
      case SalesBillingFieldKey.huid:
        return model.showHuid;
      case SalesBillingFieldKey.wastage:
        return model.showWastage;
      case SalesBillingFieldKey.oldGoldLine:
        return model.showOldGoldLine;
      case SalesBillingFieldKey.diamondClarity:
        return model.showDiamondClarity;
      case SalesBillingFieldKey.certificationNo:
        return model.showCertificationNo;
      case SalesBillingFieldKey.diamondCarats:
        return model.showDiamondCarats;
      case SalesBillingFieldKey.diamondPieces:
        return model.showDiamondPieces;
      case SalesBillingFieldKey.metalWeight:
        return model.showMetalWeight;
      case SalesBillingFieldKey.fineWeight:
        return model.showFineWeight;
      case SalesBillingFieldKey.gstBreakup:
        return model.showGstBreakup;
      case SalesBillingFieldKey.hsnCode:
        return model.showHsnCode;
    }
  }

  static SalesBillingModel setValue(
    SalesBillingModel model,
    SalesBillingFieldKey key,
    bool value,
  ) {
    switch (key) {
      case SalesBillingFieldKey.pieces:
        return model.copyWith(showPieces: value);
      case SalesBillingFieldKey.grossWeight:
        return model.copyWith(showGrossWeight: value);
      case SalesBillingFieldKey.lessWeight:
        return model.copyWith(showLessWeight: value);
      case SalesBillingFieldKey.netWeight:
        return model.copyWith(showNetWeight: value);
      case SalesBillingFieldKey.purity:
        return model.copyWith(showPurity: value);
      case SalesBillingFieldKey.rate:
        return model.copyWith(showRate: value);
      case SalesBillingFieldKey.makingCharges:
        return model.copyWith(showMakingCharges: value);
      case SalesBillingFieldKey.makingChargeType:
        return model.copyWith(showMakingChargeType: value);
      case SalesBillingFieldKey.stoneDetails:
        return model.copyWith(showStoneDetails: value);
      case SalesBillingFieldKey.stoneValue:
        return model.copyWith(showStoneValue: value);
      case SalesBillingFieldKey.totalValue:
        return model.copyWith(showTotalValue: value);
      case SalesBillingFieldKey.huid:
        return model.copyWith(showHuid: value);
      case SalesBillingFieldKey.wastage:
        return model.copyWith(showWastage: value);
      case SalesBillingFieldKey.oldGoldLine:
        return model.copyWith(showOldGoldLine: value);
      case SalesBillingFieldKey.diamondClarity:
        return model.copyWith(showDiamondClarity: value);
      case SalesBillingFieldKey.certificationNo:
        return model.copyWith(showCertificationNo: value);
      case SalesBillingFieldKey.diamondCarats:
        return model.copyWith(showDiamondCarats: value);
      case SalesBillingFieldKey.diamondPieces:
        return model.copyWith(showDiamondPieces: value);
      case SalesBillingFieldKey.metalWeight:
        return model.copyWith(showMetalWeight: value);
      case SalesBillingFieldKey.fineWeight:
        return model.copyWith(showFineWeight: value);
      case SalesBillingFieldKey.gstBreakup:
        return model.copyWith(showGstBreakup: value);
      case SalesBillingFieldKey.hsnCode:
        return model.copyWith(showHsnCode: value);
    }
  }
}
