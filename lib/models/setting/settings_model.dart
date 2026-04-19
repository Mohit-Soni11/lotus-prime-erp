import 'package:flutter/material.dart';

class SettingsModel {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  // Constructor (Contract signing)
  const SettingsModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}