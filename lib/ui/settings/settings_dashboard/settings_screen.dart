// =============================================================================
// FILE : lib/ui/settings/settings_dashboard/settings_screen.dart
// DESIGN: Dark Premium — Animated live dot — Category groups — Top brand look
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/settings/settings_dashboard/settings_theme.dart';
import 'data/settings_data.dart';
import '../settings_dashboard/settings_ui/settings_card.dart';
import '../shop_setup/shop_setup_wizard.dart';
import '../account_profile/account_profile_screen.dart';
import '../../../models/setting/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String routeId) onNavigate;
  const SettingsScreen({super.key, required this.onNavigate});

  void _handleTap(BuildContext context, SettingsModel item) {
    if (item.id == 'shop_profile') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ShopSetupWizard()));
    } else if (item.id == 'account_profile') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AccountProfileScreen()));
    } else {
      onNavigate(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: SettingsStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ─────────────────────────────────────────────────
              const _Header(),
              const SizedBox(height: 32),
              Divider(
                color: SettingsColors.cardBorder,
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 32),

              // ── CATEGORY SECTIONS ──────────────────────────────────────
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
        // Icon box
        Container(
          padding: const EdgeInsets.all(13),
          decoration: SettingsStyles.headerIconBox,
          child: const Icon(
            SettingsIcons.headerIcon,
            color: SettingsColors.accentGold,
            size: 26,
          ),
        ),
        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: SettingsStyles.headerTitle),
              const SizedBox(height: 6),
              Row(
                children: [
                  // 🟢 Animated live dot
                  const _LiveDot(),
                  const SizedBox(width: 7),
                  const Text('System Online',
                      style: SettingsStyles.headerSubtitle),
                  const SizedBox(width: 12),
                  // Options count pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: SettingsStyles.optionsPill,
                    child: Text(
                      '${SettingsData.items.length} options',
                      style: const TextStyle(
                        fontSize: 11,
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

// ── ANIMATED LIVE GREEN DOT ───────────────────────────────────────────────────
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

    _pulse = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    SettingsColors.onlineGreen.withOpacity(_pulse.value * 0.28),
              ),
            ),
          ),
          // Inner solid dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SettingsColors.onlineGreen,
              boxShadow: [
                BoxShadow(
                  color: SettingsColors.onlineGlow,
                  blurRadius: 6,
                  spreadRadius: 1,
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
  final CategoryMeta meta;
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
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header row
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(meta.icon, color: meta.color, size: 15),
              const SizedBox(width: 8),
              Text(
                meta.label,
                style: SettingsStyles.categoryLabel.copyWith(color: meta.color),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards grid
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
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.65,
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
