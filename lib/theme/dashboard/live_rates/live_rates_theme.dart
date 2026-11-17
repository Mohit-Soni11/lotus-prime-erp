import 'package:flutter/material.dart';

class LiveRatesColors {
  const LiveRatesColors._();

  static const background = Color(0xFF101925);
  static const goldPanel = Color(0xFF242015);
  static const silverPanel = Color(0xFF142338);
  static const gold = Color(0xFFE4B94D);
  static const silver = Color(0xFFC9D9EA);
  static const text = Color(0xFFF5F7FB);
  static const muted = Color(0xFFAFBBCB);
  static const green = Color(0xFF31DE94);
  static const divider = Color(0x30FFFFFF);
}

class LiveRatesStrings {
  const LiveRatesStrings._();

  static const title = "Today's Metal Rates";
  static const live = 'Live Rate';
  static const gold = 'GOLD';
  static const silver = 'SILVER';
  static const purity = 'Purity';
  static const perGram = 'Per gram';
  static const perTenGrams = 'Per 10g';
  static const perKilogram = 'Per kg';
  static const viewPurchase = 'View Purchase Rates';
  static const hidePurchase = 'Hide Purchase Rates';
}

class LiveRatesStyles {
  const LiveRatesStyles._();

  static BoxDecoration get card => BoxDecoration(
        color: LiveRatesColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: LiveRatesColors.gold.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration panel({required bool isGold}) {
    final accent = isGold ? LiveRatesColors.gold : LiveRatesColors.silver;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isGold
            ? const [Color(0xFF47391E), LiveRatesColors.goldPanel]
            : const [Color(0xFF254361), LiveRatesColors.silverPanel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: accent.withValues(alpha: 0.48)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static const title = TextStyle(
    color: LiveRatesColors.text,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const date = TextStyle(
    color: LiveRatesColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const panelTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
  static const column = TextStyle(
    color: LiveRatesColors.muted,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const purity = TextStyle(
    color: LiveRatesColors.text,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const rate = TextStyle(
    color: LiveRatesColors.text,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
}
