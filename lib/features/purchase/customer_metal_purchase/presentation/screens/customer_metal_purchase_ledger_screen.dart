import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/screens/customer_metal_purchase_metal_detail_screen.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_card_grid.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
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
  late final CustomerMetalPurchaseLedgerController _ledgerController;

  @override
  void initState() {
    super.initState();
    _ledgerController = CustomerMetalPurchaseLedgerController();
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
    _ledgerController.dispose();
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
        child: ListenableBuilder(
          listenable: _ledgerController,
          builder: (context, _) {
            if (_ledgerController.isLoading &&
                _ledgerController.entries.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: PurchaseEntryColors.brandGold,
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                children: [
                  if (_ledgerController.error != null) ...[
                    const CustomerMetalPurchaseEmptyState(
                      message:
                          'Unable to load customer metal settlement records.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomerMetalPurchaseCardGrid(
                    animationController: _cardAnimationController,
                    summaries: _ledgerController.metalSummaries,
                    onMetalSelected: _openMetalDetail,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openMetalDetail(CustomerMetalPurchaseMetal metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) {
          return CustomerMetalPurchaseMetalDetailScreen(
            metal: metal,
            controller: _ledgerController,
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
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
