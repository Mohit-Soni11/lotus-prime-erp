// =============================================================================
// FILE        : lib/models/setting/billing/purchase_billing_model.dart
// MODULE      : Billing Setup → Purchase
// =============================================================================

import 'sales_billing_model.dart';

class PurchaseBillingModel {
  final String metal;

  // Section 1 — Purchase Voucher Display
  final bool showGrossWeight;
  final bool showLessWeight;
  final bool showNetWeight;
  final bool showPurity;
  final bool showRate;
  final bool showFineWeight;
  final bool showTotalValue;
  final bool showStoneDetails;
  final bool showStoneValue;
  final bool showHuid;
  final bool showSupplierDetails;
  final bool showPanNumber;
  final bool showDiamondCarats;
  final bool showDiamondClarity;
  final bool showCertificationNo;
  final bool showGstBreakup;
  final bool showHsnCode;

  // Section 2 — Purchase Return Policy
  final int returnWindowDays;
  final String returnMode;
  final double purityDeductPercent;

  // Section 3 — Terms
  final String termsAndConditions;
  final String footerMessage;

  // Section 4 — Template
  final String selectedTemplate;

  const PurchaseBillingModel({
    required this.metal,
    this.showGrossWeight = true,
    this.showLessWeight = true,
    this.showNetWeight = true,
    this.showPurity = true,
    this.showRate = true,
    this.showFineWeight = true,
    this.showTotalValue = true,
    this.showStoneDetails = false,
    this.showStoneValue = false,
    this.showHuid = false,
    this.showSupplierDetails = true,
    this.showPanNumber = true,
    this.showDiamondCarats = true,
    this.showDiamondClarity = true,
    this.showCertificationNo = false,
    this.showGstBreakup = false,
    this.showHsnCode = false,
    this.returnWindowDays = 3,
    this.returnMode = 'Credit Note',
    this.purityDeductPercent = 2.0,
    this.termsAndConditions = 'Quality will be checked on delivery.\n'
        'Short delivery or defective goods must be reported within 24 hours.\n'
        'Payment as per agreed terms only.',
    this.footerMessage = '',
    this.selectedTemplate = 'default',
  });

  factory PurchaseBillingModel.defaultFor(String metal) {
    switch (metal) {
      case BillingMetal.gold:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: true,
          showSupplierDetails: true,
          showPanNumber: true,
          showGstBreakup: false,
          returnWindowDays: 3,
          returnMode: 'Credit Note',
          purityDeductPercent: 2.0,
          termsAndConditions:
              'Gold quality will be verified by hallmarking/testing.\n'
              'HUID required for all gold purchases above 20g.\n'
              'Defective goods must be reported within 24 hours of delivery.\n'
              'Payment as per agreed terms only.',
        );

      case BillingMetal.silver:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: false,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: false,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 3,
          returnMode: 'Credit Note',
          purityDeductPercent: 3.0,
          termsAndConditions:
              'Silver quality will be verified by purity testing.\n'
              'Short delivery must be reported within 24 hours.\n'
              'Payment as per agreed terms only.',
        );

      case BillingMetal.diamond:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: false,
          showLessWeight: false,
          showNetWeight: false,
          showPurity: false,
          showRate: true,
          showFineWeight: false,
          showTotalValue: true,
          showStoneDetails: true,
          showStoneValue: true,
          showDiamondCarats: true,
          showDiamondClarity: true,
          showCertificationNo: true,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 0,
          returnMode: 'Exchange',
          purityDeductPercent: 5.0,
          termsAndConditions: 'Diamond quality as per certificate provided.\n'
              'Certificate is mandatory for all diamond purchases.\n'
              'Any discrepancy to be reported within 24 hours.\n'
              'Payment as per agreed terms only.',
        );

      case BillingMetal.platinum:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: false,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 3,
          returnMode: 'Credit Note',
          purityDeductPercent: 2.0,
          termsAndConditions:
              'Platinum quality will be verified by purity testing.\n'
              'Defective goods must be reported within 24 hours.\n'
              'Payment as per agreed terms only.',
        );

      default:
        return PurchaseBillingModel(metal: metal);
    }
  }

  PurchaseBillingModel copyWith({
    bool? showGrossWeight,
    bool? showLessWeight,
    bool? showNetWeight,
    bool? showPurity,
    bool? showRate,
    bool? showFineWeight,
    bool? showTotalValue,
    bool? showStoneDetails,
    bool? showStoneValue,
    bool? showHuid,
    bool? showSupplierDetails,
    bool? showPanNumber,
    bool? showDiamondCarats,
    bool? showDiamondClarity,
    bool? showCertificationNo,
    bool? showGstBreakup,
    bool? showHsnCode,
    int? returnWindowDays,
    String? returnMode,
    double? purityDeductPercent,
    String? termsAndConditions,
    String? footerMessage,
    String? selectedTemplate,
  }) {
    return PurchaseBillingModel(
      metal: metal,
      showGrossWeight: showGrossWeight ?? this.showGrossWeight,
      showLessWeight: showLessWeight ?? this.showLessWeight,
      showNetWeight: showNetWeight ?? this.showNetWeight,
      showPurity: showPurity ?? this.showPurity,
      showRate: showRate ?? this.showRate,
      showFineWeight: showFineWeight ?? this.showFineWeight,
      showTotalValue: showTotalValue ?? this.showTotalValue,
      showStoneDetails: showStoneDetails ?? this.showStoneDetails,
      showStoneValue: showStoneValue ?? this.showStoneValue,
      showHuid: showHuid ?? this.showHuid,
      showSupplierDetails: showSupplierDetails ?? this.showSupplierDetails,
      showPanNumber: showPanNumber ?? this.showPanNumber,
      showDiamondCarats: showDiamondCarats ?? this.showDiamondCarats,
      showDiamondClarity: showDiamondClarity ?? this.showDiamondClarity,
      showCertificationNo: showCertificationNo ?? this.showCertificationNo,
      showGstBreakup: showGstBreakup ?? this.showGstBreakup,
      showHsnCode: showHsnCode ?? this.showHsnCode,
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      returnMode: returnMode ?? this.returnMode,
      purityDeductPercent: purityDeductPercent ?? this.purityDeductPercent,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerMessage: footerMessage ?? this.footerMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}
