// =============================================================================
// FILE        : quick_action_item_model.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : Models
// DESCRIPTION : Contains complete data for a quick action button.
//               hasPopup: true  → Triggers a dropdown popup on click
//               hasPopup: false → Triggers direct navigation
// =============================================================================

import 'package:flutter/material.dart';

class QuickActionItemModel {
  final String id;
  final String label;
  final IconData icon;
  final String routeId;
  final Color accentColor;
  final bool
      hasPopup; // ✅ Indicates if the button triggers a popup or direct navigation

  const QuickActionItemModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.routeId,
    required this.accentColor,
    this.hasPopup = false,
  });
}
