// =============================================================================
// FILE : lib/ui/settings/settings_dashboard/data/settings_data.dart
// 10 cards — 4 categories — jewellery ERP ke liye top-brand complete set
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../models/setting/settings_model.dart';
import '../../../../theme/settings/settings_dashboard/settings_theme.dart';

class CategoryMeta {
  final String label;
  final IconData icon;
  final Color color;
  const CategoryMeta(
      {required this.label, required this.icon, required this.color});
}

class SettingsData {
  // ── ALL ITEMS ─────────────────────────────────────────────────────────────
  static const List<SettingsModel> items = [
    // ── BUSINESS ──────────────────────────────────────────────────
    SettingsModel(
      id: 'shop_profile',
      icon: SettingsIcons.shopProfile,
      title: 'Shop Profile',
      subtitle: 'Store naam, logo, address aur contact info',
      category: SettingsCategory.business,
      accentColor: Color(0xFFD4AF37),
    ),
    SettingsModel(
      id: 'account_profile',
      icon: SettingsIcons.ownerDetails,
      title: 'Account & Profile',
      subtitle: 'Owner ka photo, naam aur password',
      category: SettingsCategory.business,
      accentColor: Color(0xFF7C6AE8),
    ),
    SettingsModel(
      id: 'billing_setup',
      icon: SettingsIcons.billing,
      title: 'Billing Setup',
      subtitle: 'Invoice terms, footer text, printer config',
      category: SettingsCategory.business,
      accentColor: Color(0xFF0EA5E9),
    ),
    SettingsModel(
      id: 'print_templates',
      icon: SettingsIcons.printTemplates,
      title: 'Print Templates',
      subtitle: 'Invoice, receipt aur girvi note design',
      category: SettingsCategory.business,
      accentColor: Color(0xFFE06B3F),
    ),

    // ── FINANCE ───────────────────────────────────────────────────
    SettingsModel(
      id: 'gst_config',
      icon: SettingsIcons.taxGst,
      title: 'Tax & GST',
      subtitle: 'GSTIN, PAN number aur tax slabs setup',
      category: SettingsCategory.finance,
      accentColor: Color(0xFF16A34A),
    ),
    SettingsModel(
      id: 'gold_rate_settings',
      icon: SettingsIcons.goldRate,
      title: 'Gold Rate Settings',
      subtitle: 'Default rates, IBJA sync aur rate rounding',
      category: SettingsCategory.finance,
      accentColor: Color(0xFFD97706),
    ),

    // ── SECURITY ──────────────────────────────────────────────────
    SettingsModel(
      id: 'security',
      icon: SettingsIcons.security,
      title: 'Security & Access',
      subtitle: 'PIN lock, staff roles aur permissions',
      category: SettingsCategory.security,
      accentColor: Color(0xFFDC2626),
    ),

    // ── SYSTEM ────────────────────────────────────────────────────
    SettingsModel(
      id: 'notifications',
      icon: SettingsIcons.notifications,
      title: 'Notifications',
      subtitle: 'EMI due, girvi expiry aur stock alerts',
      category: SettingsCategory.system,
      accentColor: Color(0xFF2563EB),
    ),
    SettingsModel(
      id: 'app_preferences',
      icon: SettingsIcons.appPrefs,
      title: 'App Preferences',
      subtitle: 'Language, date format aur display settings',
      category: SettingsCategory.system,
      accentColor: Color(0xFF0891B2),
    ),
    SettingsModel(
      id: 'backup',
      icon: SettingsIcons.backup,
      title: 'Backup & Restore',
      subtitle: 'Database backup download ya restore karo',
      category: SettingsCategory.system,
      accentColor: Color(0xFF4ADE80),
    ),
  ];

  // ── CATEGORY METADATA ─────────────────────────────────────────────────────
  static const Map<SettingsCategory, CategoryMeta> categoryMeta = {
    SettingsCategory.business: CategoryMeta(
      label: 'BUSINESS',
      icon: Icons.store_rounded,
      color: Color(0xFFD4AF37),
    ),
    SettingsCategory.finance: CategoryMeta(
      label: 'FINANCE & TAX',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF16A34A),
    ),
    SettingsCategory.security: CategoryMeta(
      label: 'SECURITY',
      icon: Icons.shield_rounded,
      color: Color(0xFFDC2626),
    ),
    SettingsCategory.system: CategoryMeta(
      label: 'SYSTEM',
      icon: Icons.settings_rounded,
      color: Color(0xFF2563EB),
    ),
  };

  // ── HELPERS ──────────────────────────────────────────────────────────────
  static List<SettingsModel> getByCategory(SettingsCategory cat) =>
      items.where((i) => i.category == cat).toList();
}
