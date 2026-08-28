import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_report_workspace.dart';
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
        title: 'Customer Metal Purchase Report',
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

            if (_ledgerController.error != null) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CustomerMetalPurchaseEmptyState(
                  message: 'Unable to load customer metal purchase records.',
                ),
              );
            }

            return CustomerMetalPurchaseReportWorkspace(
              controller: _ledgerController,
              animationController: _cardAnimationController,
              onOpenVoucher: _openSourceDocument,
            );
          },
        ),
      ),
    );
  }

  void _openSourceDocument(CustomerMetalPurchaseEntry entry) {
    final source = entry.source.toLowerCase();
    if (source.contains('trade') || source.contains('exchange')) {
      context.push(
        Uri(
          path: RoutePaths.salesPos,
          queryParameters: {'editBillId': '${entry.sourceDocumentId}'},
        ).toString(),
      );
      return;
    }

    context.push(
      Uri(
        path: RoutePaths.purchaseEntry,
        queryParameters: {'voucherId': '${entry.sourceDocumentId}'},
      ).toString(),
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
