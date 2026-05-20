// =============================================================================
// FILE        : quick_actions_logic.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : Logic (Business Logic)
// DESCRIPTION : Complete business logic for the Quick Actions card.
//               ✅ UPDATE:
//               • "New Entry" button → Triggers 4-option popup
//                  (New Sale / Purchase Entry / Collateral / Advance)
//               • "Adjust" button   → Triggers 2-option popup
//                  (Due Adjust / Interest Adjustment)
//               Pattern: ChangeNotifier (Similar to ShopCardLogic)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

import '../../../models/dashboard/quick_action_item_model.dart';
import '../../../constants/app_routes.dart';

// ==========================================
// POPUP OPTION MODEL
// ==========================================
class QuickActionPopupOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String routeId;

  const QuickActionPopupOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.routeId,
  });
}

// ==========================================
// MAIN LOGIC CLASS
// ==========================================
class QuickActionsLogic extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  String? _pressedId;
  String? _hoveredId;
  bool _isProcessing = false;
  Timer? _pressTimer;

  String? get pressedId => _pressedId;
  String? get hoveredId => _hoveredId;
  bool get isProcessing => _isProcessing;

  bool isPressed(String id) => _pressedId == id;
  bool isHovered(String id) => _hoveredId == id;

  // ==========================================
  // ACTION BUTTONS (2x2 grid)
  // ✅ Button 1: "New Entry"  — popup
  // ✅ Button 3: "Adjust"     — popup
  // ==========================================
  static final List<QuickActionItemModel> actions = [
    const QuickActionItemModel(
      id: 'new_entry',
      label: 'New Entry',
      icon: Icons.add_circle_outline_rounded,
      routeId: '', // Handled via popup
      accentColor: Color(0xFFF59E0B), // Gold
      hasPopup: true,
    ),
    const QuickActionItemModel(
      id: 'add_stock',
      label: 'Add Stock',
      icon: Icons.inventory_2_rounded,
      routeId: AppRoutes.addStockRoute,
      accentColor: Color(0xFF10B981), // Emerald
      hasPopup: false,
    ),
    const QuickActionItemModel(
      id: 'adjust',
      label: 'Adjust',
      icon: Icons.tune_rounded,
      routeId: '', // Handled via popup
      accentColor: Color(0xFF6366F1), // Indigo
      hasPopup: true,
    ),
    const QuickActionItemModel(
      id: 'cash_book',
      label: 'Cash Book',
      icon: Icons.account_balance_wallet_rounded,
      routeId: AppRoutes.cashBookRoute,
      accentColor: Color(0xFFEC4899), // Pink
      hasPopup: false,
    ),
  ];

  // ==========================================
  // POPUP OPTIONS — 4 options for "New Entry"
  // ==========================================
  static const List<QuickActionPopupOption> newEntryOptions = [
    QuickActionPopupOption(
      id: 'new_sale',
      label: 'New Sale',
      subtitle: 'Create a new sales invoice for a customer',
      icon: Icons.shopping_cart_rounded,
      accentColor: Color(0xFFF59E0B),
      routeId: AppRoutes.newSaleRoute,
    ),
    QuickActionPopupOption(
      id: 'purchase_entry',
      label: 'Purchase Entry',
      subtitle: 'Record a new purchase from a supplier',
      icon: Icons.shopping_bag_rounded,
      accentColor: Color(0xFF10B981),
      routeId: AppRoutes.purchaseEntryRoute,
    ),
    QuickActionPopupOption(
      id: 'girvi_entry',
      label: 'Collateral / Loan',
      subtitle: 'Create a new collateral loan entry',
      icon: Icons.lock_rounded,
      accentColor: Color(0xFFEC4899),
      routeId: AppRoutes.newGirviRoute,
    ),
    QuickActionPopupOption(
      id: 'advance_entry',
      label: 'Booking Advance',
      subtitle: 'Record an advance payment for an order',
      icon: Icons.event_available_rounded,
      accentColor: Color(0xFF6366F1),
      routeId: AppRoutes.bookingAdvanceRoute,
    ),
  ];

  // ==========================================
  // POPUP OPTIONS — 2 options for "Adjust"
  // ==========================================
  static const List<QuickActionPopupOption> adjustOptions = [
    QuickActionPopupOption(
      id: 'due_adjust',
      label: 'Due Adjust',
      subtitle: 'Receive pending due payments from customers',
      icon: Icons.receipt_long_rounded,
      accentColor: Color(0xFF10B981),
      routeId: AppRoutes.defaulterListRoute,
    ),
    QuickActionPopupOption(
      id: 'girvi_interest',
      label: 'Interest Payment',
      subtitle: 'Collect interest for active collateral loans',
      icon: Icons.account_balance_rounded,
      accentColor: Color(0xFFF59E0B),
      routeId: AppRoutes.interestCalcRoute,
    ),
  ];

  // Retrieve popup options based on button ID
  List<QuickActionPopupOption> getPopupOptions(String buttonId) {
    if (buttonId == 'new_entry') return newEntryOptions;
    if (buttonId == 'adjust') return adjustOptions;
    return [];
  }

  // Retrieve popup title based on button ID
  String getPopupTitle(String buttonId) {
    if (buttonId == 'new_entry') return 'Select an Action';
    if (buttonId == 'adjust') return 'Select Adjustment Type';
    return '';
  }

  // ==========================================
  // INTERACTION HANDLERS
  // ==========================================
  void onButtonTapDown(String id) {
    if (_isProcessing) return;
    _pressedId = id;
    notifyListeners();
  }

  Future<void> onDirectButtonTapUp(
    String id,
    Function(String routeId) onNavigate,
  ) async {
    if (_isProcessing) return;
    _isProcessing = true;

    await Future.delayed(const Duration(milliseconds: 120));
    _pressedId = null;
    notifyListeners();

    final item = actions.firstWhere((a) => a.id == id);
    if (item.routeId.isNotEmpty) {
      onNavigate(item.routeId);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _isProcessing = false;
  }

  void onButtonTapCancel() {
    _pressedId = null;
    notifyListeners();
  }

  void onHoverEnter(String id) {
    if (_hoveredId == id) return;
    _hoveredId = id;
    notifyListeners();
  }

  void onHoverExit() {
    _hoveredId = null;
    notifyListeners();
  }

  // ==========================================
  // CLEANUP
  // ==========================================
  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }
}
