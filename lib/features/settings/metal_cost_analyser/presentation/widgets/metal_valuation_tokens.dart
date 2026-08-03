import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetalValuationColors {
  MetalValuationColors._();

  static const shell = Color(0xFF1F2937);
  static const shellBorder = Color(0xFF334155);
  static const canvas = Color(0xFFF7F3EA);
  static const panel = Color(0xFFFFFCF7);
  static const line = Color(0xFFE7DCC8);
  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF334155);
  static const softInk = Color(0xFF64748B);
  static const gold = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8860B);
  static const green = Color(0xFF00C48C);
  static const red = Color(0xFFFF4141);
  static const blue = Color(0xFF2563EB);
  static const slate = Color(0xFF78909C);
}

class MetalValuationText {
  MetalValuationText._();

  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 20,
        height: 1.1,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 20,
        height: 1.15,
        fontWeight: FontWeight.w900,
        color: MetalValuationColors.ink,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: MetalValuationColors.ink,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: MetalValuationColors.ink,
      );

  static TextStyle get value => GoogleFonts.manrope(
        fontSize: 22,
        height: 1.08,
        fontWeight: FontWeight.w900,
        color: MetalValuationColors.ink,
      );
}

BoxDecoration valuationPanelDecoration({Color? color}) {
  return BoxDecoration(
    color: color ?? MetalValuationColors.panel,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: MetalValuationColors.line),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String formatMoney(double value) {
  final sign = value < 0 ? '-' : '';
  return '${sign}Rs ${value.abs().toStringAsFixed(2)}';
}

String formatGram(double value) => '${value.toStringAsFixed(3)} g';

String formatPercent(double value) => '${value.toStringAsFixed(2)}%';

String formatDate(DateTime? value) {
  if (value == null) return 'Not recorded';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day-$month-${value.year}';
}

String titleCase(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'Not recorded';
  return clean.split(RegExp(r'\s+')).map((part) {
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }).join(' ');
}
