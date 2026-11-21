import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../features/notifications/domain/notification_item.dart';
import 'payment_status_navigation.dart';

abstract final class NotificationNavigation {
  static String location(NotificationItem item) {
    if (item.location != null) return item.location!;
    if (item.billId != null) {
      return PaymentStatusNavigation.invoice(item.billId!, item.customerId);
    }
    if (item.loanId != null) return RoutePaths.girviAccountFor(item.loanId!);
    return RouteMapper.toPath(item.routeId ?? AppRoutes.dashboardRoute);
  }

  /// Keeps the originating dashboard alive and restores its notification list
  /// after the destination route is popped by either screen or system Back.
  static Future<void> showCenter(
    BuildContext context, {
    required WidgetBuilder builder,
    Future<void> Function()? onReturn,
  }) async {
    while (true) {
      if (!context.mounted) return;
      final selected = await showDialog<NotificationItem>(
        context: context,
        useSafeArea: true,
        builder: builder,
      );
      if (selected == null || !context.mounted) return;
      await context.push<void>(location(selected));
      if (context.mounted && onReturn != null) await onReturn();
    }
  }
}
