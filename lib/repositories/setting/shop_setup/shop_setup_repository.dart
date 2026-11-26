// -----------------------------------------------------------------------------
// FILE: shop_setup_repository.dart
// TYPE: Repository / Data Access Layer
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: Permanent Tenant ID integrated via Session Manager.
//              Prevents duplicate store creations and ensures Upsert logic.
// -----------------------------------------------------------------------------

// --- MODEL IMPORTS ---
import '../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../models/setting/shop_setup/tabs/tax_gst_model.dart';
import '../../../models/setting/shop_setup/tabs/bank_account_model.dart';
import '../../../models/setting/shop_setup/tabs/shop_branding_model.dart';
import '../../../models/setting/shop_setup/tabs/shop_master_payload_model.dart';
import '../../../models/setting/shop_setup/shop_setup_save_result.dart';

// --- DATABASE HELPER IMPORT ---
import '../../../database/local_database/shop_database_helper.dart';

// ✅ DRIFT DB — Dashboard ShopCard ke liye sync
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:drift/drift.dart';

import 'shop_session_manager.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/events/shop_identity_updates.dart';

class ShopSetupRepository {
  final ShopDatabaseHelper _dbHelper = ShopDatabaseHelper();

  // ✅ Drift DB instance — Dashboard ke liye
  final AppDatabase _driftDb = AppDatabase();

  /// Commits the local Shop Profile source of truth first, then refreshes the
  /// operational projections used by legacy finance/reporting consumers.
  Future<ShopSetupSaveResult> submitMasterPayload({
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
      AppLogger.debug(
          "🚀 [SHOP SETUP] SECURE MASTER PAYLOAD ROUTED TO DB WITH PERMANENT ID: $tenantId");

      // The isolated profile database is authoritative and transactional.
      final bool isSaved =
          await _dbHelper.upsertMasterPayload(masterPayloadMap);
      if (!isSaved) return const ShopSetupSaveResult(isPersisted: false);

      ShopIdentityUpdates.instance.publish();
      final warnings = <String>[];

      final isProfileSynced = await _syncToDriftShopProfiles(
        basicInfo: basicInfo,
        addressData: addressData,
        taxGst: taxGst,
        banking: bankingList,
      );
      if (!isProfileSynced) {
        warnings.add('Reporting profile synchronization is pending.');
      }

      warnings.addAll(
        await _syncBankingToFinanceAccounts(
          tenantId: tenantId,
          banking: bankingList,
        ),
      );
      return ShopSetupSaveResult(
        isPersisted: true,
        syncWarnings: List.unmodifiable(warnings),
      );
    } catch (e, stacktrace) {
      AppLogger.error("❌ [SHOP SETUP] REPOSITORY ERROR: $e");
      AppLogger.debug(stacktrace.toString());
      return const ShopSetupSaveResult(isPersisted: false);
    }
  }

  /// Only manages Bank Book records explicitly linked to Shop Profile.
  /// Financial history (opening balance and activation date) is never changed
  /// by identity/settings edits.
  Future<List<String>> _syncBankingToFinanceAccounts({
    required String tenantId,
    required List<BankAccountModel> banking,
  }) async {
    try {
      final validAccounts = banking.where((bank) {
        return bank.acc.trim().isNotEmpty || bank.upi.trim().isNotEmpty;
      }).toList();
      final persistedLinks =
          await _dbHelper.financeAccountLinksForTenant(tenantId);
      final nextLinks = <String, int>{};
      final warnings = <String>[];
      final activeFinanceIds = <int>[];

      await _driftDb.transaction(() async {
        for (final bank in validAccounts) {
          final accountNumber = _financeAccountNumberFor(bank);
          if (accountNumber.isEmpty) continue;

          final linkedId = persistedLinks[bank.id];
          final linkedAccount = linkedId == null
              ? null
              : await (_driftDb.select(_driftDb.bankAccounts)
                    ..where((table) => table.id.equals(linkedId))
                    ..limit(1))
                  .getSingleOrNull();

          if (linkedAccount != null) {
            await (_driftDb.update(_driftDb.bankAccounts)
                  ..where((table) => table.id.equals(linkedAccount.id)))
                .write(_financeIdentityCompanion(bank, accountNumber));
            nextLinks[bank.id] = linkedAccount.id;
            activeFinanceIds.add(linkedAccount.id);
            continue;
          }

          final conflictingAccount = await (_driftDb
                  .select(_driftDb.bankAccounts)
                ..where((table) => table.accountNumber.equals(accountNumber))
                ..limit(1))
              .getSingleOrNull();
          if (conflictingAccount != null) {
            warnings.add(
              'Bank account ${_maskedAccount(accountNumber)} already belongs to Bank Book and was left unchanged.',
            );
            continue;
          }

          final createdId = await _driftDb.into(_driftDb.bankAccounts).insert(
                BankAccountsCompanion.insert(
                  accountName: _accountTitle(bank, activeFinanceIds.length),
                  bankName:
                      bank.bank.trim().isEmpty ? 'Bank' : bank.bank.trim(),
                  accountNumber: accountNumber,
                  holderName: Value(_nullable(bank.holder)),
                  ifscCode: Value(_nullable(bank.ifsc)?.toUpperCase()),
                  branchName: Value(_nullable(bank.branch)),
                  accountType: Value(_financeAccountType(bank.type)),
                  upiId: Value(_nullable(bank.upi)),
                ),
              );
          nextLinks[bank.id] = createdId;
          activeFinanceIds.add(createdId);
        }

        final previouslyLinkedIds = persistedLinks.values.toSet();
        final removedIds =
            previouslyLinkedIds.difference(activeFinanceIds.toSet());
        if (removedIds.isNotEmpty) {
          await (_driftDb.update(_driftDb.bankAccounts)
                ..where((table) => table.id.isIn(removedIds)))
              .write(const BankAccountsCompanion(
            isActive: Value(false),
            isPrimary: Value(false),
          ));
        }
        if (activeFinanceIds.isNotEmpty) {
          await (_driftDb.update(_driftDb.bankAccounts)
                ..where((table) => table.id.isIn(activeFinanceIds)))
              .write(const BankAccountsCompanion(isPrimary: Value(false)));
          await (_driftDb.update(_driftDb.bankAccounts)
                ..where((table) => table.id.equals(activeFinanceIds.first)))
              .write(const BankAccountsCompanion(
            isActive: Value(true),
            isPrimary: Value(true),
          ));
        }
      });

      await _dbHelper.replaceFinanceAccountLinks(
        tenantId: tenantId,
        links: nextLinks,
      );
      return warnings;
    } catch (e) {
      AppLogger.warning('Shop Profile banking projection pending: $e');
      return const [
        'Bank Book synchronization is pending and will not alter existing balances.'
      ];
    }
  }

  BankAccountsCompanion _financeIdentityCompanion(
    BankAccountModel bank,
    String accountNumber,
  ) =>
      BankAccountsCompanion(
        accountName: Value(_accountTitle(bank, 0)),
        holderName: Value(_nullable(bank.holder)),
        bankName: Value(bank.bank.trim().isEmpty ? 'Bank' : bank.bank.trim()),
        accountNumber: Value(accountNumber),
        ifscCode: Value(_nullable(bank.ifsc)?.toUpperCase()),
        branchName: Value(_nullable(bank.branch)),
        accountType: Value(_financeAccountType(bank.type)),
        upiId: Value(_nullable(bank.upi)),
        isActive: const Value(true),
      );

  String _accountTitle(BankAccountModel bank, int index) =>
      bank.title.trim().isEmpty
          ? (index == 0
              ? 'Primary Operating Account'
              : 'Additional Account ${index + 1}')
          : bank.title.trim();

  String _maskedAccount(String accountNumber) {
    if (accountNumber.startsWith('UPI:')) return 'UPI account';
    if (accountNumber.length <= 4) return '••••';
    return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
  }

  String _financeAccountNumberFor(BankAccountModel bank) {
    final acc = bank.acc.trim();
    if (acc.isNotEmpty) return acc;
    final upi = bank.upi.trim();
    if (upi.isNotEmpty) return 'UPI:$upi';
    return '';
  }

  String _financeAccountType(dynamic type) {
    final value = type.toString().toLowerCase();
    if (value.contains('saving')) return 'SAVINGS';
    if (value.contains('od') || value.contains('cc')) return 'OD';
    return 'CURRENT';
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  // ==========================================
  // ✅ DRIFT SYNC — Settings → Dashboard
  // ShopProfileModel (settings) ka data
  // Drift ShopProfiles table mein upsert karo
  // ==========================================
  Future<bool> _syncToDriftShopProfiles({
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
        email: Value(basicInfo.businessEmail),
        contactNumber: Value(basicInfo.shopPhone),
        whatsappNumber: Value(basicInfo.shopWhatsapp),
        logoPath: Value(basicInfo.logoPath),
        logoShape: Value(basicInfo.logoShape),
        signaturePath: Value(basicInfo.signaturePath),
        signatureShape: Value(basicInfo.signatureShape),
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
      );

      final existing = await (_driftDb.select(_driftDb.shopProfiles)
            ..orderBy([(table) => OrderingTerm.asc(table.id)])
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        // Update
        await (_driftDb.update(_driftDb.shopProfiles)
              ..where((t) => t.id.equals(existing.id)))
            .write(companion);
        AppLogger.debug(
            '✅ [DRIFT SYNC] ShopProfiles updated (id: ${existing.id})');
      } else {
        // Insert
        await _driftDb.into(_driftDb.shopProfiles).insert(companion);
        AppLogger.debug('✅ [DRIFT SYNC] ShopProfiles inserted.');
      }
      return true;
    } catch (e) {
      // Sync fail hone par crash mat karo — sirf log karo
      AppLogger.debug('⚠️ [DRIFT SYNC] Failed (non-critical): $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchExistingSetup(String tenantId) async {
    try {
      return await _dbHelper.getMasterPayload(tenantId);
    } catch (e) {
      AppLogger.error("❌ [SHOP SETUP] FAILED TO FETCH DATA: $e");
      return null;
    }
  }
}
