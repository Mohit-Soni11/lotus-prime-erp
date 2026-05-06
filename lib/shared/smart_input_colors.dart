// =============================================================================
// FILE        : smart_input_colors.dart
// MODULE      : Shared → Smart Input
// LAYER       : Theme → Colors
// =============================================================================

import 'package:flutter/material.dart';

class SmartInputColors {
  SmartInputColors._();

  // ── Spell Correction Tile ──────────────────────────────────────────────────
  static const Color spellTileBg      = Color(0xFFFFF8E1); // Warm gold tint
  static const Color spellTileBorder  = Color(0x33D4AF37); // Gold border 20%
  static const Color spellText        = Color(0xFF64748B);
  static const Color spellHighlight   = Color(0xFFD4AF37); // Brand gold
  static const Color spellIcon        = Color(0xFFD4AF37);
  static const Color spellArrow       = Color(0xFFD4AF37);

  // ── Suggestion Chips ──────────────────────────────────────────────────────
  static const Color chipBg           = Color(0xFFFFF8E1); // Gold tint
  static const Color chipBgPressed    = Color(0xFFFFEFBA);
  static const Color chipBorder       = Color(0x55D4AF37);
  static const Color chipText         = Color(0xFF7A5A00); // Dark gold text
  static const Color chipLabelText    = Color(0xFF9CA3AF);

  // ── Loading / Shimmer ─────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE8E3DA); // Cream
  static const Color shimmerHighlight = Color(0xFFF9F6F0); // Lighter cream
  static const Color loadingBarBg     = Color(0xFFE8E3DA);
  static const Color loadingBarFill   = Color(0xFFD4AF37); // Gold sweep

  // ── Loading spinner (in TextField suffix) ─────────────────────────────────
  static const Color spinnerColor     = Color(0xFFD4AF37);

  // ── Zone container ────────────────────────────────────────────────────────
  static const Color zoneBg          = Colors.transparent;
}
