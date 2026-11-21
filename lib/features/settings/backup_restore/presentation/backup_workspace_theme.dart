import 'package:flutter/material.dart';

abstract final class BackupWorkspaceTheme {
  static const navy = Color(0xFF1F2937);
  static const gold = Color(0xFFD4AF37);
  static const canvas = Color(0xFFF8F5F1);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const green = Color(0xFF087A30);

  static ThemeData of(BuildContext context) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        colorScheme: ColorScheme.fromSeed(
            seedColor: gold,
            brightness: Brightness.light,
            primary: const Color(0xFF9A730D),
            surface: Colors.white),
        scaffoldBackgroundColor: canvas,
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: ink,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)))),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
      );
}

class BackupPanel extends StatelessWidget {
  const BackupPanel(
      {super.key,
      required this.title,
      required this.icon,
      required this.child,
      this.subtitle});
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BackupWorkspaceTheme.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C111827),
                  blurRadius: 18,
                  offset: Offset(0, 5))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color:
                            BackupWorkspaceTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child:
                        Icon(icon, size: 22, color: const Color(0xFF9A730D))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: BackupWorkspaceTheme.ink)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: BackupWorkspaceTheme.muted))
                      ],
                    ])),
              ]),
              const SizedBox(height: 18),
              child,
            ]),
      );
}
