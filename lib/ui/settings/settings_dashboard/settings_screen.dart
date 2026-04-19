// =============================================================================
// FILE        : lib/ui/settings/settings_dashboard/settings_screen.dart
// CHANGE      : "account_profile" card click → AccountProfileScreen navigate
// =============================================================================

import 'package:flutter/material.dart';

import '../../../theme/settings/settings_dashboard/settings_theme.dart';
import 'data/settings_data.dart';
import '../settings_dashboard/settings_ui/settings_card.dart';
import '../shop_setup/shop_setup_wizard.dart';

// ✅ NEW IMPORT: Account Profile Screen
import '../account_profile/account_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String routeId) onNavigate;

  const SettingsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = SettingsData.items;

    return Scaffold(
      backgroundColor: SettingsColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: SettingsStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              Divider(color: SettingsColors.borderDefault, thickness: 1),
              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100 ? 4 :
                                       constraints.maxWidth > 800  ? 3 :
                                       constraints.maxWidth > 600  ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return SettingsCard(
                        item: item,
                        onTap: () {
                          if (item.id == "shop_profile") {
                            // Shop profile → wizard
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopSetupWizard(),
                              ),
                            );

                          } else if (item.id == "account_profile") {
                            // ✅ NEW: Account Profile → AccountProfileScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountProfileScreen(),
                              ),
                            );

                          } else {
                            onNavigate(item.id);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: SettingsStyles.iconBoxDecoration,
          child: const Icon(SettingsIcons.headerIcon,
              color: SettingsColors.accentGold, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SETTINGS DASHBOARD", style: SettingsStyles.headerTitle),
            Row(
              children: [
                const Icon(SettingsIcons.systemStatus,
                    size: 8, color: Color(0xFF00E676)),
                const SizedBox(width: 6),
                Text("System Online", style: SettingsStyles.systemStatus),
              ],
            ),
          ],
        ),
      ],
    );
  }
}