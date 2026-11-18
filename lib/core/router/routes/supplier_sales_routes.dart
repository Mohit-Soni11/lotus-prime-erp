part of '../app_router.dart';

List<RouteBase> supplierSalesRoutes() => [
      GoRoute(
        path: RoutePaths.supplierList,
        builder: (context, state) => SupplierListScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
          onAddSupplier: () => context.push(RoutePaths.supplierAdd),
          onSupplierTap: (supplierId) =>
              context.go(RoutePaths.supplierProfileFor(supplierId)),
        ),
      ),
      GoRoute(
        path: RoutePaths.supplierAdd,
        builder: (context, state) => AddSupplierScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
          onSaved: () => context.go(RoutePaths.supplierList),
        ),
      ),
      GoRoute(
        path: RoutePaths.supplierProfile,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final initialVoucherId =
              int.tryParse(state.uri.queryParameters['voucherId'] ?? '');
          return SupplierProfileScreen(
            supplierId: id,
            initialVoucherId: initialVoucherId,
            onBack: () => _goBackOr(context, RoutePaths.supplierList),
            onDeleted: () => context.go(RoutePaths.supplierList),
            onNewStock: () => context.go(RoutePaths.stockAdd),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.salesReturnExchange,
        builder: (context, state) {
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );
          return ReturnReversalDeskScreen(
            initialBookingOrderNo: state.uri.queryParameters['bookingOrderNo'],
            onBack: () => returnCustomerId == null
                ? _goBackOr(context, RoutePaths.dashboard)
                : context.go(
                    RoutePaths.customerProfileFor(returnCustomerId),
                  ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.purchaseEntry,
        builder: (context, state) => PurchaseEntryScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
    ];
