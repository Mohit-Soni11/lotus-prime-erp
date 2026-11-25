import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/app_back_navigation.dart';

void main() {
  testWidgets('Back works from a shell route builder with and without history',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/expense'),
            child: const Text('Open expense'),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      ),
      ShellRoute(
        builder: (_, __, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/expense',
            builder: (routeContext, _) => Column(
              children: [
                TextButton(
                  onPressed: () => AppBackNavigation.backOr(routeContext, '/'),
                  child: const Text('Expense Back'),
                ),
                TextButton(
                  onPressed: () =>
                      AppBackNavigation.backOr(routeContext, '/expense'),
                  child: const Text('Same Route Fallback'),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Open expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open expense'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go('/expense');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Same Route Fallback'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go('/expense');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open expense'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
