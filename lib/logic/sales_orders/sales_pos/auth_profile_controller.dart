// ==========================================
// FILE: auth_profile_controller.dart
// TYPE: Master Logic (Separated from UI)
// AUTHOR: Senior System Architect
// DESCRIPTION: Handles logged-in user state, dynamic shop info, and role logic.
//               Strictly English comments.
//               Ready for API/Database injection.
// ==========================================

import 'package:flutter/material.dart';

// NOTE: Ensure this path correctly points to your enums file
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class AuthProfileController extends ChangeNotifier {
  // --- DYNAMIC DATABASE MOCK VALUES ---
  // These variables will be updated from the Settings/Auth API in the future
  String displayShopName = "Lotus Jewellers";
  String shopCity = "Patna";

  String loggedInUserName = "System Admin";
  UserRole currentUserRole = UserRole.owner;

  // --- ROLE BASED COLOR LOGIC ---
  Color get roleColor {
    switch (currentUserRole) {
      case UserRole.owner:
        return SalesPosColors.brandGold;
      case UserRole.manager:
        return Colors.blueAccent;
      case UserRole.cashier:
        return SalesPosColors.success;
      case UserRole.staff:
        return SalesPosColors.brandSilver;
    }
  }

  // --- GLOW LOGIC ---
  // Only the owner gets the premium golden shadow effect
  bool get hasGoldenGlow => currentUserRole == UserRole.owner;

  // Clean display name for the UI header
  String get displayRoleName => currentUserRole.name.toUpperCase();

  // ==========================================
  // FUTURE API INTEGRATION METHODS
  // ==========================================

  /// Call this method when the user logs in or switches profiles
  void updateUserProfile({
    required String newUserName,
    required UserRole newRole,
    String? newShopName,
    String? newShopCity,
  }) {
    loggedInUserName = newUserName;
    currentUserRole = newRole;

    if (newShopName != null) displayShopName = newShopName;
    if (newShopCity != null) shopCity = newShopCity;

    // This will instantly update the POS Master Header without rebuilding the whole screen
    notifyListeners();
  }
}
