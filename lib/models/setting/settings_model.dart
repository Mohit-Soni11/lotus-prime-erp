// =============================================================================
// FILE : lib/models/setting/settings_model.dart
// =============================================================================

import 'package:flutter/material.dart';

enum SettingsCategory { business, finance, security, system }

class SettingsModel {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final SettingsCategory category;
  final Color accentColor;

  const SettingsModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.accentColor,
  });
}
