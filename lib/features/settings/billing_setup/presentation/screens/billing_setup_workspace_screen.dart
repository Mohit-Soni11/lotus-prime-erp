import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/app_routes.dart';
import '../../girvi/presentation/screens/girvi_billing_workspace_screen.dart';
import '../../domain/entities/billing_setup_module.dart';
import '../../purchase/presentation/screens/purchase_billing_workspace_screen.dart';
import '../../sales/presentation/screens/sales_billing_workspace_screen.dart';
import '../../shop_info/presentation/screens/shop_print_information_screen.dart';
import '../widgets/billing_setup_module_card.dart';
import '../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../../../../theme/settings/billing_setup/billing_setup_strings.dart';
import '../../../../../ui/settings/billing_setup/billing_setup_app_bar.dart';

class BillingSetupWorkspaceScreen extends StatelessWidget {
  const BillingSetupWorkspaceScreen({super.key});

  void _openModule(BuildContext context, BillingSetupModule module) {
    switch (module.id) {
      case BillingSetupModuleId.sales:
        _pushLegacyModule(context, const SalesBillingWorkspaceScreen());
        return;
      case BillingSetupModuleId.purchase:
        _pushLegacyModule(context, const PurchaseBillingWorkspaceScreen());
        return;
      case BillingSetupModuleId.girvi:
        _pushLegacyModule(context, const GirviBillingWorkspaceScreen());
        return;
      case BillingSetupModuleId.shopPrintInformation:
        _pushLegacyModule(context, const ShopPrintInformationScreen());
        return;
    }
  }

  void _pushLegacyModule(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _returnToSettings(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.settings);
  }

  @override
  Widget build(BuildContext context) {
    const modules = BillingSetupModules.all;

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: BillingSetupStrings.hubTitle,
        screenSubtitle: BillingSetupStrings.hubSub,
        onBack: () => _returnToSettings(context),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1200 ? 36.0 : 20.0;
            final topPadding = constraints.maxHeight >= 720 ? 30.0 : 22.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                36,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT MODULE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: BillingSetupColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ModuleGrid(
                      modules: modules,
                      onOpen: (module) => _openModule(context, module),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  static const double _gap = 20;
  static const double _cardHeight = 218;

  final List<BillingSetupModule> modules;
  final ValueChanged<BillingSetupModule> onOpen;

  const _ModuleGrid({
    required this.modules,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: _gap,
            mainAxisSpacing: _gap,
            mainAxisExtent: _cardHeight,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return BillingSetupModuleCard(
              module: module,
              height: _cardHeight,
              onOpen: () => onOpen(module),
            );
          },
        );
      },
    );
  }
}
