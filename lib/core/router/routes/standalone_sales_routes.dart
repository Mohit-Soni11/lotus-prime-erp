part of '../app_router.dart';

List<RouteBase> standaloneSalesRoutes() => [
      workspaceRoute(
        path: RoutePaths.salesPos,
        rootNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final editBillId = int.tryParse(
            state.uri.queryParameters['editBillId'] ?? '',
          );
          final initialCustomerId = int.tryParse(
            state.uri.queryParameters['customerId'] ?? '',
          );
          final convertAdvanceId = int.tryParse(
            state.uri.queryParameters['convertAdvanceId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return PosMasterSaleScreen(
            editBillId: editBillId,
            convertAdvanceId: convertAdvanceId,
            initialCustomerId: initialCustomerId,
            onBack: () {
              if (returnCustomerId != null) {
                context.go(RoutePaths.customerProfileFor(returnCustomerId));
                return;
              }
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.dashboard);
            },
          );
        },
      ),
      workspaceRoute(
        path: RoutePaths.salesBooking,
        rootNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final editAdvanceId = int.tryParse(
            state.uri.queryParameters['editAdvanceId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return BookingAdvanceScreen(
            editOrderId: editAdvanceId,
            onBack: () {
              if (returnCustomerId != null) {
                context.go(RoutePaths.customerProfileFor(returnCustomerId));
                return;
              }
              _goBackOr(context, RoutePaths.dashboard);
            },
          );
        },
      ),
    ];
