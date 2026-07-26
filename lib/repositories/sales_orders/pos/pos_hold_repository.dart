// ==========================================
// FILE: pos_hold_repository.dart
// TYPE: Repository
// DESCRIPTION: Persists parked POS bills locally so they survive screen exits
//              and app restarts.
// ==========================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/sales_orders/sales_pos_models/pos_hold_bill_model.dart';

class PosHoldRepository {
  static const String _storageKey = 'lotus_pos_held_bills_v1';

  Future<List<PosHoldBillModel>> loadHeldBills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PosHoldBillModel.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHeldBills(List<PosHoldBillModel> heldBills) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      heldBills.map((bill) => bill.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey, payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

