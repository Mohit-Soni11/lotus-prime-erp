part of '../app_router.dart';

List<RouteBase> standaloneStockRoutes() => [
      GoRoute(
        path: RoutePaths.stockAdd,
        builder: (context, _) => AddStockHubScreen(
          onBack: () => context.go(RoutePaths.dashboard),
        ),
      ),
    ];
