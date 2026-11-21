// =============================================================================
// FILE        : app_router.dart
// LAYER       : Core / Router
// DESCRIPTION : Declarative go_router configuration for Lotus ERP.
//               Replaces the 518-line if-else God Class in MainLayoutWrapper.
//
// ARCHITECTURE:
//     ... (all 40+ routes)
//
// CHANGELOG:
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import 'notice_recovery_navigation.dart';
import 'payment_status_navigation.dart';
import 'workspace_navigation.dart';
import 'workspace_transition_page.dart';
import 'workspace_route.dart';

import '../../ui/auth/login_screen.dart';
import '../../ui/auth/auth_gate_screen.dart';
import '../../ui/auth/services/auth_session_controller.dart';

import '../../ui/dashboard/dashboard_screen.dart';
import '../../ui/settings/metal_rate/metal_rate_hub_screen.dart';

import '../../ui/settings/settings_dashboard/settings_screen.dart';
import '../../ui/settings/account_profile/account_profile_screen.dart';
import '../../ui/settings/print_templates/print_templates_screen.dart';
import '../../features/settings/metal_cost_analyser/presentation/metal_valuation_desk_screen.dart';
import '../../features/settings/metal_cost_analyser/presentation/metal_valuation_batch_detail_screen.dart';
import '../../features/settings/metal_cost_analyser/presentation/metal_valuation_grade_screen.dart';
import '../../features/settings/billing_setup/presentation/screens/billing_setup_workspace_screen.dart';

import '../../ui/sales_orders/sales_pos/pos_master_sale_screen.dart';
import '../../ui/booking_advance/booking_advance_screen.dart';
import '../../features/sales/return_reversal/presentation/screens/return_reversal_desk_screen.dart';

import 'package:lotus_erp/features/stock/shared/presentation/add_stock/add_stock_hub_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/inventory_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/low_stock_alert_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_activity/stock_activity_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_search/stock_search_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_summary/stock_summary_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/stock_transfer_screen.dart';

import '../../ui/customer/customer_list/customer_list_screen.dart';
import '../../ui/customer/add_customer/add_customer_screen.dart';
import '../../ui/customer/customer_profile/customer_profile_screen.dart';
import '../../ui/customer/defaulter/defaulter_list_screen.dart';

import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_list/supplier_list_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/add_supplier/add_supplier_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_profile/supplier_profile_screen.dart';

import '../../ui/purchase_orders/purchase_entry/purchase_entry_screen.dart';

import '../../ui/finance/account_book/account_book_screen.dart';
import '../../ui/finance/cash_book/cash_book_screen.dart';
import '../../ui/finance/bank_book/bank_book_screen.dart';
import '../../ui/finance/due_collection_entry/due_collection_entry_screen.dart';
import '../../ui/finance/due_report/due_report_screen.dart';
import '../../ui/finance/due_receipt_history/due_receipt_history_screen.dart';
import '../../ui/finance/expense/expense_screen.dart';
import '../../models/finance/expense/expense_draft.dart';

import '../../ui/girvi/new_girvi/new_girvi_screen.dart';
import '../../ui/girvi/girvi_account/girvi_account_detail_screen.dart';
import '../../ui/girvi/girvi_list/girvi_list_screen.dart';
import '../../ui/girvi/interest_calc/interest_calc_screen.dart';
import '../../ui/girvi/contact_recovery/contact_recovery_screen.dart';

import '../../ui/report/day_book/day_book_screen.dart';
import '../../ui/report/sales_report/sales_report_screen.dart';
import '../../features/reports/gst_report/presentation/screens/gst_report_hub_screen.dart';

import '../../ui/layout/app_shell.dart';
import '../../features/purchase/customer_metal_purchase/presentation/screens/customer_metal_checkout_report_screen.dart';
import '../../features/purchase/customer_metal_purchase/presentation/screens/customer_metal_purchase_ledger_screen.dart';
import '../../features/purchase/customer_metal_purchase/presentation/screens/customer_metal_purchase_voucher_detail_screen.dart';

part 'routes/standalone_pledge_routes.dart';
part 'routes/standalone_sales_routes.dart';
part 'routes/standalone_stock_routes.dart';
part 'routes/dashboard_settings_routes.dart';
part 'routes/customer_routes.dart';
part 'routes/supplier_sales_routes.dart';
part 'routes/inventory_routes.dart';
part 'routes/finance_routes.dart';
part 'routes/report_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

void _goBackOr(BuildContext context, String fallbackPath) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final currentPath = GoRouterState.of(context).uri.toString();
  context.go(currentPath == fallbackPath ? RoutePaths.dashboard : fallbackPath);
}

void initAuthRouting() {
  AuthSessionController.instance.start();
}

// 5. ROUTER FACTORY

GoRouter createAppRouter() {
  final session = AuthSessionController.instance;
  final moduleRoutes = <RouteBase>[
    ...dashboardSettingsRoutes(),
    ...customerRoutes(),
    ...supplierSalesRoutes(),
    ...inventoryRoutes(),
    ...financeRoutes(),
    ...reportRoutes(),
  ];
  // Full-window routes belong on the root, outside the shell's navigator.
  final rootWorkspaces = moduleRoutes.where((route) =>
      route is GoRoute && route.parentNavigatorKey == _rootNavigatorKey);
  final shellRoutes = moduleRoutes
      .where((route) =>
          route is! GoRoute || route.parentNavigatorKey != _rootNavigatorKey)
      .toList();
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    refreshListenable: session,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == RoutePaths.login;
      final isCheckRoute = state.matchedLocation == RoutePaths.authCheck;

      return switch (session.status) {
        AuthSessionStatus.checking ||
        AuthSessionStatus.unavailable =>
          isCheckRoute ? null : RoutePaths.authCheck,
        AuthSessionStatus.signedOut => isLoginRoute ? null : RoutePaths.login,
        AuthSessionStatus.authorized =>
          isLoginRoute || isCheckRoute ? RoutePaths.dashboard : null,
      };
    },
    routes: [
      GoRoute(
        path: RoutePaths.authCheck,
        builder: (_, __) => const AuthGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ...standalonePledgeRoutes(),
      ...standaloneSalesRoutes(),
      ...standaloneStockRoutes(),
      ...rootWorkspaces,
      ShellRoute(
        pageBuilder: (context, state, child) => WorkspaceTransitionPage(
          key: state.pageKey,
          child: AppShell(child: child),
        ),
        routes: shellRoutes,
      ),
    ],
  );
}
