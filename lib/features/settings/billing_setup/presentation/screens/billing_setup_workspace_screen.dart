import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/app_routes.dart';
import '../../girvi/presentation/screens/girvi_billing_workspace_screen.dart';
import '../../domain/entities/billing_setup_module.dart';
import '../../purchase/presentation/screens/purchase_billing_workspace_screen.dart';
import '../../sales/presentation/screens/sales_billing_workspace_screen.dart';
import '../theme/billing_setup_design_tokens.dart';
import '../widgets/billing_setup_module_card.dart';
import '../widgets/billing_setup_navigation_panel.dart';
import '../widgets/billing_setup_preview_panel.dart';
import '../widgets/billing_setup_workspace_header.dart';

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
      case BillingSetupModuleId.printTemplates:
        context.go(RoutePaths.printTemplates);
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
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1120;

    return Scaffold(
      backgroundColor: BillingSetupDesignTokens.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BillingSetupWorkspaceHeader(
                onBack: () => _returnToSettings(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              sliver: SliverToBoxAdapter(
                child: isCompact
                    ? _CompactWorkspace(
                        modules: modules,
                        onOpen: (module) => _openModule(context, module),
                      )
                    : _DesktopWorkspace(
                        modules: modules,
                        onOpen: (module) => _openModule(context, module),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopWorkspace extends StatelessWidget {
  final List<BillingSetupModule> modules;
  final ValueChanged<BillingSetupModule> onOpen;

  const _DesktopWorkspace({
    required this.modules,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BillingSetupNavigationPanel(
          modules: modules,
          onModuleSelected: onOpen,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _ModuleGrid(
            modules: modules,
            onOpen: onOpen,
          ),
        ),
        const SizedBox(width: 18),
        BillingSetupPreviewPanel(
          modules: modules,
          width: 318,
        ),
      ],
    );
  }
}

class _CompactWorkspace extends StatelessWidget {
  final List<BillingSetupModule> modules;
  final ValueChanged<BillingSetupModule> onOpen;

  const _CompactWorkspace({
    required this.modules,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModuleGrid(
          modules: modules,
          onOpen: onOpen,
        ),
        const SizedBox(height: 18),
        BillingSetupPreviewPanel(modules: modules),
      ],
    );
  }
}

class _ModuleGrid extends StatelessWidget {
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
        final columns = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 314,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return BillingSetupModuleCard(
              module: module,
              onOpen: () => onOpen(module),
            );
          },
        );
      },
    );
  }
}
