part of '../app_router.dart';

List<RouteBase> standalonePledgeRoutes() => [
      GoRoute(
        path: RoutePaths.girviNew,
        pageBuilder: (context, state) {
          final editLoanId = int.tryParse(
            state.uri.queryParameters['editLoanId'] ?? '',
          );
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );

          return WorkspaceTransitionPage(
            key: state.pageKey,
            child: NewGirviScreen(
              editLoanId: editLoanId,
              onBack: () => returnCustomerId == null
                  ? WorkspaceNavigation.backTo(context, RoutePaths.dashboard)
                  : context.go(RoutePaths.customerProfileFor(returnCustomerId)),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.girviInterest,
        pageBuilder: (context, state) {
          final returnTo = state.uri.queryParameters['returnTo'];
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );
          final fallbackPath = switch (returnTo) {
            'riskCollections' => RoutePaths.customerDefaulters,
            'girviNotice' => RoutePaths.girviNotice,
            'girviLedger' => RoutePaths.girviList,
            'customerProfile' when returnCustomerId != null =>
              RoutePaths.customerProfileFor(returnCustomerId),
            _ => RoutePaths.dashboard,
          };
          return WorkspaceTransitionPage(
            key: state.pageKey,
            child: InterestCalcScreen(
              initialTicketNo: state.uri.queryParameters['ticketNo'],
              onBack: () =>
                  returnTo == 'customerProfile' && returnCustomerId != null
                      ? context.go(fallbackPath)
                      : WorkspaceNavigation.backTo(context, fallbackPath),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.girviList,
        pageBuilder: (context, state) => WorkspaceTransitionPage(
          key: state.pageKey,
          child: GirviListScreen(
            onBack: () => WorkspaceNavigation.backTo(
              context,
              RoutePaths.dashboard,
            ),
            onNewGirvi: () async {
              await context.push(RoutePaths.girviNew);
            },
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.girviAccountDetail,
        pageBuilder: (context, state) {
          final loanId =
              int.tryParse(state.pathParameters['loanId'] ?? '') ?? 0;
          final returnTo = state.uri.queryParameters['returnTo'];
          final returnCustomerId = int.tryParse(
            state.uri.queryParameters['returnCustomerId'] ?? '',
          );
          return WorkspaceTransitionPage(
            key: state.pageKey,
            child: GirviAccountDetailScreen(
              loanId: loanId,
              returnTo: returnTo,
              returnCustomerId: returnCustomerId,
              onBack: () {
                final fallbackPath = switch (returnTo) {
                  'riskCollections' => RoutePaths.customerDefaulters,
                  'girviNotice' => RoutePaths.girviNotice,
                  'customerProfile' when returnCustomerId != null =>
                    RoutePaths.customerProfileFor(returnCustomerId),
                  _ => RoutePaths.girviList,
                };
                if (returnTo == 'customerProfile' && returnCustomerId != null) {
                  context.go(fallbackPath);
                } else {
                  WorkspaceNavigation.backTo(context, fallbackPath);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.customerDefaulters,
        pageBuilder: (context, state) => WorkspaceTransitionPage(
          key: state.pageKey,
          child: DefaulterListScreen(
            onBack: () => WorkspaceNavigation.backTo(
              context,
              RoutePaths.dashboard,
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.girviNotice,
        pageBuilder: (context, state) => WorkspaceTransitionPage(
          key: state.pageKey,
          child: ContactRecoveryScreen(
            initialTicketNo: state.uri.queryParameters['ticketNo'],
            onBack: () => NoticeRecoveryNavigation.goBack(context, state.uri),
          ),
        ),
      ),
    ];
