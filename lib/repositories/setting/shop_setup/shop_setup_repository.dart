// -----------------------------------------------------------------------------
// FILE: shop_setup_repository.dart
// TYPE: Repository / Data Access Layer
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: Permanent Tenant ID integrated via Session Manager.
//              Prevents duplicate store creations and ensures Upsert logic.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'dart:convert';

// --- MODEL IMPORTS ---
import '../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../models/setting/shop_setup/tabs/tax_gst_model.dart';
import '../../../models/setting/shop_setup/tabs/bank_account_model.dart';
import '../../../models/setting/shop_setup/tabs/shop_branding_model.dart';
import '../../../models/setting/shop_setup/tabs/shop_master_payload_model.dart';

// --- DATABASE HELPER IMPORT ---
import '../../../database/local_database/shop_database_helper.dart';

// ✅ DRIFT DB — Dashboard ShopCard ke liye sync
import '../../../database/db/app_database.dart';
import 'package:drift/drift.dart';

import 'shop_session_manager.dart';

class ShopSetupRepository {
  final ShopDatabaseHelper _dbHelper = ShopDatabaseHelper();

  // ✅ Drift DB instance — Dashboard ke liye
  final AppDatabase _driftDb = AppDatabase();

  /// Master method to construct and push the final payload securely.
  Future<bool> submitMasterPayload({
    required ShopProfileModel basicInfo,
    required Map<String, dynamic> addressData,
    required TaxGstModel taxGst,
    required List<BankAccountModel> bankingList,
    required ShopBrandingModel branding,
  }) async {
    try {
      final String tenantId = await ShopSessionManager.getPermanentTenantId();

      final masterModel = ShopMasterPayloadModel(
        tenantId: tenantId,
        basicInfo: basicInfo,
        addressData: addressData,
        taxGst: taxGst,
        bankingList: bankingList,
        branding: branding,
      );

      final masterPayloadMap = masterModel.toJson();
      final String prettyJson =
          const JsonEncoder.withIndent('  ').convert(masterPayloadMap);
      debugPrint(
          "🚀 [SHOP SETUP] SECURE MASTER PAYLOAD ROUTED TO DB WITH PERMANENT ID: $tenantId");
      debugPrint(prettyJson);

      // 1. Existing local DB mein save karo (unchanged)
      final bool isSaved =
          await _dbHelper.upsertMasterPayload(masterPayloadMap);

      // ✅ 2. Drift ShopProfiles table mein bhi sync karo
      // Dashboard ShopCard yahan se padhta hai
      if (isSaved) {
        await _syncToDriftShopProfiles(
          basicInfo: basicInfo,
          addressData: addressData,
          taxGst: taxGst,
          banking: bankingList,
        );
      }

      return isSaved;
    } catch (e, stacktrace) {
      debugPrint("❌ [SHOP SETUP] REPOSITORY ERROR: $e");
      debugPrint(stacktrace.toString());
      return false;
    }
  }

  // ==========================================
  // ✅ DRIFT SYNC — Settings → Dashboard
  // ShopProfileModel (settings) ka data
  // Drift ShopProfiles table mein upsert karo
  // ==========================================
  Future<void> _syncToDriftShopProfiles({
    required ShopProfileModel basicInfo,
    required Map<String, dynamic> addressData,
    required TaxGstModel taxGst,
    required List<BankAccountModel> banking,
  }) async {
    try {
      // Address data extract karo
      final String city = addressData['city']?.toString() ?? '';
      final String state = addressData['state']?.toString() ?? '';
      final String pincode = addressData['pincode']?.toString() ?? '';
      final String address = addressData['addr1']?.toString() ?? '';

      // Banking (first account) — BankAccountModel fields: acc, bank, holder, upi, ifsc
      String bankName = '';
      String bankAccNo = '';
      String bankIfsc = '';
      String upiId = '';
      String bankHolder = '';
      if (banking.isNotEmpty) {
        bankName = banking.first.bank; // ✅ .bank (not .bankName)
        bankAccNo = banking.first.acc; // ✅ .acc (not .accountNumber)
        bankIfsc = banking.first.ifsc; // ✅ .ifsc (not .ifscCode)
        upiId = banking.first.upi; // ✅ .upi (not .upiId)
        bankHolder = banking.first.holder; // ✅ .holder (not .holderName)
      }

      // Companion banao — sirf woh fields jo fill karne hain
      final companion = ShopProfilesCompanion(
        shopName: Value(basicInfo.brandDisplayName.isNotEmpty
            ? basicInfo.brandDisplayName
            : basicInfo.displayName),
        legalName: Value(basicInfo.legalName),
        tagline: Value(basicInfo.tagline),
        ownerName: Value(basicInfo.ownerName),
        ownerContact: Value(basicInfo.ownerPhone),
        ownerWhatsapp: Value(basicInfo.ownerWhatsapp),
        estYear: Value(basicInfo.estYear),
        branchCode: Value(basicInfo.branchCode),
        openingTime: Value(basicInfo.openTime),
        closingTime: Value(basicInfo.closeTime),
        weeklyOff: Value(basicInfo.weeklyOff),
        email: Value(basicInfo.businessEmail),
        contactNumber: Value(basicInfo.shopPhone),
        whatsappNumber: Value(basicInfo.shopWhatsapp),
        address: Value(address),
        city: Value(city),
        state: Value(state),
        pincode: Value(pincode),
        gstin: Value(taxGst.gstin),
        bisLicense: Value(taxGst.bisLicenseNo),
        bankName: Value(bankName),
        bankAccNo: Value(bankAccNo),
        bankIfsc: Value(bankIfsc),
        upiId: Value(upiId),
        bankHolderName: Value(bankHolder),
        showMobile: const Value(true),
        showEmail: const Value(true),
        showGst: const Value(true),
      );

      // Existing check karo
      final existing = await (_driftDb.select(_driftDb.shopProfiles)..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        // Update
        await (_driftDb.update(_driftDb.shopProfiles)
              ..where((t) => t.id.equals(existing.id)))
            .write(companion);
        debugPrint('✅ [DRIFT SYNC] ShopProfiles updated (id: ${existing.id})');
      } else {
        // Insert
        await _driftDb.into(_driftDb.shopProfiles).insert(companion);
        debugPrint('✅ [DRIFT SYNC] ShopProfiles inserted.');
      }
    } catch (e) {
      // Sync fail hone par crash mat karo — sirf log karo
      debugPrint('⚠️ [DRIFT SYNC] Failed (non-critical): $e');
    }
  }

  Future<Map<String, dynamic>?> fetchExistingSetup(String tenantId) async {
    try {
      return await _dbHelper.getMasterPayload(tenantId);
    } catch (e) {
      debugPrint("❌ [SHOP SETUP] FAILED TO FETCH DATA: $e");
      return null;
    }
  }
}
