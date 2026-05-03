// =============================================================================
// FILE        : lib/ui/settings/settings_dashboard/settings_screen.dart
// DESCRIPTION : Settings hub screen. v12 — billingSetup navigation wired.
//               FIXED: Uses original SettingsColors/SettingsData/CategoryMeta
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/settings_dashboard/settings_theme.dart';
import 'data/settings_data.dart';
import '../settings_dashboard/settings_ui/settings_card.dart';
import '../../../models/setting/settings_model.dart';

import '../shop_setup/shop_setup_wizard.dart';
import '../account_profile/account_profile_screen.dart';

// ✅ v12: Billing Setup
import '../billing_setup/billing_setup_hub_screen.dart';

// ✅ Metal Costing Analysis
import '../metal_costing/metal_costing_hub_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String routeId) onNavigate;
  const SettingsScreen({super.key, required this.onNavigate});

  void _handleTap(BuildContext context, SettingsModel item) {
    switch (item.id) {
      case 'shop_profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopSetupWizard()),
        );
        break;

      case 'account_profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountProfileScreen()),
        );
        break;

      // ✅ v12: Billing Setup — fade transition
      case 'billing_setup':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const BillingSetupHubScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 260),
          ),
        );
        break;

      // ✅ Metal Costing Analysis — fade transition
      case 'metal_costing':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const MetalCostingHubScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 260),
          ),
        );
        break;

      default:
        onNavigate(item.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.pageBackground, // ✅ original naam
      body: SafeArea(
        child: SingleChildScrollView(
          padding: SettingsStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 36),
              Divider(
                  color: SettingsColors.cardBorder, thickness: 1, height: 1),
              const SizedBox(height: 36),
              // ✅ Original SettingsCategory loop — SettingsGroup nahi
              ...SettingsCategory.values.map((cat) {
                final items = SettingsData.getByCategory(cat);
                if (items.isEmpty) return const SizedBox.shrink();
                final meta = SettingsData.categoryMeta[cat]!;
                return _CategorySection(
                  meta: meta,
                  items: items,
                  onTap: (item) => _handleTap(context, item),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: SettingsStyles.headerIconBox,
          child: const Icon(
            SettingsIcons.headerIcon,
            color: SettingsColors.accentGold,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ SettingsStyles.headerTitle — original style
              const Text('Settings', style: SettingsStyles.headerTitle),
              const SizedBox(height: 8),
              Row(
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 8),
                  const Text('System Online',
                      style: SettingsStyles.headerSubtitle),
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: SettingsStyles.optionsPill,
                    child: Text(
                      '${SettingsData.items.length} Options',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SettingsColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── ANIMATED LIVE DOT ─────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    SettingsColors.onlineGreen.withOpacity(_pulse.value * 0.28),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SettingsColors.onlineGreen,
              boxShadow: [
                BoxShadow(
                  color: SettingsColors.onlineGlow,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CATEGORY SECTION ──────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final CategoryMeta meta; // ✅ original — SettingsGroup nahi
  final List<SettingsModel> items;
  final void Function(SettingsModel) onTap;

  const _CategorySection({
    required this.meta,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(meta.icon, color: meta.color, size: 16),
              const SizedBox(width: 9),
              Text(
                meta.label,
                style: SettingsStyles.categoryLabel.copyWith(
                  color: meta.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ✅ Original responsive GridView
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w > 1100
                  ? 4
                  : w > 750
                      ? 3
                      : w > 500
                          ? 2
                          : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (_, i) => SettingsCard(
                  item: items[i],
                  onTap: () => onTap(items[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
