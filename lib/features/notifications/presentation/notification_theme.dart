import 'package:flutter/material.dart';
import '../../../theme/dashboard/app/uv.dart';
import '../../../theme/dashboard/topbar/topbar_colors.dart';
import '../../../theme/girvi/girvi_colors.dart';
import '../../../theme/settings/metal_rate/metal_rate_colors.dart';

abstract final class NotificationTheme {
  static const background = TopBarColors.background;
  static const surface = TopBarColors.profileBg;
  static const ink = TopBarColors.textPrimary;
  static const muted = TopBarColors.textSecondary;
  static const border = TopBarColors.divider;
  static const shell = TopBarColors.background;
  static const shellInk = MetalRateColors.shellTextTitle;
  static const shellMuted = MetalRateColors.shellTextMuted;
  static const gold = TopBarColors.accentGold;
  static const goldInk = gold;
  static const onGold = TopBarColors.background;
  static const red = TopBarColors.notificationRed;
  static LinearGradient get goldGradient => UV.colors.goldGradient;

  static ThemeData data(ThemeData base) => base.copyWith(
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ).copyWith(
            primary: gold,
            onPrimary: onGold,
            surface: surface,
            onSurface: ink,
            outline: border,
            error: red),
        textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: muted, fontSize: 13),
          prefixIconColor: muted,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold)),
        ),
      );
  static Color accent(String category) => switch (category) {
        'Inventory' => gold,
        'Orders' => GirviColors.info,
        'Collections' => red,
        'Girvi' => GirviColors.accentLoan,
        'Day Book' => TopBarColors.systemOnline,
        'Metal Rates' => MetalRateColors.gold,
        _ => muted,
      };
  static IconData icon(String category) => switch (category) {
        'Inventory' => Icons.inventory_2_outlined,
        'Orders' => Icons.local_shipping_outlined,
        'Collections' => Icons.payments_outlined,
        'Girvi' => Icons.handshake_outlined,
        'Day Book' => Icons.account_balance_outlined,
        'Metal Rates' => Icons.diamond_outlined,
        _ => Icons.notifications_outlined,
      };
}
