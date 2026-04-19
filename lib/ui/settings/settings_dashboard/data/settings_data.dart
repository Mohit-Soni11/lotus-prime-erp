// =============================================================================
// FILE        : lib/ui/settings/settings_dashboard/data/settings_data.dart
// CHANGE      : "Owner Details" → "Account & Profile" (professional rename)
//               + id changed to "account_profile" taaki navigation kaam kare
// =============================================================================

import '../../../../models/setting/settings_model.dart';
import '../../../../theme/settings/settings_dashboard/settings_theme.dart';

class SettingsData {
  static const List<SettingsModel> items = [
    SettingsModel(
      id: "shop_profile",
      icon: SettingsIcons.shopProfile,
      title: "Shop Profile",
      subtitle: "Manage Address, Logo & Contact Info",
    ),

    // ✅ RENAMED: "Owner Details" → "Account & Profile"
    SettingsModel(
      id: "account_profile",           // ← id change kiya
      icon: SettingsIcons.ownerDetails,
      title: "Account & Profile",      // ← Professional naam
      subtitle: "Edit Profile, Photo & Password",
    ),

    SettingsModel(
      id: "gst_config",
      icon: SettingsIcons.taxGst,
      title: "Tax & GST",
      subtitle: "Setup GSTIN, PAN & Tax Slabs",
    ),
    SettingsModel(
      id: "billing_setup",
      icon: SettingsIcons.billing,
      title: "Billing Setup",
      subtitle: "Invoice Terms, Footer & Printer Settings",
    ),
    SettingsModel(
      id: "security",
      icon: SettingsIcons.security,
      title: "Security & Access",
      subtitle: "Change Password & Manage Staff Roles",
    ),
    SettingsModel(
      id: "backup",
      icon: SettingsIcons.backup,
      title: "Backup & Restore",
      subtitle: "Download Database Backup",
    ),
  ];
}