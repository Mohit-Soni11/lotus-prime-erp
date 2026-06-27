// =============================================================================
// FILE : lib/ui/settings/settings_dashboard/data/settings_data.dart
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../constants/app_routes.dart';
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
  static const List<SettingsModel> items = [
    // ── BUSINESS ──────────────────────────────────────────────────────────
    SettingsModel(
      id: 'shop_profile',
      icon: SettingsIcons.shopProfile,
      title: 'Shop Profile',
      subtitle: 'Configure store name, logo, address & contact details',
      category: SettingsCategory.business,
      accentColor: Color(0xFFD4AF37),
    ),
    SettingsModel(
      id: 'account_profile',
      icon: SettingsIcons.ownerDetails,
      title: 'Account & Profile',
      subtitle: 'Update owner name, profile photo & login credentials',
      category: SettingsCategory.business,
      accentColor: Color(0xFF7C6AE8),
    ),
    SettingsModel(
      id: 'billing_setup',
      icon: SettingsIcons.billing,
      title: 'Billing Setup',
      subtitle: 'Customize invoice layout, terms & printer preferences',
      category: SettingsCategory.business,
      accentColor: Color(0xFF0EA5E9),
    ),
    SettingsModel(
      id: AppRoutes.printTemplatesRoute,
      icon: SettingsIcons.printTemplates,
      title: 'Print Templates',
      subtitle: 'Design invoice, receipt & girvi note print formats',
      category: SettingsCategory.business,
      accentColor: Color(0xFFE06B3F),
    ),

    // ── FINANCE ───────────────────────────────────────────────────────────
    SettingsModel(
      id: 'metal_costing',
      icon: Icons.analytics_rounded,
      title: 'Metal Cost Analyser',
      subtitle: 'Purchase cost, current value & profit/loss per metal & purity',
      category: SettingsCategory.finance,
      accentColor: Color(0xFFD97706),
    ),
    SettingsModel(
      id: 'gst_config',
      icon: SettingsIcons.taxGst,
      title: 'Tax & GST',
      subtitle: 'Configure GSTIN, PAN number & applicable tax slabs',
      category: SettingsCategory.finance,
      accentColor: Color(0xFF16A34A),
    ),
    SettingsModel(
      id: 'gold_rate_settings',
      icon: SettingsIcons.goldRate,
      title: 'Metal Rate Master',
      subtitle: 'Set daily selling and old-buy rates for all metals',
      category: SettingsCategory.finance,
      accentColor: Color(0xFFD97706),
    ),

    // ── SECURITY ──────────────────────────────────────────────────────────
    SettingsModel(
      id: 'security',
      icon: SettingsIcons.security,
      title: 'Security & Access',
      subtitle: 'Manage PIN lock, staff roles & module permissions',
      category: SettingsCategory.security,
      accentColor: Color(0xFFDC2626),
    ),

    // ── SYSTEM ────────────────────────────────────────────────────────────
    SettingsModel(
      id: 'notifications',
      icon: SettingsIcons.notifications,
      title: 'Notifications',
      subtitle: 'Configure alerts for EMI dues, girvi expiry & low stock',
      category: SettingsCategory.system,
      accentColor: Color(0xFF2563EB),
    ),
    SettingsModel(
      id: 'app_preferences',
      icon: SettingsIcons.appPrefs,
      title: 'App Preferences',
      subtitle: 'Set language, date format & regional display options',
      category: SettingsCategory.system,
      accentColor: Color(0xFF0891B2),
    ),
    SettingsModel(
      id: 'backup',
      icon: SettingsIcons.backup,
      title: 'Backup & Restore',
      subtitle: 'Download a complete database backup or restore data',
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

  static List<SettingsModel> getByCategory(SettingsCategory cat) =>
      items.where((i) => i.category == cat).toList();
}
