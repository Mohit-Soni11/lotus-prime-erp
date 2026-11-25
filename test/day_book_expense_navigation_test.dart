import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/core/router/app_back_navigation.dart';

void main() {
  testWidgets('Day Book can open and return from Expense on the root stack',
      (tester) async {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/day-book',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: Scaffold(
              body: TextButton(
                onPressed: () => context.push('/expense'),
                child: const Text('Open expense'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/expense',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: Scaffold(
              body: TextButton(
                onPressed: () =>
                    AppBackNavigation.backOr(context, '/dashboard'),
                child: const Text('Expense back'),
              ),
            ),
          ),
        ),
        ShellRoute(
          builder: (_, __, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, _) => TextButton(
                onPressed: () => context.push('/day-book'),
                child: const Text('Open day book'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open day book'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open expense'));
    await tester.pumpAndSettle();
    expect(find.text('Expense back'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Expense back'));
    await tester.pumpAndSettle();
    expect(find.text('Open expense'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
