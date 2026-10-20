import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';

/// Keeps the dashboard mounted while opening full-screen pledge workspaces.
abstract final class WorkspaceNavigation {
  static const _stackedPaths = {
    RoutePaths.girviNew,
    RoutePaths.girviInterest,
    RoutePaths.girviList,
    RoutePaths.girviNotice,
    RoutePaths.customerDefaulters,
  };

  static void open(BuildContext context, String location) {
    final path = Uri.parse(location).path;
    if (_stackedPaths.contains(path)) {
      context.push(location);
    } else {
      context.go(location);
    }
  }

  static void backTo(BuildContext context, String fallbackPath) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackPath);
    }
  }
}
