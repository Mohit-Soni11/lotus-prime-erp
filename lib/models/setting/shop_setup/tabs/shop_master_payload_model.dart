// -----------------------------------------------------------------------------
// FILE: shop_master_payload_model.dart
// TYPE: Master Data Model wrapper
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 NEW: Replaces weak Map<String, dynamic> with strict typing.
// -----------------------------------------------------------------------------

import '../shop_profile_model.dart';
import '../tabs/tax_gst_model.dart';
import '../tabs/bank_account_model.dart';
import '../tabs/shop_branding_model.dart';
import 'package:flutter/foundation.dart';

@immutable
class ShopMasterPayloadModel {
  final String tenantId;
  final ShopProfileModel basicInfo;
  final Map<String, dynamic> addressData; // Updatable to ShopAddressModel later
  final TaxGstModel taxGst;
  final List<BankAccountModel> bankingList;
  final ShopBrandingModel branding;

  const ShopMasterPayloadModel({
    required this.tenantId,
    required this.basicInfo,
    required this.addressData,
    required this.taxGst,
    required this.bankingList,
    required this.branding,
  });

  Map<String, dynamic> toJson() {
    return {
      "tenant_id": tenantId,
      "basic_info": basicInfo.toJson(),
      "address": addressData,
      "tax_compliance": taxGst.toJson(),
      "banking_details": bankingList.map((bank) => bank.toJson()).toList(),
      "branding_social": branding.toJson(),
      "system_metadata": {
        "created_at": DateTime.now().toUtc().toIso8601String(),
        "setup_version": "1.0.0",
        "device_platform": defaultTargetPlatform.name,
      }
    };
  }
}