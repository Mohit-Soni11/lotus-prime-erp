import 'package:flutter/material.dart';

abstract final class BackupWorkspaceTheme {
  static const canvas = Color(0xFFF8F7F5);
  static const surface = Colors.white;
  static const navy = Color(0xFF172435);
  static const surfaceLow = Color(0xFFF7F8FA);
  static const gold = Color(0xFFD4A927);
  static const ink = Color(0xFF101827);
  static const muted = Color(0xFF596575);
  static const border = Color(0xFFD9DDE3);
  static const green = Color(0xFF0B9B51);
  static const amber = Color(0xFFA86300);

  static ThemeData of(BuildContext context) {
    final base = Theme.of(context);
    final fontFamily = base.textTheme.bodyMedium?.fontFamily;
    final text = ThemeData(brightness: Brightness.light, useMaterial3: true)
        .textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: ink,
          displayColor: ink,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
      ).copyWith(
        primary: gold,
        onPrimary: ink,
        surface: surface,
        onSurface: ink,
        outline: border,
      ),
      scaffoldBackgroundColor: canvas,
      canvasColor: surface,
      textTheme: text.copyWith(
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, color: ink),
        bodySmall: text.bodySmall?.copyWith(fontSize: 13, color: muted),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: ink,
          side: const BorderSide(color: border),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: gold.withValues(alpha: 0.12),
          foregroundColor: ink,
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? gold : surfaceLow),
          foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? ink : ink),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? gold : muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? gold.withValues(alpha: 0.35)
                : surfaceLow),
        trackOutlineColor: const WidgetStatePropertyAll(border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        labelStyle: const TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: text.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(fontSize: 14, color: ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
      dividerTheme: const DividerThemeData(color: border),
    );
  }
}

class BackupPanel extends StatelessWidget {
  const BackupPanel(
      {super.key, this.title, this.icon, this.trailing, required this.child});

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BackupWorkspaceTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101827),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              LayoutBuilder(builder: (context, constraints) {
                final heading = Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color:
                            BackupWorkspaceTheme.gold.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          size: 20, color: BackupWorkspaceTheme.amber),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(title!,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: BackupWorkspaceTheme.ink)),
                  ),
                ]);
                if (trailing == null) return heading;
                if (constraints.maxWidth < 540) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: trailing),
                    ],
                  );
                }
                return Row(children: [
                  Expanded(child: heading),
                  const SizedBox(width: 12),
                  trailing!,
                ]);
              }),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      );
}
