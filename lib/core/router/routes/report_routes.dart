part of '../app_router.dart';

List<RouteBase> reportRoutes() => [
      GoRoute(
        path: RoutePaths.reportDayBook,
        builder: (context, state) => DayBookScreen(
          initialDate:
              DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.reportSales,
        builder: (context, state) => SalesReportScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.reportPurchase,
        builder: (context, state) => const CustomerMetalPurchaseLedgerScreen(
          title: 'Metal Purchase Report',
        ),
      ),
      GoRoute(
        path: RoutePaths.customerMetalCheckoutReport,
        builder: (context, state) => const CustomerMetalCheckoutReportScreen(),
      ),
      GoRoute(
        path: RoutePaths.customerMetalPurchaseVoucher,
        builder: (context, state) {
          final voucherId = int.tryParse(
            state.pathParameters['voucherId'] ?? '',
          );
          if (voucherId == null) {
            return const CustomerMetalPurchaseLedgerScreen();
          }
          return CustomerMetalPurchaseVoucherDetailScreen(
            voucherId: voucherId,
            onBack: () => _goBackOr(
              context,
              RoutePaths.reportPurchase,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.reportPnl,
        builder: (context, state) => _ComingSoonScreen(
          pageTitle: AppRoutes.getTitle(AppRoutes.profitLossRoute),
        ),
      ),
      GoRoute(
        path: RoutePaths.reportGst,
        builder: (context, state) => GstReportHubScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.billingSetup,
        builder: (context, state) => const BillingSetupWorkspaceScreen(),
      ),
      GoRoute(
        path: '${RoutePaths.settingsMetalCostAnalyser}/audit',
        redirect: (context, state) => RoutePaths.settingsMetalCostAnalyser,
      ),
      GoRoute(
        path: RoutePaths.accountProfile,
        builder: (context, state) => AccountProfileScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
    ];
