part of '../app_router.dart';

List<RouteBase> inventoryRoutes() => [
      GoRoute(
        path: RoutePaths.stockInventory,
        builder: (context, state) => InventoryScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
          initialMetalLabel: state.uri.queryParameters['metal'],
          initialBatchCode: state.uri.queryParameters['batch'],
        ),
      ),
      GoRoute(
        path: RoutePaths.stockSummary,
        builder: (context, state) => StockSummaryScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockActivity,
        builder: (context, state) => StockActivityScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockSearch,
        builder: (context, state) => StockSearchScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockValuation,
        redirect: (context, state) => RoutePaths.settingsMetalCostAnalyser,
      ),
      GoRoute(
        path: RoutePaths.stockTransfer,
        builder: (context, state) => StockTransferScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockLowAlert,
        builder: (context, state) => LowStockAlertScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
    ];
