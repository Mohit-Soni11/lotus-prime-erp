// =============================================================================
// FILE        : smart_spell_tile.dart
// MODULE      : Shared → Smart Input → UI → Widgets
// LAYER       : UI (Presentational only)
// PURPOSE     : "Search instead for X" suggestion row
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_input_colors.dart';
import 'smart_input_strings.dart';
import 'smart_input_styles.dart';

class SmartSpellTile extends StatelessWidget {
  const SmartSpellTile({
    super.key,
    required this.correction,
    required this.onTap,
  });

  final String correction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: SmartInputStyles.spellTileDecoration,
          child: Row(
            children: [
              // Search icon
              Icon(
                Icons.search_rounded,
                size: 16,
                color: SmartInputColors.spellIcon,
              ),
              const SizedBox(width: 8),

              // "Search instead for <correction>"
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: SmartInputStrings.spellPrefix,
                        style: SmartInputStyles.spellTextStyle,
                      ),
                      TextSpan(
                        text: correction,
                        style: SmartInputStyles.spellHighlightStyle,
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow icon
              Icon(
                Icons.north_east_rounded,
                size: 14,
                color: SmartInputColors.spellArrow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
