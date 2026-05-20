// -----------------------------------------------------------------------------
// FILE: address_logic.dart
// TYPE: Business Logic / ViewModel
// AUTHOR: Senior Enterprise Architect
// DESCRIPTION: 🚀 UPGRADED: Pure Form Logic, 100% decoupled from UI and Map.
//              Optimized strictly with ValueNotifiers for granular rebuilds.
//              FocusNodes and Controllers successfully removed.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

class AddressFormLogic {
  // --- 🚀 UPGRADE: GRANULAR STATE NOTIFIERS ---
  final ValueNotifier<bool> isAddressLocked = ValueNotifier(true);
  final ValueNotifier<bool> isSaving = ValueNotifier(false);
  final ValueNotifier<String> selectedAddressType =
      ValueNotifier("Head Office");

  // --- ACTIONS ---

  void unlockAddress() {
    isAddressLocked.value = false;
  }

  void updateAddressType(String type) {
    if (selectedAddressType.value != type) {
      selectedAddressType.value = type;
    }
  }

  // --- 🚀 UPGRADE: PURE VALIDATION (Returns String Keys, not FocusNodes) ---
  List<String> validateAddress({
    required String addr1,
    required String addr2,
    required String city,
    required String state,
    required String pin,
  }) {
    List<String> errors = [];
    if (addr1.trim().isEmpty) errors.add('keyAddr1');
    if (addr2.trim().isEmpty) errors.add('keyAddr2');
    if (city.trim().isEmpty) errors.add('keyCity');
    if (state.trim().isEmpty) errors.add('keyState');
    if (pin.trim().length != 6) errors.add('keyPin');
    return errors;
  }

  // --- ASYNC SAVE LOGIC ---
  Future<bool> saveAddress(List<String> errors) async {
    if (errors.isNotEmpty) {
      return false;
    }

    isSaving.value = true;

    // Fast Micro-Interaction (Simulated API Call)
    await Future.delayed(const Duration(milliseconds: 300));

    isSaving.value = false;
    isAddressLocked.value = true;
    return true;
  }

  // --- MEMORY MANAGEMENT ---
  void dispose() {
    isAddressLocked.dispose();
    isSaving.dispose();
    selectedAddressType.dispose();
  }
}
