import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';

/// Navigation context for the Risk & Collections → Notice & Recovery flow.
abstract final class NoticeRecoveryNavigation {
  static const _riskCollections = 'riskCollections';

  static String fromRiskCollections(String ticketNo) => Uri(
        path: RoutePaths.girviNotice,
        queryParameters: {
          'ticketNo': ticketNo,
          'returnTo': _riskCollections,
        },
      ).toString();

  static String fallbackPath(Uri location) =>
      location.queryParameters['returnTo'] == _riskCollections
          ? RoutePaths.customerDefaulters
          : RoutePaths.dashboard;

  static void goBack(BuildContext context, Uri location) {
    // Keep the originating page and its filters alive when it is on the stack.
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackPath(location));
  }
}
