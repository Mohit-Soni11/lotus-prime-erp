import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';

enum PurchaseBillingFieldKey {
  grossWeight,
  lessWeight,
  netWeight,
  purity,
  rate,
  fineWeight,
  totalValue,
  stoneDetails,
  stoneValue,
  huid,
  supplierDetails,
  panNumber,
  diamondCarats,
  diamondClarity,
  certificationNo,
  gstBreakup,
  hsnCode,
}

class PurchaseBillingFieldDefinition {
  final PurchaseBillingFieldKey key;
  final String label;
  final String description;

  const PurchaseBillingFieldDefinition({
    required this.key,
    required this.label,
    required this.description,
  });
}

class PurchaseBillingMetalProfile {
  final String metal;
  final String title;
  final String subtitle;
  final String shortDescription;

  const PurchaseBillingMetalProfile({
    required this.metal,
    required this.title,
    required this.subtitle,
    required this.shortDescription,
  });
}

class PurchaseBillingMetalProfiles {
  PurchaseBillingMetalProfiles._();

  static const List<PurchaseBillingMetalProfile> all = [
    PurchaseBillingMetalProfile(
      metal: BillingMetal.gold,
      title: 'Gold',
      subtitle: 'Hallmark, HUID, purity, fine weight, PAN, and supplier rules.',
      shortDescription: 'Gold voucher controls.',
    ),
    PurchaseBillingMetalProfile(
      metal: BillingMetal.silver,
      title: 'Silver',
      subtitle: 'Weight, purity, fine weight, supplier, and settlement policy.',
      shortDescription: 'Silver purchase defaults.',
    ),
    PurchaseBillingMetalProfile(
      metal: BillingMetal.diamond,
      title: 'Diamond',
      subtitle: 'Certificate, carat, clarity, value, and supplier checks.',
      shortDescription: 'Diamond acquisition controls.',
    ),
    PurchaseBillingMetalProfile(
      metal: BillingMetal.platinum,
      title: 'Platinum',
      subtitle: 'Purity, fine weight, rate, supplier, and return policy.',
      shortDescription: 'Platinum voucher rules.',
    ),
  ];

  static PurchaseBillingMetalProfile byMetal(String metal) {
    return all.firstWhere(
      (profile) => profile.metal == metal,
      orElse: () => all.first,
    );
  }

  static List<PurchaseBillingFieldDefinition> fieldsFor(String metal) {
    final fields = <PurchaseBillingFieldDefinition>[];

    if (metal != BillingMetal.diamond) {
      fields.addAll(const [
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.grossWeight,
          label: 'Gross Weight',
          description: 'Total received weight before deductions.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.lessWeight,
          label: 'Less Weight',
          description: 'Stone, beading, or other deducted weight.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.netWeight,
          label: 'Net Weight',
          description: 'Final billable purchase weight.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.purity,
          label: 'Purity',
          description: 'Purity such as 22KT, 925, or 950PT.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.rate,
          label: 'Rate',
          description: 'Purchase rate shown on the voucher.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.fineWeight,
          label: 'Fine Weight',
          description: 'Fine weight after purity calculation.',
        ),
      ]);
    } else {
      fields.addAll(const [
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.rate,
          label: 'Rate',
          description: 'Diamond purchase rate shown on the voucher.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.stoneDetails,
          label: 'Stone Details',
          description: 'Diamond or stone details on purchase voucher.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.stoneValue,
          label: 'Stone Value',
          description: 'Stone value as a separate purchase amount.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.diamondCarats,
          label: 'Diamond Carats',
          description: 'Total diamond weight in carats.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.diamondClarity,
          label: 'Clarity Grade',
          description: 'VVS1, VS1, SI1, and similar quality grades.',
        ),
        PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.certificationNo,
          label: 'Certificate Number',
          description: 'GIA, IGI, HRD, or internal certificate number.',
        ),
      ]);
    }

    if (metal == BillingMetal.gold) {
      fields.add(
        const PurchaseBillingFieldDefinition(
          key: PurchaseBillingFieldKey.huid,
          label: 'HUID Number',
          description: 'BIS hallmark number for gold purchase verification.',
        ),
      );
    }

    fields.addAll(const [
      PurchaseBillingFieldDefinition(
        key: PurchaseBillingFieldKey.totalValue,
        label: 'Total Value',
        description: 'Final voucher amount for the item row.',
      ),
      PurchaseBillingFieldDefinition(
        key: PurchaseBillingFieldKey.supplierDetails,
        label: 'Supplier Details',
        description: 'Supplier identity and address on the voucher.',
      ),
      PurchaseBillingFieldDefinition(
        key: PurchaseBillingFieldKey.panNumber,
        label: 'PAN Number',
        description: 'Seller PAN details for compliance checks.',
      ),
      PurchaseBillingFieldDefinition(
        key: PurchaseBillingFieldKey.gstBreakup,
        label: 'GST Breakup',
        description: 'Separate GST details on purchase voucher.',
      ),
      PurchaseBillingFieldDefinition(
        key: PurchaseBillingFieldKey.hsnCode,
        label: 'HSN Code',
        description: 'HSN code for reporting and compliance.',
      ),
    ]);

    return fields;
  }

  static int activeFieldCount(PurchaseBillingModel model) {
    return fieldsFor(model.metal)
        .where((field) => valueFor(model, field.key))
        .length;
  }

  static bool valueFor(
    PurchaseBillingModel model,
    PurchaseBillingFieldKey key,
  ) {
    switch (key) {
      case PurchaseBillingFieldKey.grossWeight:
        return model.showGrossWeight;
      case PurchaseBillingFieldKey.lessWeight:
        return model.showLessWeight;
      case PurchaseBillingFieldKey.netWeight:
        return model.showNetWeight;
      case PurchaseBillingFieldKey.purity:
        return model.showPurity;
      case PurchaseBillingFieldKey.rate:
        return model.showRate;
      case PurchaseBillingFieldKey.fineWeight:
        return model.showFineWeight;
      case PurchaseBillingFieldKey.totalValue:
        return model.showTotalValue;
      case PurchaseBillingFieldKey.stoneDetails:
        return model.showStoneDetails;
      case PurchaseBillingFieldKey.stoneValue:
        return model.showStoneValue;
      case PurchaseBillingFieldKey.huid:
        return model.showHuid;
      case PurchaseBillingFieldKey.supplierDetails:
        return model.showSupplierDetails;
      case PurchaseBillingFieldKey.panNumber:
        return model.showPanNumber;
      case PurchaseBillingFieldKey.diamondCarats:
        return model.showDiamondCarats;
      case PurchaseBillingFieldKey.diamondClarity:
        return model.showDiamondClarity;
      case PurchaseBillingFieldKey.certificationNo:
        return model.showCertificationNo;
      case PurchaseBillingFieldKey.gstBreakup:
        return model.showGstBreakup;
      case PurchaseBillingFieldKey.hsnCode:
        return model.showHsnCode;
    }
  }

  static PurchaseBillingModel setValue(
    PurchaseBillingModel model,
    PurchaseBillingFieldKey key,
    bool value,
  ) {
    switch (key) {
      case PurchaseBillingFieldKey.grossWeight:
        return model.copyWith(showGrossWeight: value);
      case PurchaseBillingFieldKey.lessWeight:
        return model.copyWith(showLessWeight: value);
      case PurchaseBillingFieldKey.netWeight:
        return model.copyWith(showNetWeight: value);
      case PurchaseBillingFieldKey.purity:
        return model.copyWith(showPurity: value);
      case PurchaseBillingFieldKey.rate:
        return model.copyWith(showRate: value);
      case PurchaseBillingFieldKey.fineWeight:
        return model.copyWith(showFineWeight: value);
      case PurchaseBillingFieldKey.totalValue:
        return model.copyWith(showTotalValue: value);
      case PurchaseBillingFieldKey.stoneDetails:
        return model.copyWith(showStoneDetails: value);
      case PurchaseBillingFieldKey.stoneValue:
        return model.copyWith(showStoneValue: value);
      case PurchaseBillingFieldKey.huid:
        return model.copyWith(showHuid: value);
      case PurchaseBillingFieldKey.supplierDetails:
        return model.copyWith(showSupplierDetails: value);
      case PurchaseBillingFieldKey.panNumber:
        return model.copyWith(showPanNumber: value);
      case PurchaseBillingFieldKey.diamondCarats:
        return model.copyWith(showDiamondCarats: value);
      case PurchaseBillingFieldKey.diamondClarity:
        return model.copyWith(showDiamondClarity: value);
      case PurchaseBillingFieldKey.certificationNo:
        return model.copyWith(showCertificationNo: value);
      case PurchaseBillingFieldKey.gstBreakup:
        return model.copyWith(showGstBreakup: value);
      case PurchaseBillingFieldKey.hsnCode:
        return model.copyWith(showHsnCode: value);
    }
  }
}
