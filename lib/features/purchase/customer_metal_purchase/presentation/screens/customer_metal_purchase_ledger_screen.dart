import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_card_grid.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseLedgerScreen extends StatefulWidget {
  const CustomerMetalPurchaseLedgerScreen({super.key});

  @override
  State<CustomerMetalPurchaseLedgerScreen> createState() =>
      _CustomerMetalPurchaseLedgerScreenState();
}

class _CustomerMetalPurchaseLedgerScreenState
    extends State<CustomerMetalPurchaseLedgerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cardAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        onBack: () => _handleBack(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: CustomerMetalPurchaseCardGrid(
            animationController: _cardAnimationController,
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.dashboard);
  }
}
