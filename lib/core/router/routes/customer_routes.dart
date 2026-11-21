part of '../app_router.dart';

List<RouteBase> customerRoutes() => [
      GoRoute(
        path: RoutePaths.customerList,
        builder: (context, state) => CustomerListScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
          onAddCustomer: () => context.go(RoutePaths.customerAdd),
          onCustomerTap: (customerId) =>
              context.go(RoutePaths.customerProfileFor(customerId)),
        ),
      ),
      GoRoute(
        path: RoutePaths.customerAdd,
        builder: (context, state) => AddCustomerScreen(
          onBack: () => _goBackOr(context, RoutePaths.customerList),
          onSaved: () => context.go(RoutePaths.customerList),
        ),
      ),
      workspaceRoute(
        path: RoutePaths.customerProfile,
        rootNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final initialBillId =
              int.tryParse(state.uri.queryParameters['billId'] ?? '');
          final initialGirviId =
              int.tryParse(state.uri.queryParameters['girviId'] ?? '');
          final initialAdvanceId =
              int.tryParse(state.uri.queryParameters['advanceId'] ?? '');
          return CustomerProfileScreen(
            customerId: id,
            initialBillId: initialBillId,
            initialGirviId: initialGirviId,
            initialAdvanceId: initialAdvanceId,
            onBack: () => _goBackOr(context, RoutePaths.customerList),
            onDeleted: () => context.go(RoutePaths.customerList),
            onNewSale: (customerId) => context.go(Uri(
              path: RoutePaths.salesPos,
              queryParameters: {
                'customerId': '$customerId',
                'returnCustomerId': '$customerId',
              },
            ).toString()),
            onEditBill: (billId) => context.go(
              Uri(
                path: RoutePaths.salesPos,
                queryParameters: {
                  'editBillId': '$billId',
                  'returnCustomerId': '$id',
                },
              ).toString(),
            ),
            onEditGirvi: (loanId) => context.go(
              Uri(
                path: RoutePaths.girviNew,
                queryParameters: {
                  'editLoanId': '$loanId',
                  'returnCustomerId': '$id',
                },
              ).toString(),
            ),
            onCollectGirviInterest: (customerId, ticketNo) => context.go(
              Uri(
                path: RoutePaths.girviInterest,
                queryParameters: {
                  'ticketNo': ticketNo,
                  'returnTo': 'customerProfile',
                  'returnCustomerId': '$customerId',
                },
              ).toString(),
            ),
            onOpenGirviAccount: (loanId) => context.go(
              Uri(
                path: '${RoutePaths.girviAccountBase}/$loanId',
                queryParameters: {
                  'returnTo': 'customerProfile',
                  'returnCustomerId': '$id',
                },
              ).toString(),
            ),
            onEditAdvance: (orderId) => context.go(
              Uri(
                path: RoutePaths.salesBooking,
                queryParameters: {
                  'editAdvanceId': '$orderId',
                  'returnCustomerId': '$id',
                },
              ).toString(),
            ),
            onCancelAdvance: (orderNo, customerId) => context.go(
              Uri(
                path: RoutePaths.salesReturnExchange,
                queryParameters: {
                  'bookingOrderNo': orderNo,
                  'returnCustomerId': '$customerId',
                },
              ).toString(),
            ),
            onConvertAdvanceToSale: (orderId, customerId) => context.go(
              Uri(
                path: RoutePaths.salesPos,
                queryParameters: {
                  'convertAdvanceId': '$orderId',
                  'returnCustomerId': '$customerId',
                },
              ).toString(),
            ),
            onCollectDue: (customerId, billNo) => context.go(
              Uri(
                path: RoutePaths.financeDueCollection,
                queryParameters: {
                  'customerId': '$customerId',
                  'billNo': billNo,
                  'returnCustomerId': '$customerId',
                },
              ).toString(),
            ),
          );
        },
      ),
    ];
