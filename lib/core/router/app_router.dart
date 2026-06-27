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
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_routes.dart';
import '../../theme/dashboard/app/uv.dart';

import '../../ui/auth/login_screen.dart';

import '../../ui/dashboard/dashboard_screen.dart';

import '../../ui/settings/settings_dashboard/settings_screen.dart';
import '../../ui/settings/print_templates/print_templates_screen.dart';
import '../../features/settings/billing_setup/presentation/screens/billing_setup_workspace_screen.dart';

import '../../ui/sales_orders/sales_pos/pos_master_sale_screen.dart';
import '../../ui/booking_advance/booking_advance_screen.dart';
import '../../ui/sales_orders/delivery/delivery_management_screen.dart';

import '../../ui/stock/add_stock/add_stock_hub_screen.dart';
import '../../ui/stock/inventory/inventory_screen.dart';

import '../../ui/customer/customer_list/customer_list_screen.dart';
import '../../ui/customer/add_customer/add_customer_screen.dart';
import '../../ui/customer/customer_profile/customer_profile_screen.dart';
import '../../ui/customer/defaulter/defaulter_list_screen.dart';

import '../../ui/stock/supplier/supplier_list/supplier_list_screen.dart';
import '../../ui/stock/supplier/add_supplier/add_supplier_screen.dart';
import '../../ui/stock/supplier/supplier_profile/supplier_profile_screen.dart';

import '../../ui/purchase_orders/purchase_entry/purchase_entry_screen.dart';

import '../../ui/finance/cash_book/cash_book_screen.dart';
import '../../ui/finance/bank_book/bank_book_screen.dart';
import '../../ui/finance/due_collection_entry/due_collection_entry_screen.dart';
import '../../ui/finance/due_report/due_report_screen.dart';
import '../../ui/finance/due_receipt_history/due_receipt_history_screen.dart';
import '../../ui/finance/expense/expense_screen.dart';

import '../../ui/karigar/issue_karigar/issue_karigar_screen.dart';
import '../../ui/karigar/receive_karigar/receive_karigar_screen.dart';
import '../../ui/karigar/pending_jobs/pending_jobs_screen.dart';
import '../../ui/karigar/karigar_hisaab/karigar_hisaab_screen.dart';

import '../../ui/girvi/new_girvi/new_girvi_screen.dart';
import '../../ui/girvi/girvi_account/girvi_account_detail_screen.dart';
import '../../ui/girvi/girvi_list/girvi_list_screen.dart';
import '../../ui/girvi/interest_calc/interest_calc_screen.dart';
import '../../ui/girvi/notice_auction/notice_auction_screen.dart';

import '../../ui/report/day_book/day_book_screen.dart';

import '../../ui/layout/app_shell.dart';

final _authNotifier = ValueNotifier<bool>(false);
final _rootNavigatorKey = GlobalKey<NavigatorState>();

void _goBackOr(BuildContext context, String fallbackPath) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final currentPath = GoRouterState.of(context).uri.toString();
  context.go(currentPath == fallbackPath ? RoutePaths.dashboard : fallbackPath);
}

/// Call this once during app bootstrap (main.dart) to wire Firebase auth
/// state changes into the router's refreshListenable.
void initAuthRouting() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    _authNotifier.value = user != null;
  });
}

class _ComingSoonScreen extends StatelessWidget {
  final String pageTitle;
  const _ComingSoonScreen({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 60,
            color: UV.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text('Under Construction',
              style: UV.styles.h2.copyWith(color: UV.colors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: UV.colors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pageTitle,
              style: UV.styles.body.copyWith(
                color: UV.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. ROUTER FACTORY

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = _authNotifier.value;
      final isLoginRoute = state.matchedLocation == RoutePaths.login;

      if (!isLoggedIn && !isLoginRoute) {
        return RoutePaths.login;
      }

      if (isLoggedIn && isLoginRoute) {
        return RoutePaths.dashboard;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.girviNew,
        builder: (context, state) {
          final editLoanId = int.tryParse(
            state.uri.queryParameters['editLoanId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return NewGirviScreen(
            editLoanId: editLoanId,
            onBack: () {
              if (returnCustomerId != null) {
                context.go(RoutePaths.customerProfileFor(returnCustomerId));
                return;
              }
              context.go(RoutePaths.dashboard);
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.girviInterest,
        builder: (context, state) {
          final returnTo = state.uri.queryParameters['returnTo'];
          return InterestCalcScreen(
            initialTicketNo: state.uri.queryParameters['ticketNo'],
            onBack: () {
              if (returnTo == 'riskCollections') {
                context.go(RoutePaths.customerDefaulters);
                return;
              }
              if (returnTo == 'girviNotice') {
                context.go(RoutePaths.girviNotice);
                return;
              }
              if (returnTo == 'girviLedger') {
                context.go(RoutePaths.girviList);
                return;
              }
              context.go(RoutePaths.dashboard);
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.girviList,
        builder: (context, state) => GirviListScreen(
          onBack: () => context.go(RoutePaths.dashboard),
          onNewGirvi: () => context.go(RoutePaths.girviNew),
        ),
      ),
      GoRoute(
        path: RoutePaths.girviAccountDetail,
        builder: (context, state) {
          final loanId =
              int.tryParse(state.pathParameters['loanId'] ?? '') ?? 0;
          final returnTo = state.uri.queryParameters['returnTo'];
          return GirviAccountDetailScreen(
            loanId: loanId,
            returnTo: returnTo,
            onBack: () {
              if (returnTo == 'riskCollections') {
                context.go(RoutePaths.customerDefaulters);
                return;
              }
              if (returnTo == 'girviNotice') {
                context.go(RoutePaths.girviNotice);
                return;
              }
              context.go(RoutePaths.girviList);
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.customerDefaulters,
        builder: (context, state) => DefaulterListScreen(
          onBack: () => context.go(RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.girviNotice,
        builder: (context, state) => NoticeAuctionScreen(
          initialTicketNo: state.uri.queryParameters['ticketNo'],
          onBack: () => context.go(RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.salesPos,
        builder: (context, state) {
          final editBillId = int.tryParse(
            state.uri.queryParameters['editBillId'] ?? '',
          );
          final convertAdvanceId = int.tryParse(
            state.uri.queryParameters['convertAdvanceId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return PosMasterSaleScreen(
            editBillId: editBillId,
            convertAdvanceId: convertAdvanceId,
            onBack: () {
              if (returnCustomerId != null) {
                context.go(RoutePaths.customerProfileFor(returnCustomerId));
                return;
              }
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.dashboard);
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.salesBooking,
        builder: (context, state) {
          final editAdvanceId = int.tryParse(
            state.uri.queryParameters['editAdvanceId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return BookingAdvanceScreen(
            editOrderId: editAdvanceId,
            onBack: () {
              if (returnCustomerId != null) {
                context.go(RoutePaths.customerProfileFor(returnCustomerId));
                return;
              }
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.salesPos);
            },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => DashboardScreen(
              onNavigate: (routeId) => context.go(RouteMapper.toPath(routeId)),
              onNavigateWithId: (routeId, {customerId}) {
                if (routeId == AppRoutes.customerProfileRoute &&
                    customerId != null) {
                  context.go(RoutePaths.customerProfileFor(customerId));
                } else {
                  context.go(RouteMapper.toPath(routeId));
                }
              },
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => SettingsScreen(
              onNavigate: (routeId) => context.go(RouteMapper.toPath(routeId)),
            ),
          ),
          GoRoute(
            path: RoutePaths.printTemplates,
            builder: (context, state) => const PrintTemplatesScreen(),
          ),
          GoRoute(
            path: RoutePaths.customerList,
            builder: (context, state) => CustomerListScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onAddCustomer: () => context.go(RoutePaths.customerAdd),
              onCustomerTap: (customerId) =>
                  context.go(RoutePaths.customerProfileFor(customerId)),
            ),
          ),
          GoRoute(
            path: RoutePaths.customerAdd,
            builder: (context, state) => AddCustomerScreen(
              onBack: () => _goBackOr(context, RoutePaths.customerList),
              onSaved: () => context.go(RoutePaths.customerList),
            ),
          ),
          GoRoute(
            path: RoutePaths.customerProfile,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CustomerProfileScreen(
                customerId: id,
                onBack: () => _goBackOr(context, RoutePaths.customerList),
                onDeleted: () => context.go(RoutePaths.customerList),
                onNewSale: (_) => context.go(RoutePaths.salesPos),
                onEditBill: (billId) => context.go(
                  Uri(
                    path: RoutePaths.salesPos,
                    queryParameters: {
                      'editBillId': '$billId',
                      'returnCustomerId': '$id',
                    },
                  ).toString(),
                ),
                onEditGirvi: (loanId) => context.go(
                  Uri(
                    path: RoutePaths.girviNew,
                    queryParameters: {
                      'editLoanId': '$loanId',
                      'returnCustomerId': '$id',
                    },
                  ).toString(),
                ),
                onEditAdvance: (orderId) => context.go(
                  Uri(
                    path: RoutePaths.salesBooking,
                    queryParameters: {
                      'editAdvanceId': '$orderId',
                      'returnCustomerId': '$id',
                    },
                  ).toString(),
                ),
                onConvertAdvanceToSale: (orderId, customerId) => context.go(
                  Uri(
                    path: RoutePaths.salesPos,
                    queryParameters: {
                      'convertAdvanceId': '$orderId',
                      'returnCustomerId': '$customerId',
                    },
                  ).toString(),
                ),
                onCollectDue: (customerId, billNo) => context.go(
                  Uri(
                    path: RoutePaths.financeDueCollection,
                    queryParameters: {
                      'customerId': '$customerId',
                      'billNo': billNo,
                      'returnCustomerId': '$customerId',
                    },
                  ).toString(),
                ),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.supplierList,
            builder: (context, state) => SupplierListScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onAddSupplier: () => context.go(RoutePaths.supplierAdd),
              onSupplierTap: (supplierId) =>
                  context.go(RoutePaths.supplierProfileFor(supplierId)),
            ),
          ),
          GoRoute(
            path: RoutePaths.supplierAdd,
            builder: (context, state) => AddSupplierScreen(
              onBack: () => _goBackOr(context, RoutePaths.supplierList),
              onSaved: () => context.go(RoutePaths.supplierList),
            ),
          ),
          GoRoute(
            path: RoutePaths.supplierProfile,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return SupplierProfileScreen(
                supplierId: id,
                onBack: () => _goBackOr(context, RoutePaths.supplierList),
                onDeleted: () => context.go(RoutePaths.supplierList),
                onNewStock: () => context.go(RoutePaths.stockAdd),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.salesDelivery,
            builder: (context, state) => DeliveryManagementScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.purchaseEntry,
            builder: (_, __) => const PurchaseEntryScreen(),
          ),
          GoRoute(
            path: RoutePaths.purchaseOldGold,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.oldGoldBuyRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.purchaseReturn,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.purchaseReturnRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockInventory,
            builder: (context, state) => InventoryScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockAdd,
            builder: (_, __) => const AddStockHubScreen(),
          ),
          GoRoute(
            path: RoutePaths.stockBarcode,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.barcodePrintRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockTransfer,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.stockTransferRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockLowAlert,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.lowStockAlertRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.karigarIssue,
            builder: (_, __) => const IssueKarigarScreen(),
          ),
          GoRoute(
            path: RoutePaths.karigarReceive,
            builder: (context, state) {
              final issueId = state.uri.queryParameters['issueId'];
              return ReceiveKarigarScreen(
                preSelectedIssueId:
                    issueId != null ? int.tryParse(issueId) : null,
              );
            },
          ),
          GoRoute(
            path: RoutePaths.karigarPending,
            builder: (context, state) => PendingJobsScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onReceiveGoods: (issueId) =>
                  context.go('${RoutePaths.karigarReceive}?issueId=$issueId'),
            ),
          ),
          GoRoute(
            path: RoutePaths.karigarLedger,
            builder: (context, state) => KarigarHisaabScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.financeCashBook,
            builder: (_, __) => const CashBookScreen(),
          ),
          GoRoute(
            path: RoutePaths.financeBankBook,
            builder: (_, __) => const BankBookScreen(),
          ),
          GoRoute(
            path: RoutePaths.financeExpense,
            builder: (context, state) => ExpenseScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.financeJournal,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.journalEntryRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.financeDueReport,
            builder: (context, state) => DueReportScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.financeDueCollection,
            builder: (context, state) {
              final initialCustomerId = int.tryParse(
                state.uri.queryParameters['customerId'] ?? '',
              );
              final returnCustomerId = int.tryParse(
                state.uri.queryParameters['returnCustomerId'] ?? '',
              );
              final initialBillNo = state.uri.queryParameters['billNo'];

              return DueCollectionEntryScreen(
                initialCustomerId: initialCustomerId,
                initialBillNo: initialBillNo,
                onBack: () {
                  if (returnCustomerId != null) {
                    context.go(RoutePaths.customerProfileFor(returnCustomerId));
                    return;
                  }
                  _goBackOr(context, RoutePaths.dashboard);
                },
              );
            },
          ),
          GoRoute(
            path: RoutePaths.financeDueReceipts,
            builder: (context, state) => DueReceiptHistoryScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportDayBook,
            builder: (context, state) => DayBookScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportSales,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.salesReportRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportPurchase,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.purchaseReportRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportStock,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.stockSummaryRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportPnl,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.profitLossRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.reportGst,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.gstReportRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.schemesNew,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.newSchemeRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.schemesCollection,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.monthlyCollectionRoute),
            ),
          ),
          GoRoute(
            path: RoutePaths.billingSetup,
            builder: (context, state) => const BillingSetupWorkspaceScreen(),
          ),
          GoRoute(
            path: RoutePaths.accountProfile,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.accountProfileRoute),
            ),
          ),
        ],
      ),
    ],
  );
}
