// =============================================================================
// FILE        : smart_suggestion_zone.dart
// MODULE      : Shared → Smart Input → UI → Widgets
// LAYER       : UI (Presentational only)
// PURPOSE     : Suggestion zone — sirf tab rebuild hota hai jab
//               ListenableBuilder trigger kare. TextField kabhi rebuild
//               nahi hota. Zero jank.
//
// ✅ FIXES APPLIED:
//   1. Error state dikhata hai (red warning tile)
//   2. API key missing hone pe clear message
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_input_controller.dart';
import 'smart_input_styles.dart';
import 'smart_input_colors.dart';
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
    final hasError = controller.hasError;
    final fieldType = controller.fieldType;

    // Kuchh nahi dikhana — SizedBox.shrink
    if (!hasSpell && !hasChips && !isLoading && !hasError) {
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
            // ── ✅ Error Tile ───────────────────────────────────────────────
            if (hasError) ...[
              _ErrorTile(message: controller.errorMessage!),
              const SizedBox(height: 4),
            ],

            // ── Spell Correction Row ────────────────────────────────────────
            if (hasSpell && !hasError) ...[
              SmartSpellTile(
                correction: controller.spellCorrection!,
                onTap: onSpellTap,
              ),
              const SizedBox(height: 8),
            ],

            // ── Suggestion Chips ────────────────────────────────────────────
            if (hasChips && fieldType.showSuggestionChips && !hasError) ...[
              Row(
                children: [
                  Text(
                    SmartInputStrings.chipLabel(fieldType),
                    style: SmartInputStyles.chipLabelStyle,
                  ),
                  const SizedBox(width: 8),
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

            // ── Loading Shimmer ─────────────────────────────────────────────
            if (isLoading && !hasSpell && !hasChips) const SmartShimmerRow(),
          ],
        ),
      ),
    );
  }
}

// ── Error Tile ────────────────────────────────────────────────────────────────
class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 15, color: Color(0xFFE53935)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFB71C1C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
