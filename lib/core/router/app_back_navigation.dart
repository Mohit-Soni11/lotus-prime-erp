import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_routes.dart';

abstract final class AppBackNavigation {
  static void backOr(BuildContext context, String fallbackPath) {
    final router = GoRouter.of(context);
    final rootNavigator = router.routerDelegate.navigatorKey.currentState;
    if (rootNavigator?.canPop() == true) {
      rootNavigator!.pop();
      return;
    }
    if (router.canPop()) {
      router.pop();
    } else {
      final currentPath = router.routeInformationProvider.value.uri.toString();
      router.go(
          currentPath == fallbackPath ? RoutePaths.dashboard : fallbackPath);
    }
  }
}
