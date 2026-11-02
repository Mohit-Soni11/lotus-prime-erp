import 'package:flutter/material.dart';

import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookAddEntryButton extends StatelessWidget {
  const CashBookAddEntryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: CashBookStrings.addEntry,
      backgroundColor: CashBookColors.brandGold,
      foregroundColor: CashBookColors.textDark,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        CashBookStrings.addEntry,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
