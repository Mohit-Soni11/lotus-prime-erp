import 'package:flutter/material.dart';

import 'due_collection_entry_colors.dart';

class DueCollectionEntryStyles {
  const DueCollectionEntryStyles._();

  static const TextStyle appBarTitle = TextStyle(
    color: DueCollectionEntryColors.shellTitle,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle appBarSub = TextStyle(
    color: DueCollectionEntryColors.shellMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: DueCollectionEntryColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle label = TextStyle(
    color: DueCollectionEntryColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle muted = TextStyle(
    color: DueCollectionEntryColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle amount = TextStyle(
    color: DueCollectionEntryColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle rowTitle = TextStyle(
    color: DueCollectionEntryColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle rowSub = TextStyle(
    color: DueCollectionEntryColors.textMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static BoxDecoration panel(
      {Color color = DueCollectionEntryColors.bodyPanel}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DueCollectionEntryColors.bodyBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration flatPanel(
      {Color color = DueCollectionEntryColors.bodyPanel}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: DueCollectionEntryColors.bodyBorder),
    );
  }
}
