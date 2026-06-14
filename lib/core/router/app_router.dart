// =============================================================================
// FILE        : app_router.dart
// LAYER       : Core / Router
// DESCRIPTION : Declarative go_router configuration for Lotus ERP.
//               Replaces the 518-line if-else God Class in MainLayoutWrapper.
//
// ARCHITECTURE:
//   /login                    → LoginScreen (standalone, no sidebar)
//   /app                      → ShellRoute with AppShell (sidebar + content)
//     /app/dashboard          → DashboardScreen
//     /app/settings           → SettingsScreen
//     /app/customer/list      → CustomerListScreen
//     /app/customer/add       → AddCustomerScreen
//     /app/customer/profile/:id → CustomerProfileScreen
//     ... (all 40+ routes)
//
// CHANGELOG:
//   v1 — Extracted from MainLayoutWrapper. Zero if-else navigation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_routes.dart';
import '../../theme/dashboard/app/uv.dart';

// ── AUTH ────────────────────────────────────────────────────────────────────
import '../../ui/auth/login_screen.dart';

// ── DASHBOARD ─────────────────────────────────────────────────────────────────
import '../../ui/dashboard/dashboard_screen.dart';

// ── SETTINGS ──────────────────────────────────────────────────────────────────
import '../../ui/settings/settings_dashboard/settings_screen.dart';

// ── SALES & ORDERS ────────────────────────────────────────────────────────────
import '../../ui/sales & orders/sales_pos/pos_master_sale_screen.dart';
import '../../ui/booking_advance/booking_advance_screen.dart';
import '../../ui/sales & orders/delivery/delivery_management_screen.dart';

// ── STOCK ─────────────────────────────────────────────────────────────────────
import '../../ui/stock/add_stock/add_stock_hub_screen.dart';
import '../../ui/stock/inventory/inventory_screen.dart';

// ── CUSTOMER ──────────────────────────────────────────────────────────────────
import '../../ui/customer/customer_list/customer_list_screen.dart';
import '../../ui/customer/add_customer/add_customer_screen.dart';
import '../../ui/customer/customer_profile/customer_profile_screen.dart';
import '../../ui/customer/defaulter/defaulter_list_screen.dart';

// ── SUPPLIER ──────────────────────────────────────────────────────────────────
import '../../ui/stock/supplier/supplier_list/supplier_list_screen.dart';
import '../../ui/stock/supplier/add_supplier/add_supplier_screen.dart';
import '../../ui/stock/supplier/supplier_profile/supplier_profile_screen.dart';

// ── PURCHASE ────────────────────────────────────────────────────────────────────
import '../../ui/purchase & orders/purchase_entry/purchase_entry_screen.dart';

// ── FINANCE ─────────────────────────────────────────────────────────────────────
import '../../ui/finance/cash_book/cash_book_screen.dart';
import '../../ui/finance/bank_book/bank_book_screen.dart';
import '../../ui/finance/due_collection_entry/due_collection_entry_screen.dart';
import '../../ui/finance/due_report/due_report_screen.dart';
import '../../ui/finance/due_receipt_history/due_receipt_history_screen.dart';
import '../../ui/finance/expense/expense_screen.dart';

// ── KARIGAR ─────────────────────────────────────────────────────────────────────
import '../../ui/karigar/issue_karigar/issue_karigar_screen.dart';
import '../../ui/karigar/receive_karigar/receive_karigar_screen.dart';
import '../../ui/karigar/pending_jobs/pending_jobs_screen.dart';
import '../../ui/karigar/karigar_hisaab/karigar_hisaab_screen.dart';

// ── GIRVI ───────────────────────────────────────────────────────────────────────
import '../../ui/girvi/new_girvi/new_girvi_screen.dart';
import '../../ui/girvi/girvi_list/girvi_list_screen.dart';
import '../../ui/girvi/interest_calc/interest_calc_screen.dart';
import '../../ui/girvi/notice_auction/notice_auction_screen.dart';

// ── REPORTS ─────────────────────────────────────────────────────────────────────
import '../../ui/report/day_book/day_book_screen.dart';

// ── SHELL ───────────────────────────────────────────────────────────────────────
import '../../ui/layout/app_shell.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. ROUTE PATH CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String app = '/app';

  // Core
  static const String dashboard = '/app/dashboard';
  static const String settings = '/app/settings';
  static const String accountProfile = '/app/account/profile';

  // Settings sub-routes
  static const String billingSetup = '/app/settings/billing-setup';

  // Customer
  static const String customerList = '/app/customer/list';
  static const String customerAdd = '/app/customer/add';
  static const String customerProfile = '/app/customer/profile/:id';
  static const String customerCreditLimit = '/app/customer/credit-limit';
  static const String customerDefaulters = '/app/customer/defaulters';

  // Supplier
  static const String supplierList = '/app/supplier/list';
  static const String supplierAdd = '/app/supplier/add';
  static const String supplierProfile = '/app/supplier/profile/:id';

  // Sales & Orders
  static const String salesPos = '/app/sales/pos';
  static const String salesBooking = '/app/sales/booking';
  static const String salesDelivery = '/app/sales/delivery';

  // Purchase
  static const String purchaseEntry = '/app/purchase/entry';
  static const String purchaseOldGold = '/app/purchase/old-gold';
  static const String purchaseReturn = '/app/purchase/return';

  // Stock
  static const String stockInventory = '/app/stock/inventory';
  static const String stockAdd = '/app/stock/add';
  static const String stockBarcode = '/app/stock/barcode';
  static const String stockTransfer = '/app/stock/transfer';
  static const String stockLowAlert = '/app/stock/low-alert';

  // Karigar
  static const String karigarIssue = '/app/karigar/issue';
  static const String karigarReceive = '/app/karigar/receive';
  static const String karigarPending = '/app/karigar/pending';
  static const String karigarLedger = '/app/karigar/ledger';

  // Girvi
  static const String girviNew = '/app/girvi/new';
  static const String girviList = '/app/girvi/list';
  static const String girviInterest = '/app/girvi/interest';
  static const String girviNotice = '/app/girvi/notice';

  // Finance
  static const String financeCashBook = '/app/finance/cashbook';
  static const String financeBankBook = '/app/finance/bankbook';
  static const String financeExpense = '/app/finance/expense';
  static const String financeJournal = '/app/finance/journal';
  static const String financeDueReport = '/app/finance/due-report';
  static const String financeDueCollection = '/app/finance/due-collection';
  static const String financeDueReceipts = '/app/finance/due-receipts';

  // Reports
  static const String reportDayBook = '/app/reports/daybook';
  static const String reportSales = '/app/reports/sales';
  static const String reportPurchase = '/app/reports/purchase';
  static const String reportStock = '/app/reports/stock';
  static const String reportPnl = '/app/reports/pnl';
  static const String reportGst = '/app/reports/gst';

  // Schemes
  static const String schemesNew = '/app/schemes/new';
  static const String schemesCollection = '/app/schemes/collection';
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. ROUTE MAPPER — AppRoutes ID ↔ go_router path
// ═══════════════════════════════════════════════════════════════════════════════

class RouteMapper {
  RouteMapper._();

  /// Converts an AppRoutes route ID to a go_router path.
  /// Use [entityId] for routes that need a path parameter (e.g., customer profile).
  static String toPath(String routeId, {int? entityId}) {
    switch (routeId) {
      // Core
      case AppRoutes.dashboardRoute:
        return RoutePaths.dashboard;
      case AppRoutes.settingsRoute:
        return RoutePaths.settings;
      case AppRoutes.accountProfileRoute:
        return RoutePaths.accountProfile;

      // Settings
      case AppRoutes.billingSetupRoute:
        return RoutePaths.billingSetup;

      // Customer
      case AppRoutes.customerListRoute:
        return RoutePaths.customerList;
      case AppRoutes.addCustomerRoute:
        return RoutePaths.customerAdd;
      case AppRoutes.customerProfileRoute:
        return entityId != null
            ? '/app/customer/profile/$entityId'
            : RoutePaths.customerList;
      case AppRoutes.creditLimitRoute:
        return RoutePaths.customerCreditLimit;
      case AppRoutes.defaulterListRoute:
        return RoutePaths.customerDefaulters;

      // Supplier
      case AppRoutes.supplierListRoute:
        return RoutePaths.supplierList;
      case AppRoutes.addSupplierRoute:
        return RoutePaths.supplierAdd;

      // Sales
      case AppRoutes.newSaleRoute:
        return RoutePaths.salesPos;
      case AppRoutes.bookingAdvanceRoute:
        return RoutePaths.salesBooking;
      case AppRoutes.deliveryManagementRoute:
        return RoutePaths.salesDelivery;

      // Purchase
      case AppRoutes.purchaseEntryRoute:
        return RoutePaths.purchaseEntry;
      case AppRoutes.oldGoldBuyRoute:
        return RoutePaths.purchaseOldGold;
      case AppRoutes.purchaseReturnRoute:
        return RoutePaths.purchaseReturn;

      // Stock
      case AppRoutes.inventoryRoute:
        return RoutePaths.stockInventory;
      case AppRoutes.addStockRoute:
        return RoutePaths.stockAdd;
      case AppRoutes.barcodePrintRoute:
        return RoutePaths.stockBarcode;
      case AppRoutes.stockTransferRoute:
        return RoutePaths.stockTransfer;
      case AppRoutes.lowStockAlertRoute:
        return RoutePaths.stockLowAlert;

      // Karigar
      case AppRoutes.issueToKarigarRoute:
        return RoutePaths.karigarIssue;
      case AppRoutes.receiveFromKarigarRoute:
        return RoutePaths.karigarReceive;
      case AppRoutes.pendingJobsRoute:
        return RoutePaths.karigarPending;
      case AppRoutes.karigarLedgerRoute:
        return RoutePaths.karigarLedger;

      // Girvi
      case AppRoutes.newGirviRoute:
        return RoutePaths.girviNew;
      case AppRoutes.girviReleaseRoute:
        return RoutePaths.girviList;
      case AppRoutes.interestCalcRoute:
        return RoutePaths.girviInterest;
      case AppRoutes.noticeAuctionRoute:
        return RoutePaths.girviNotice;

      // Finance
      case AppRoutes.cashBookRoute:
        return RoutePaths.financeCashBook;
      case AppRoutes.bankBookRoute:
        return RoutePaths.financeBankBook;
      case AppRoutes.expenseEntryRoute:
        return RoutePaths.financeExpense;
      case AppRoutes.journalEntryRoute:
        return RoutePaths.financeJournal;
      case AppRoutes.dueReportRoute:
        return RoutePaths.financeDueReport;
      case AppRoutes.dueCollectionRoute:
        return RoutePaths.financeDueCollection;
      case AppRoutes.dueReceiptHistoryRoute:
        return RoutePaths.financeDueReceipts;

      // Reports
      case AppRoutes.dayBookRoute:
        return RoutePaths.reportDayBook;
      case AppRoutes.salesReportRoute:
        return RoutePaths.reportSales;
      case AppRoutes.purchaseReportRoute:
        return RoutePaths.reportPurchase;
      case AppRoutes.stockSummaryRoute:
        return RoutePaths.reportStock;
      case AppRoutes.profitLossRoute:
        return RoutePaths.reportPnl;
      case AppRoutes.gstReportRoute:
        return RoutePaths.reportGst;

      // Schemes
      case AppRoutes.newSchemeRoute:
        return RoutePaths.schemesNew;
      case AppRoutes.monthlyCollectionRoute:
        return RoutePaths.schemesCollection;

      default:
        return RoutePaths.dashboard;
    }
  }

  /// Converts a go_router path back to an AppRoutes ID.
  /// Used by the sidebar to highlight the active menu item.
  static String toRouteId(String path) {
    // Remove path parameters for matching
    final cleanPath = path.replaceAll(RegExp(r'/\d+$'), '');

    if (cleanPath == RoutePaths.dashboard) return AppRoutes.dashboardRoute;
    if (cleanPath == RoutePaths.settings) return AppRoutes.settingsRoute;
    if (cleanPath == RoutePaths.billingSetup)
      return AppRoutes.billingSetupRoute;
    if (cleanPath == RoutePaths.customerList ||
        cleanPath.startsWith('/app/customer/profile'))
      return AppRoutes.customerListRoute;
    if (cleanPath == RoutePaths.customerAdd) return AppRoutes.addCustomerRoute;
    if (cleanPath == RoutePaths.customerDefaulters)
      return AppRoutes.defaulterListRoute;
    if (cleanPath == RoutePaths.supplierList)
      return AppRoutes.supplierListRoute;
    if (cleanPath == RoutePaths.supplierAdd) return AppRoutes.addSupplierRoute;
    if (cleanPath == RoutePaths.salesPos) return AppRoutes.newSaleRoute;
    if (cleanPath == RoutePaths.salesBooking)
      return AppRoutes.bookingAdvanceRoute;
    if (cleanPath == RoutePaths.salesDelivery)
      return AppRoutes.deliveryManagementRoute;
    if (cleanPath == RoutePaths.purchaseEntry)
      return AppRoutes.purchaseEntryRoute;
    if (cleanPath == RoutePaths.purchaseOldGold)
      return AppRoutes.oldGoldBuyRoute;
    if (cleanPath == RoutePaths.purchaseReturn)
      return AppRoutes.purchaseReturnRoute;
    if (cleanPath == RoutePaths.stockInventory) return AppRoutes.inventoryRoute;
    if (cleanPath == RoutePaths.stockAdd) return AppRoutes.addStockRoute;
    if (cleanPath == RoutePaths.stockBarcode)
      return AppRoutes.barcodePrintRoute;
    if (cleanPath == RoutePaths.stockTransfer)
      return AppRoutes.stockTransferRoute;
    if (cleanPath == RoutePaths.stockLowAlert)
      return AppRoutes.lowStockAlertRoute;
    if (cleanPath == RoutePaths.karigarIssue)
      return AppRoutes.issueToKarigarRoute;
    if (cleanPath == RoutePaths.karigarReceive)
      return AppRoutes.receiveFromKarigarRoute;
    if (cleanPath == RoutePaths.karigarPending)
      return AppRoutes.pendingJobsRoute;
    if (cleanPath == RoutePaths.karigarLedger)
      return AppRoutes.karigarLedgerRoute;
    if (cleanPath == RoutePaths.girviNew) return AppRoutes.newGirviRoute;
    if (cleanPath == RoutePaths.girviList) return AppRoutes.girviReleaseRoute;
    if (cleanPath == RoutePaths.girviInterest)
      return AppRoutes.interestCalcRoute;
    if (cleanPath == RoutePaths.girviNotice)
      return AppRoutes.noticeAuctionRoute;
    if (cleanPath == RoutePaths.financeCashBook) return AppRoutes.cashBookRoute;
    if (cleanPath == RoutePaths.financeBankBook) return AppRoutes.bankBookRoute;
    if (cleanPath == RoutePaths.financeExpense)
      return AppRoutes.expenseEntryRoute;
    if (cleanPath == RoutePaths.financeJournal)
      return AppRoutes.journalEntryRoute;
    if (cleanPath == RoutePaths.financeDueReport)
      return AppRoutes.dueReportRoute;
    if (cleanPath == RoutePaths.financeDueCollection)
      return AppRoutes.dueCollectionRoute;
    if (cleanPath == RoutePaths.financeDueReceipts)
      return AppRoutes.dueReceiptHistoryRoute;
    if (cleanPath == RoutePaths.reportDayBook) return AppRoutes.dayBookRoute;
    if (cleanPath == RoutePaths.reportSales) return AppRoutes.salesReportRoute;
    if (cleanPath == RoutePaths.reportPurchase)
      return AppRoutes.purchaseReportRoute;
    if (cleanPath == RoutePaths.reportStock) return AppRoutes.stockSummaryRoute;
    if (cleanPath == RoutePaths.reportPnl) return AppRoutes.profitLossRoute;
    if (cleanPath == RoutePaths.reportGst) return AppRoutes.gstReportRoute;
    if (cleanPath == RoutePaths.schemesNew) return AppRoutes.newSchemeRoute;
    if (cleanPath == RoutePaths.schemesCollection)
      return AppRoutes.monthlyCollectionRoute;

    return AppRoutes.dashboardRoute;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. AUTH NOTIFIER — Drives router redirect on login/logout
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// 4. COMING SOON SCREEN — Placeholder for unimplemented routes
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// 5. ROUTER FACTORY
// ═══════════════════════════════════════════════════════════════════════════════

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = _authNotifier.value;
      final isLoginRoute = state.matchedLocation == RoutePaths.login;

      // Not logged in + not on login page → send to login
      if (!isLoggedIn && !isLoginRoute) {
        return RoutePaths.login;
      }

      // Logged in + on login page → send to dashboard
      if (isLoggedIn && isLoginRoute) {
        return RoutePaths.dashboard;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // ── LOGIN (standalone, no sidebar) ───────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),

      // ── APP SHELL (sidebar + content) ────────────────────────────────────────
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
                context.go('/app/customer/profile/$returnCustomerId');
                return;
              }
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.girviList);
            },
          );
        },
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
                context.go('/app/customer/profile/$returnCustomerId');
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
                context.go('/app/customer/profile/$returnCustomerId');
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
          // ── CORE ────────────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => DashboardScreen(
              onNavigate: (routeId) => context.go(RouteMapper.toPath(routeId)),
              onNavigateWithId: (routeId, {customerId}) {
                if (routeId == AppRoutes.customerProfileRoute &&
                    customerId != null) {
                  context.go('/app/customer/profile/$customerId');
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

          // ── CUSTOMER ──────────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.customerList,
            builder: (context, state) => CustomerListScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onAddCustomer: () => context.go(RoutePaths.customerAdd),
              onCustomerTap: (customerId) =>
                  context.go('/app/customer/profile/$customerId'),
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
            path: RoutePaths.customerDefaulters,
            builder: (_, __) => const DefaulterListScreen(),
          ),

          // ── SUPPLIER ──────────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.supplierList,
            builder: (context, state) => SupplierListScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onAddSupplier: () => context.go(RoutePaths.supplierAdd),
              onSupplierTap: (supplierId) =>
                  context.go('/app/supplier/profile/$supplierId'),
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

          // ── SALES & ORDERS ────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.salesDelivery,
            builder: (context, state) => DeliveryManagementScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
            ),
          ),

          // ── PURCHASE ──────────────────────────────────────────────────────────
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

          // ── STOCK ─────────────────────────────────────────────────────────────
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

          // ── KARIGAR ────────────────────────────────────────────────────────────
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

          // ── GIRVI ─────────────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.girviList,
            builder: (context, state) => GirviListScreen(
              onBack: () => _goBackOr(context, RoutePaths.dashboard),
              onNewGirvi: () => context.go(RoutePaths.girviNew),
            ),
          ),

          GoRoute(
            path: RoutePaths.girviInterest,
            builder: (_, __) => const InterestCalcScreen(),
          ),

          GoRoute(
            path: RoutePaths.girviNotice,
            builder: (context, state) => NoticeAuctionScreen(
              onBack: () => _goBackOr(context, RoutePaths.girviList),
            ),
          ),

          // ── FINANCE ────────────────────────────────────────────────────────────
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
                    context.go('/app/customer/profile/$returnCustomerId');
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

          // ── REPORTS ────────────────────────────────────────────────────────────
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

          // ── SCHEMES ──────────────────────────────────────────────────────────────
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

          // ── SETTINGS SUB-ROUTES ────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.billingSetup,
            builder: (context, state) => _ComingSoonScreen(
              pageTitle: AppRoutes.getTitle(AppRoutes.billingSetupRoute),
            ),
          ),

          // ── ACCOUNT ───────────────────────────────────────────────────────────
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
