// =============================================================================
// FILE        : main_layout_wrapper.dart
// LAYER       : UI / Layout
// DESCRIPTION : Central navigation shell.
//
// CHANGELOG:
//   v1 — Initial shell
//   v2 — cashBookRoute wired to CashBookScreen
//   v3 — Karigar module all 4 routes wired
//   v4 — karigarHisaabRoute renamed to karigarLedgerRoute (route fix)
//        Finance & Ledgers comment updated (renamed from Accounts & GST)
//   v5 — bankBookRoute wired to BankBookScreen
//   v6 — Girvi module all 4 routes wired:
//          newGirviRoute      → NewGirviScreen
//          girviReleaseRoute  → GirviListScreen (release happens inside)
//          interestCalcRoute  → InterestCalcScreen
//          noticeAuctionRoute → NoticeAuctionScreen
//   v7 — Supplier module wired:
//          supplierListRoute → SupplierListScreen
//          addSupplierRoute  → AddSupplierScreen
//   v8 — ✅ Expense Entry module wired:
//          expenseEntryRoute → ExpenseScreen
//   v9 — ✅ Day Book module wired:
//          dayBookRoute → DayBookScreen
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/dashboard/app/uv.dart';
import '../../../constants/app_routes.dart';
import 'sidebar/custom_sidebar.dart';

// DASHBOARD
import '../dashboard/dashboard_screen.dart';

// SETTINGS
import '../settings/settings_dashboard/settings_screen.dart';

// SALES
import '../../ui/sales & orders/sales_pos/pos_master_sale_screen.dart';

// BOOKING
import '../booking_advance/booking_advance_screen.dart';

// STOCK
import '../stock/add_stock/add_stock_screen.dart';
import '../stock/inventory/inventory_screen.dart';

// CUSTOMER
import '../customer/customer_list/customer_list_screen.dart';
import '../customer/add_customer/add_customer_screen.dart';
import '../customer/customer_profile/customer_profile_screen.dart';
import '../customer/defaulter/defaulter_list_screen.dart';

// ✅ v7: SUPPLIER MODULE
import '../stock/supplier/supplier_list/supplier_list_screen.dart';
import '../stock/supplier/add_supplier/add_supplier_screen.dart';

// PURCHASE
import '../purchase & orders/purchase_entry/purchase_entry_screen.dart';

// FINANCE & LEDGERS
import '../finance/cash_book/cash_book_screen.dart';
import '../finance/bank_book/bank_book_screen.dart';
import '../finance/expense/expense_screen.dart'; // ✅ v8: Expense Entry

// KARIGAR MODULE
import '../karigar/issue_karigar/issue_karigar_screen.dart';
import '../karigar/receive_karigar/receive_karigar_screen.dart';
import '../karigar/pending_jobs/pending_jobs_screen.dart';
import '../karigar/karigar_hisaab/karigar_hisaab_screen.dart';

// ✅ v6: GIRVI MODULE
import '../girvi/new_girvi/new_girvi_screen.dart';
import '../girvi/girvi_list/girvi_list_screen.dart';
import '../girvi/interest_calc/interest_calc_screen.dart';
import '../girvi/notice_auction/notice_auction_screen.dart';

// ✅ v9: REPORTS MODULE
import '../report/day_book/day_book_screen.dart';

class MainLayoutWrapper extends StatefulWidget {
  const MainLayoutWrapper({super.key});

  @override
  State<MainLayoutWrapper> createState() => _MainLayoutWrapperState();
}

class _MainLayoutWrapperState extends State<MainLayoutWrapper> {
  String _activePageRouteId = AppRoutes.dashboardRoute;
  int? _activeCustomerId;

  // ── Central Navigation Controller ────────────────────────────────────────

  // ✅ NEW: customerId ke saath navigate — Payment Status → Customer Profile
  void _navigateToWithId(String routeId, {int? customerId}) {
    if (routeId == AppRoutes.customerProfileRoute && customerId != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerProfileScreen(
                    customerId: customerId,
                    onBack: () => Navigator.pop(context),
                    onDeleted: () => Navigator.pop(context),
                    onNewSale: (_) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PosMasterSaleScreen()));
                    },
                  )));
    } else {
      _navigateTo(routeId);
    }
  }

  void _navigateTo(String routeId) {
    if (routeId == AppRoutes.newSaleRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PosMasterSaleScreen()));
    } else if (routeId == AppRoutes.bookingAdvanceRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookingAdvanceScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    } else if (routeId == AppRoutes.defaulterListRoute) {
      Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const DefaulterListScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ));
    } else if (routeId == AppRoutes.customerListRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerListScreen(
                    onBack: () => Navigator.pop(context),
                    onAddCustomer: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddCustomerScreen(
                                    onBack: () => Navigator.pop(context),
                                    onSaved: () => Navigator.pop(context),
                                  )));
                    },
                    onCustomerTap: (customerId) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CustomerProfileScreen(
                                    customerId: customerId,
                                    onBack: () => Navigator.pop(context),
                                    onDeleted: () => Navigator.pop(context),
                                    onNewSale: (_) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const PosMasterSaleScreen()));
                                    },
                                  )));
                    },
                  )));
    } else if (routeId == AppRoutes.addCustomerRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddCustomerScreen(
                    onBack: () => Navigator.pop(context),
                    onSaved: () => Navigator.pop(context),
                  )));
    }

    // ── ✅ v7: SUPPLIER MODULE ─────────────────────────────────────────────────

    else if (routeId == AppRoutes.supplierListRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SupplierListScreen(
                    onBack: () => Navigator.pop(context),
                    onAddSupplier: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddSupplierScreen(
                                    onBack: () => Navigator.pop(context),
                                    onSaved: () => Navigator.pop(context),
                                  )));
                    },
                    onSupplierTap: (supplierId) {
                      // TODO: SupplierProfileScreen — coming soon
                    },
                  )));
    } else if (routeId == AppRoutes.addSupplierRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddSupplierScreen(
                    onBack: () => Navigator.pop(context),
                    onSaved: () => Navigator.pop(context),
                  )));
    }

    // ── STOCK ─────────────────────────────────────────────────────────────────

    else if (routeId == AppRoutes.addStockRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddStockScreen()));
    } else if (routeId == AppRoutes.inventoryRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => InventoryScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    } else if (routeId == AppRoutes.purchaseEntryRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PurchaseEntryScreen()));
    }

    // ── FINANCE & LEDGERS ─────────────────────────────────────────────────────

    else if (routeId == AppRoutes.cashBookRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CashBookScreen()));
    } else if (routeId == AppRoutes.bankBookRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BankBookScreen()));
    } else if (routeId == AppRoutes.expenseEntryRoute) {
      // ✅ v8
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ExpenseScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    }

    // ── KARIGAR MODULE ────────────────────────────────────────────────────────

    else if (routeId == AppRoutes.issueToKarigarRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const IssueKarigarScreen()));
    } else if (routeId == AppRoutes.receiveFromKarigarRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ReceiveKarigarScreen()));
    } else if (routeId == AppRoutes.pendingJobsRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PendingJobsScreen(
                    onBack: () => Navigator.pop(context),
                    onReceiveGoods: (issueId) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ReceiveKarigarScreen(
                                    preSelectedIssueId: issueId,
                                  )));
                    },
                  )));
    } else if (routeId == AppRoutes.karigarLedgerRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => KarigarHisaabScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    }

    // ── ✅ v6: GIRVI MODULE ───────────────────────────────────────────────────

    else if (routeId == AppRoutes.newGirviRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const NewGirviScreen()));
    } else if (routeId == AppRoutes.girviReleaseRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GirviListScreen(
                    onBack: () => Navigator.pop(context),
                    onNewGirvi: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NewGirviScreen()));
                    },
                  )));
    } else if (routeId == AppRoutes.interestCalcRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const InterestCalcScreen()));
    } else if (routeId == AppRoutes.noticeAuctionRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NoticeAuctionScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    }

    // ── ✅ v9: REPORTS MODULE ─────────────────────────────────────────────────

    else if (routeId == AppRoutes.dayBookRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DayBookScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    } else {
      setState(() {
        _activePageRouteId = routeId;
        _activeCustomerId = null;
      });
    }
  }

  // ── Page Content Switcher ─────────────────────────────────────────────────

  Widget _getPageContent(String routeId) {
    switch (routeId) {
      case AppRoutes.dashboardRoute:
        return DashboardScreen(
          onNavigate: (route) => _navigateTo(route),
          // ✅ FIX: customerId ab pass hoga — Payment Status → Customer Profile
          onNavigateWithId: (routeId, {int? customerId}) =>
              _navigateToWithId(routeId, customerId: customerId),
        );
      case AppRoutes.settingsRoute:
        return SettingsScreen(
          onNavigate: (routeId) => _navigateTo(routeId),
        );
      default:
        return _ComingSoonWidget(pageTitle: AppRoutes.getTitle(routeId));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: UV.colors.bgPrimary,
      drawer: isSmallScreen
          ? Drawer(child: _buildSidebarLogic(context, isMobile: true))
          : null,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: UV.colors.bgPrimary,
              title: Text(
                'LOTUS ERP',
                style: UV.styles.hero.copyWith(fontSize: 20),
              ),
              centerTitle: true,
              iconTheme: IconThemeData(color: UV.colors.textPrimary),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: UV.colors.glassBorder, height: 1),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen) _buildSidebarLogic(context, isMobile: false),
          Expanded(
            child: Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: UV.colors.bgSecondary.withOpacity(0.5),
                border: Border(
                  left: BorderSide(color: UV.colors.glassBorder, width: 1),
                ),
                boxShadow: [
                  if (!isSmallScreen)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(-4, 0),
                    ),
                ],
              ),
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  child: KeyedSubtree(
                    key: ValueKey(
                        '$_activePageRouteId-${_activeCustomerId ?? ""}'),
                    child: _getPageContent(_activePageRouteId),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────

  Widget _buildSidebarLogic(BuildContext context, {required bool isMobile}) {
    return CustomSidebar(
      activePageRouteId: _activePageRouteId,
      onPageSelected: (routeId) {
        if (routeId == AppRoutes.exitAppRoute) {
          if (Platform.isAndroid || Platform.isIOS) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
        } else {
          _navigateTo(routeId);
          if (isMobile) Navigator.pop(context);
        }
      },
    );
  }
}

// ── Coming Soon Widget ─────────────────────────────────────────────────────────

class _ComingSoonWidget extends StatelessWidget {
  final String pageTitle;
  const _ComingSoonWidget({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 60,
            color: UV.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text('Under Construction',
              style: UV.styles.h2.copyWith(color: UV.colors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: UV.colors.textSecondary.withOpacity(0.1),
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
