import 'package:flutter/material.dart';

class QuickActionPopupOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String routeId;

  const QuickActionPopupOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.routeId,
  });
}
