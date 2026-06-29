// -----------------------------------------------------------------------------
// FILE: banking_logic.dart
// TYPE: Business Logic / Master Controller
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: 100% Decoupled from UI. BuildContext and feedback overlays
//              removed. Zero-lag State Management using ValueNotifier.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// --- IMPORTING UPGRADED FOUNDATION ---
// NOTE: Adjust the import paths according to your actual folder structure.
import '../../../../../models/setting/shop_setup/tabs/bank_account_model.dart';
import '../../../../../models/setting/shop_setup/enums/banking_enums.dart';
import '../../../../../logic/setting/shop_setup/tabs/tax_gst/document_crop_logic.dart';
import '../../../../../core/logging/app_logger.dart';

class BankingLogic {
  // 🚀 UPGRADE: Single shared instance of crop logic (Memory Safe)
  final DocumentCropLogic cropLogic = DocumentCropLogic();

  // 🚀 UPGRADE: Replaced ChangeNotifier with ValueNotifier for granular rebuilds
  final ValueNotifier<List<BankAccountModel>> accountsNotifier;

  BankingLogic()
      : accountsNotifier = ValueNotifier<List<BankAccountModel>>([
          const BankAccountModel(
            id: "primary_1",
            title: "Primary Operating Account",
            type: BankAccountType.current,
          )
        ]);

  void addNewAccount() {
    final currentList = List<BankAccountModel>.from(accountsNotifier.value);
    currentList.add(BankAccountModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Additional Account ${currentList.length + 1}",
      type: BankAccountType.savings,
    ));
    // Overriding the reference triggers ValueNotifier listener
    accountsNotifier.value = currentList;
  }

  void removeAccount(String id) {
    final currentList = List<BankAccountModel>.from(accountsNotifier.value);

    try {
      final accountToRemove = currentList.firstWhere((acc) => acc.id == id);

      // 🚀 UPGRADE: Hard Memory Cleanup
      // Deletes the physical QR image file from storage if the account is removed
      if (accountToRemove.qrImagePath != null &&
          accountToRemove.qrImagePath!.isNotEmpty) {
        cropLogic.clearCache(File(accountToRemove.qrImagePath!));
      }
    } catch (e) {
      AppLogger.debug("Account ID not found for deletion: $e");
    }

    currentList.removeWhere((acc) => acc.id == id);
    accountsNotifier.value = currentList;
  }

  // 🚀 UPGRADE: Update by ID (Crash Preventer)
  // Replaced index-based update with ID-based update for thread safety
  void updateAccountData(String id, BankAccountModel updatedAccount) {
    final currentList = List<BankAccountModel>.from(accountsNotifier.value);
    final index = currentList.indexWhere((acc) => acc.id == id);

    if (index != -1) {
      currentList[index] = updatedAccount;
      accountsNotifier.value = currentList;
      // The Deep Equality (==) inside BankAccountModel ensures that
      // unchanged UI cards will completely ignore this update and NOT rebuild.
    }
  }

  // --- 🚀 UPGRADE: PURE LOGIC (No BuildContext / UI Elements) ---
  Future<bool> copyToClipboard(String text) async {
    if (text.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: text));
    return true; // Return true on success. UI will catch this and show the feedback overlay!
  }

  // 🚀 UPGRADE: Strict Memory Disposal
  void dispose() {
    accountsNotifier.dispose();
  }
}
