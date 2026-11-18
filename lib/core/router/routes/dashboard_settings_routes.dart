part of '../app_router.dart';

List<RouteBase> dashboardSettingsRoutes() => [
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => DashboardScreen(
          onNavigate: (routeId) => WorkspaceNavigation.open(
            context,
            RouteMapper.toPath(routeId),
          ),
          onNavigateWithId: (routeId, {customerId}) {
            if (routeId == AppRoutes.customerProfileRoute &&
                customerId != null) {
              context.go(RoutePaths.customerProfileFor(customerId));
            } else {
              WorkspaceNavigation.open(
                context,
                RouteMapper.toPath(routeId),
              );
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
        path: RoutePaths.settingsMetalCostAnalyser,
        builder: (context, state) => MetalValuationDeskScreen(
          onBack: () => _goBackOr(context, RoutePaths.settings),
        ),
      ),
      GoRoute(
        path: '${RoutePaths.settingsMetalCostAnalyser}/metal/:metal',
        builder: (context, state) => MetalValuationGradeScreen(
          metalType: state.pathParameters['metal'] ?? '',
          onBack: () => context.go(RoutePaths.settingsMetalCostAnalyser),
        ),
      ),
      GoRoute(
        path:
            '${RoutePaths.settingsMetalCostAnalyser}/metal/:metal/batch/:batch',
        builder: (context, state) {
          final metal = state.pathParameters['metal'] ?? '';
          return MetalValuationBatchDetailScreen(
            metalType: metal,
            batchCode: state.pathParameters['batch'] ?? '',
            onBack: () => context.go(
              '${RoutePaths.settingsMetalCostAnalyser}/metal/$metal',
            ),
          );
        },
      ),
    ];
