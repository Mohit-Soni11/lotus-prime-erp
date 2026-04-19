// =============================================================================
// FILE        : karigar_section_card.dart
// MODULE      : Karigar
// LAYER       : UI / Shared Components
// DESCRIPTION : Reusable white card with colored accent border and icon header.
//               Same pattern as _StockSection in AddStockScreen.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/karigar/karigar_theme.dart';

class KarigarSectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    accent;
  final Widget   child;

  const KarigarSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KarigarStyles.cardWithAccent(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: KarigarColors.divider, width: 1),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: KarigarStyles.sectionIconBox(accent),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,    style: KarigarStyles.sectionTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: KarigarStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ]),
          ),
          // Card body
          Padding(
            padding: KarigarStyles.cardPadding,
            child: child,
          ),
        ],
      ),
    );
  }
}
