import 'package:flutter/material.dart';

import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_metal_hub_card.dart';
import 'billing_setup_app_bar.dart';
import 'purchase_metal_settings_screen.dart';

class PurchaseMetalHubScreen extends StatefulWidget {
  const PurchaseMetalHubScreen({super.key});

  @override
  State<PurchaseMetalHubScreen> createState() => _PurchaseMetalHubScreenState();
}

class _PurchaseMetalHubScreenState extends State<PurchaseMetalHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardsAnim;

  static const List<BillingMetalHubData> _metals = [
    BillingMetalHubData(
      metal: 'gold',
      title: 'Gold',
      subtitle: 'Supplier voucher rules for hallmark and tested gold intake.',
      actionLabel: 'Configure Gold',
      badges: ['HUID', 'Purity', 'PAN'],
      fallbackIcon: Icons.workspace_premium_rounded,
      accent: BillingSetupColors.metalGold,
      surface: BillingSetupColors.metalGoldBg,
      logoAsset: 'lib/logo/gold.jpeg',
    ),
    BillingMetalHubData(
      metal: 'silver',
      title: 'Silver',
      subtitle: 'Lean purchase defaults for sterling and article stock.',
      actionLabel: 'Configure Silver',
      badges: ['Weight', 'Rate', 'Supplier'],
      fallbackIcon: Icons.toll_rounded,
      accent: BillingSetupColors.metalSilver,
      surface: BillingSetupColors.metalSilverBg,
      logoAsset: 'lib/logo/silver and platinum .jpeg',
    ),
    BillingMetalHubData(
      metal: 'diamond',
      title: 'Diamond',
      subtitle: 'Acquisition controls for certificates, carats and clarity.',
      actionLabel: 'Configure Diamond',
      badges: ['Certificate', 'Carat', 'Value'],
      fallbackIcon: Icons.auto_awesome_rounded,
      accent: BillingSetupColors.metalDiamond,
      surface: BillingSetupColors.metalDiamondBg,
      logoAsset: 'lib/logo/diamond .jpeg',
    ),
    BillingMetalHubData(
      metal: 'platinum',
      title: 'Platinum',
      subtitle: 'Purchase voucher settings for precise platinum costing.',
      actionLabel: 'Configure Platinum',
      badges: ['950 PT', 'Fine Wt', 'Terms'],
      fallbackIcon: Icons.radio_button_checked_rounded,
      accent: BillingSetupColors.metalPlatinum,
      surface: BillingSetupColors.metalPlatinumBg,
      logoAsset: 'lib/logo/silver and platinum .jpeg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cardsAnim.forward();
    });
  }

  @override
  void dispose() {
    _cardsAnim.dispose();
    super.dispose();
  }

  void _openMetal(String metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            PurchaseMetalSettingsScreen(metal: metal),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: 'Purchase Billing',
        screenSubtitle: 'Voucher rules by metal category',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 960
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < _metals.length; i++)
                    SizedBox(
                      width: cardWidth,
                      child: BillingMetalHubCard(
                        data: _metals[i],
                        animationController: _cardsAnim,
                        delay: i * 0.10,
                        onTap: () => _openMetal(_metals[i].metal),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
