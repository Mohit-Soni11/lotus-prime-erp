// =============================================================================
// FILE        : quick_actions_logic.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : Logic (Business Logic)
// DESCRIPTION : Dashboard action definitions and interaction state.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../models/dashboard/quick_action_item_model.dart';
import '../../../models/dashboard/quick_action_popup_option.dart';
import '../../../constants/app_routes.dart';

// ==========================================
// MAIN LOGIC CLASS
// ==========================================
class QuickActionsLogic extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  String? _pressedId;
  String? _hoveredId;

  String? get pressedId => _pressedId;
  String? get hoveredId => _hoveredId;

  bool isPressed(String id) => _pressedId == id;
  bool isHovered(String id) => _hoveredId == id;

  // ==========================================
  // ACTION BUTTONS (2x2 grid)
  // New Entry and Collections open contextual popups.
  // ==========================================
  static const List<QuickActionItemModel> actions = [
    QuickActionItemModel(
      id: 'new_entry',
      label: 'New Entry',
      icon: Icons.add_circle_outline_rounded,
      routeId: '', // Handled via popup
      accentColor: Color(0xFFF59E0B), // Gold
      hasPopup: true,
    ),
    QuickActionItemModel(
      id: 'add_stock',
      label: 'Add Stock',
      icon: Icons.inventory_2_rounded,
      routeId: AppRoutes.addStockRoute,
      accentColor: Color(0xFF10B981), // Emerald
      hasPopup: false,
    ),
    QuickActionItemModel(
      id: 'collections',
      label: 'Collections',
      icon: Icons.tune_rounded,
      routeId: '', // Handled via popup
      accentColor: Color(0xFF6366F1), // Indigo
      hasPopup: true,
    ),
    QuickActionItemModel(
      id: 'account_book',
      label: 'Account Book',
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
      label: 'Customer Metal Purchase',
      subtitle: 'Buy and record old metal from a customer',
      icon: Icons.move_to_inbox_rounded,
      accentColor: Color(0xFF10B981),
      routeId: AppRoutes.purchaseEntryRoute,
    ),
    QuickActionPopupOption(
      id: 'new_pledge',
      label: 'New Pledge',
      subtitle: 'Create a pledge ticket and record the loan',
      icon: Icons.lock_rounded,
      accentColor: Color(0xFFEC4899),
      routeId: AppRoutes.newGirviRoute,
    ),
    QuickActionPopupOption(
      id: 'booking_advance',
      label: 'Booking & Advance',
      subtitle: 'Create a booking and record its advance',
      icon: Icons.event_available_rounded,
      accentColor: Color(0xFF6366F1),
      routeId: AppRoutes.bookingAdvanceRoute,
    ),
  ];

  // ==========================================
  // POPUP OPTIONS — 2 options for "Collections"
  // ==========================================
  static const List<QuickActionPopupOption> collectionOptions = [
    QuickActionPopupOption(
      id: 'due_collection',
      label: 'Due Collection',
      subtitle: 'Receive pending due payments from customers',
      icon: Icons.receipt_long_rounded,
      accentColor: Color(0xFF10B981),
      routeId: AppRoutes.dueCollectionRoute,
    ),
    QuickActionPopupOption(
      id: 'interest_entry',
      label: 'Interest Entry',
      subtitle: 'Collect interest for active collateral loans',
      icon: Icons.account_balance_rounded,
      accentColor: Color(0xFFF59E0B),
      routeId: AppRoutes.interestCalcRoute,
    ),
  ];

  // Retrieve popup options based on button ID
  List<QuickActionPopupOption> getPopupOptions(String buttonId) {
    if (buttonId == 'new_entry') return newEntryOptions;
    if (buttonId == 'collections') return collectionOptions;
    return [];
  }

  // Retrieve popup title based on button ID
  String getPopupTitle(String buttonId) {
    if (buttonId == 'new_entry') return 'Select an Action';
    if (buttonId == 'collections') return 'Select Collection Type';
    return '';
  }

  // ==========================================
  // INTERACTION HANDLERS
  // ==========================================
  void onButtonTapDown(String id) {
    _pressedId = id;
    notifyListeners();
  }

  void onDirectButtonTap(
    String id,
    Function(String routeId) onNavigate,
  ) {
    _pressedId = null;
    notifyListeners();
    final routeId =
        actions.where((action) => action.id == id).firstOrNull?.routeId;
    if (routeId != null && routeId.isNotEmpty) onNavigate(routeId);
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
}
