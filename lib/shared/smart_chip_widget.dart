// =============================================================================
// FILE        : smart_chip_widget.dart
// MODULE      : Shared → Smart Input → UI → Widgets
// LAYER       : UI (Presentational only)
// PURPOSE     : Single suggestion chip button (Hindi transliteration / item / city)
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_field_type.dart';
//import 'smart_input_colors.dart';
import 'smart_input_styles.dart';

class SmartChipWidget extends StatelessWidget {
  const SmartChipWidget({
    super.key,
    required this.label,
    required this.fieldType,
    required this.onTap,
  });

  final String label;
  final SmartFieldType fieldType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: SmartInputStyles.chipDecoration,
        child: Text(
          label,
          style: SmartInputStyles.chipTextStyle(fieldType),
        ),
      ),
    );
  }
}
