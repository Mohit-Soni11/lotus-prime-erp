// =============================================================================
// FILE        : main_layout_wrapper.dart
// LAYER       : UI / Layout
// DESCRIPTION : Central navigation shell.
//
// CHANGELOG:
//   v1 â€” Initial shell
//   v2 â€” cashBookRoute wired to CashBookScreen
//   v3 â€” Karigar module all 4 routes wired
//   v4 â€” karigarHisaabRoute renamed to karigarLedgerRoute (route fix)
//        Finance & Ledgers comment updated (renamed from Accounts & GST)
//   v5 â€” bankBookRoute wired to BankBookScreen
//   v6 â€” Girvi module all 4 routes wired
//   v7 â€” Supplier module wired
//   v8 â€” âœ… Expense Entry module wired
//   v9 â€” âœ… Day Book module wired
//   v10 â€” âœ… Delivery Management module wired
//   v11 â€” âœ… Add Stock Route wired to AddStockHubScreen
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

// âœ… v10: DELIVERY MANAGEMENT
import '../sales & orders/delivery/delivery_management_screen.dart';

// STOCK
import '../stock/add_stock/add_stock_hub_screen.dart';
import '../stock/inventory/inventory_screen.dart';

// CUSTOMER
import '../customer/customer_list/customer_list_screen.dart';
import '../customer/add_customer/add_customer_screen.dart';
import '../customer/customer_profile/customer_profile_screen.dart';
import '../customer/defaulter/defaulter_list_screen.dart';

// âœ… v7: SUPPLIER MODULE
import '../stock/supplier/supplier_list/supplier_list_screen.dart';
import '../stock/supplier/add_supplier/add_supplier_screen.dart';
import '../stock/supplier/supplier_profile/supplier_profile_screen.dart';

// PURCHASE
import '../purchase & orders/purchase_entry/purchase_entry_screen.dart';

// FINANCE & LEDGERS
import '../finance/cash_book/cash_book_screen.dart';
import '../finance/bank_book/bank_book_screen.dart';
import '../finance/due_collection_entry/due_collection_entry_screen.dart';
import '../finance/due_report/due_report_screen.dart';
import '../finance/due_receipt_history/due_receipt_history_screen.dart';
import '../finance/expense/expense_screen.dart'; // âœ… v8: Expense Entry

// KARIGAR MODULE
import '../karigar/issue_karigar/issue_karigar_screen.dart';
import '../karigar/receive_karigar/receive_karigar_screen.dart';
import '../karigar/pending_jobs/pending_jobs_screen.dart';
import '../karigar/karigar_hisaab/karigar_hisaab_screen.dart';

// âœ… v6: GIRVI MODULE
import '../girvi/new_girvi/new_girvi_screen.dart';
import '../girvi/girvi_list/girvi_list_screen.dart';
import '../girvi/interest_calc/interest_calc_screen.dart';
import '../girvi/notice_auction/notice_auction_screen.dart';

// âœ… v9: REPORTS MODULE
import '../report/day_book/day_book_screen.dart';

class MainLayoutWrapper extends StatefulWidget {
  const MainLayoutWrapper({super.key});

  @override
  State<MainLayoutWrapper> createState() => _MainLayoutWrapperState();
}

class _MainLayoutWrapperState extends State<MainLayoutWrapper> {
  String _activePageRouteId = AppRoutes.dashboardRoute;
  int? _activeCustomerId;

  void _openSalesWorkspace({int? editBillId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosMasterSaleScreen(
          editBillId: editBillId,
          onBack: () => Navigator.maybePop(context),
        ),
      ),
    );
  }

  void _openGirviWorkspace({int? editLoanId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewGirviScreen(
          editLoanId: editLoanId,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openAdvanceWorkspace({int? editOrderId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingAdvanceScreen(
          editOrderId: editOrderId,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildCustomerProfile(int customerId) {
    return CustomerProfileScreen(
      customerId: customerId,
      onBack: () => Navigator.pop(context),
      onDeleted: () => Navigator.pop(context),
      onNewSale: (_) => _openSalesWorkspace(),
      onEditBill: (billId) => _openSalesWorkspace(editBillId: billId),
      onEditGirvi: (loanId) => _openGirviWorkspace(editLoanId: loanId),
      onEditAdvance: (orderId) => _openAdvanceWorkspace(editOrderId: orderId),
      onConvertAdvanceToSale: (_, __) => _openSalesWorkspace(),
    );
  }

  // â”€â”€ Central Navigation Controller â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // âœ… NEW: customerId ke saath navigate â€” Payment Status â†’ Customer Profile
  void _navigateToWithId(String routeId, {int? customerId}) {
    if (routeId == AppRoutes.customerProfileRoute && customerId != null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => _buildCustomerProfile(customerId)));
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

      // â”€â”€ âœ… v10: DELIVERY MANAGEMENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    } else if (routeId == AppRoutes.deliveryManagementRoute) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DeliveryManagementScreen(
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
                              builder: (_) =>
                                  _buildCustomerProfile(customerId)));
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

    // â”€â”€ âœ… v7: SUPPLIER MODULE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupplierProfileScreen(
                            supplierId: supplierId,
                            onBack: () => Navigator.pop(context),
                            onDeleted: () => Navigator.pop(context),
                            onNewStock: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddStockHubScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
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

    // â”€â”€ STOCK â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    else if (routeId == AppRoutes.addStockRoute) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddStockHubScreen()));
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

    // â”€â”€ FINANCE & LEDGERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    else if (routeId == AppRoutes.cashBookRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CashBookScreen()));
    } else if (routeId == AppRoutes.bankBookRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BankBookScreen()));
    } else if (routeId == AppRoutes.dueReportRoute) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DueReportScreen()),
      );
    } else if (routeId == AppRoutes.dueCollectionRoute) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DueCollectionEntryScreen()),
      );
    } else if (routeId == AppRoutes.dueReceiptHistoryRoute) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DueReceiptHistoryScreen()),
      );
    } else if (routeId == AppRoutes.expenseEntryRoute) {
      // âœ… v8
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ExpenseScreen(
                    onBack: () => Navigator.pop(context),
                  )));
    }

    // â”€â”€ KARIGAR MODULE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

    // â”€â”€ âœ… v6: GIRVI MODULE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

    // â”€â”€ âœ… v9: REPORTS MODULE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Page Content Switcher â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _getPageContent(String routeId) {
    switch (routeId) {
      case AppRoutes.dashboardRoute:
        return DashboardScreen(
          onNavigate: (route) => _navigateTo(route),
          // âœ… FIX: customerId ab pass hoga â€” Payment Status â†’ Customer Profile
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

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                color: UV.colors.bgSecondary.withValues(alpha: 0.5),
                border: Border(
                  left: BorderSide(color: UV.colors.glassBorder, width: 1),
                ),
                boxShadow: [
                  if (!isSmallScreen)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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

  // â”€â”€ Sidebar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
