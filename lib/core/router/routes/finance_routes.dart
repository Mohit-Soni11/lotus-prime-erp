part of '../app_router.dart';

List<RouteBase> financeRoutes() => [
      GoRoute(
        path: RoutePaths.financeCashBook,
        builder: (context, state) => AccountBookScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.financeCashLedger,
        builder: (context, state) => CashBookScreen(
          onBack: () => _goBackOr(context, RoutePaths.financeCashBook),
        ),
      ),
      GoRoute(
        path: RoutePaths.financeBankLedger,
        builder: (context, state) => BankBookScreen(
          title: 'Bank Ledger',
          onBack: () => _goBackOr(context, RoutePaths.financeCashBook),
        ),
      ),
      GoRoute(
        path: RoutePaths.financeBankBook,
        builder: (_, __) => const BankBookScreen(),
      ),
      workspaceRoute(
        path: RoutePaths.financeExpense,
        rootNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExpenseScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
          initialDate:
              DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
          initialReference: state.uri.queryParameters['reference'],
          initialDraftAmount:
              state.extra is double ? state.extra as double : null,
          initialDraft:
              state.extra is ExpenseDraft ? state.extra as ExpenseDraft : null,
        ),
      ),
      GoRoute(
        path: RoutePaths.financeDueReport,
        builder: (context, state) => DueReportScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
      GoRoute(
        path: RoutePaths.financeDueCollection,
        builder: (context, state) {
          final initialCustomerId = int.tryParse(
            state.uri.queryParameters['customerId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );
          final initialBillNo = state.uri.queryParameters['billNo'];

          return DueCollectionEntryScreen(
            initialCustomerId: initialCustomerId,
            initialBillNo: initialBillNo,
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
      GoRoute(
        path: RoutePaths.financeDueReceipts,
        builder: (context, state) => DueReceiptHistoryScreen(
          onBack: () => _goBackOr(context, RoutePaths.dashboard),
        ),
      ),
    ];
