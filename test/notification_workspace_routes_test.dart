import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'production notification destinations are root workspaces, outside the sidebar shell',
      () {
    final router = createAppRouter();
    addTearDown(router.dispose);
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    for (final path in [
      RoutePaths.metalRateMaster,
      RoutePaths.stockLowAlert,
      RoutePaths.customerProfile,
      RoutePaths.reportDayBook,
      RoutePaths.salesPos,
      RoutePaths.salesBooking,
      RoutePaths.girviAccountDetail,
    ]) {
      final route = routes.singleWhere((route) => route.path == path);
      expect(route.pageBuilder, isNotNull,
          reason: '$path needs the shared workspace transition');
      expect(
          route.parentNavigatorKey == null ||
              route.parentNavigatorKey == router.configuration.navigatorKey,
          isTrue);
    }
    final shell = router.configuration.routes.whereType<ShellRoute>().single;
    expect(
        shell.routes
            .whereType<GoRoute>()
            .any((route) => route.path == RoutePaths.dashboard),
        isTrue);
  });
}
