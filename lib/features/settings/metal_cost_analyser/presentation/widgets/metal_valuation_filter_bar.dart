import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationFilterBar extends StatelessWidget {
  final MetalValuationFilter selected;
  final ValueChanged<MetalValuationFilter> onChanged;

  const MetalValuationFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: MetalValuationFilter.values.map((filter) {
          final active = filter == selected;
          return Tooltip(
            message: 'Show ${filter.label.toLowerCase()} valuation',
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minWidth: 112),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: active ? MetalValuationColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: active
                        ? MetalValuationColors.goldDark
                        : MetalValuationColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      active
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: active ? Colors.white : MetalValuationColors.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filter.label,
                      style: MetalValuationText.body.copyWith(
                        color: active ? Colors.white : MetalValuationColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
