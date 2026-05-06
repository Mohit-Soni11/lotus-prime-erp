// =============================================================================
// FILE        : smart_suggestion_zone.dart
// MODULE      : Shared → Smart Input → UI → Widgets
// LAYER       : UI (Presentational only)
// PURPOSE     : Suggestion zone — ye sirf tab rebuild hota hai jab
//               ListenableBuilder trigger kare. TextField kabhi rebuild
//               nahi hota. Zero jank.
// =============================================================================

import 'package:flutter/material.dart';
//import 'smart_field_type.dart';
import 'smart_input_controller.dart';
import 'smart_input_styles.dart';
import 'smart_input_strings.dart';
import 'smart_spell_tile.dart';
import 'smart_chip_widget.dart';
import 'smart_shimmer_row.dart';

class SmartSuggestionZone extends StatelessWidget {
  const SmartSuggestionZone({
    super.key,
    required this.controller,
    required this.onSpellTap,
    required this.onChipTap,
  });

  final SmartInputController controller;
  final VoidCallback onSpellTap;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final hasSpell = controller.spellCorrection != null;
    final hasChips = controller.suggestions.isNotEmpty;
    final isLoading = controller.isLoading;
    final fieldType = controller.fieldType;

    // Kuchh nahi dikhana — SizedBox.shrink return karo
    if (!hasSpell && !hasChips && !isLoading) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: SmartInputStyles.animDuration,
      curve: SmartInputStyles.animCurve,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Spell Correction Row ────────────────────────────────────────
            if (hasSpell) ...[
              SmartSpellTile(
                correction: controller.spellCorrection!,
                onTap: onSpellTap,
              ),
              const SizedBox(height: 8),
            ],

            // ── Suggestion Chips ────────────────────────────────────────────
            if (hasChips && fieldType.showSuggestionChips) ...[
              Row(
                children: [
                  // Label (हिंदी: / Suggestions: / Items:)
                  Text(
                    SmartInputStrings.chipLabel(fieldType),
                    style: SmartInputStyles.chipLabelStyle,
                  ),
                  const SizedBox(width: 8),

                  // Chips wrapped
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: controller.suggestions.map((chip) {
                        return SmartChipWidget(
                          label: chip,
                          fieldType: fieldType,
                          onTap: () => onChipTap(chip),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            // ── Loading Shimmer (only if no results yet) ────────────────────
            if (isLoading && !hasSpell && !hasChips) const SmartShimmerRow(),
          ],
        ),
      ),
    );
  }
}
