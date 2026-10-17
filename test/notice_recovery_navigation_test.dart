import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/notice_recovery_navigation.dart';
import 'package:lotus_erp/theme/girvi/girvi_icons.dart';
import 'package:lotus_erp/ui/girvi/contact_recovery/contact_recovery_app_bar.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('risk link preserves ticket and carries a known return destination', () {
    final uri =
        Uri.parse(NoticeRecoveryNavigation.fromRiskCollections('GRV 12/3'));
    expect(uri.path, RoutePaths.girviNotice);
    expect(uri.queryParameters['ticketNo'], 'GRV 12/3');
    expect(NoticeRecoveryNavigation.fallbackPath(uri),
        RoutePaths.customerDefaulters);
  });

  test('missing or unknown return destination safely falls back to dashboard',
      () {
    for (final query in [
      '',
      '?returnTo=unknown',
      '?returnTo=https://example.com'
    ]) {
      expect(
        NoticeRecoveryNavigation.fallbackPath(
            Uri.parse('${RoutePaths.girviNotice}$query')),
        RoutePaths.dashboard,
      );
    }
  });

  testWidgets('notice header returns to existing risk page with search intact',
      (tester) async {
    final router = _router(RoutePaths.customerDefaulters);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpNavigation(tester);
    await tester.enterText(
        find.byKey(const ValueKey('risk-search')), 'GRV-0012');
    await tester.tap(find.text('Contact Review'));
    await _pumpNavigation(tester);
    expect(find.text('Notice ticket: GRV-0012'), findsOneWidget);

    await tester.tap(find.byIcon(GirviIcons.backArrow));
    await _pumpNavigation(tester);

    expect(_location(router).path, RoutePaths.customerDefaulters);
    expect(find.text('GRV-0012'), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct risk notice link returns to risk without a pushed page',
      (tester) async {
    final router =
        _router(NoticeRecoveryNavigation.fromRiskCollections('GRV-0012'));
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpNavigation(tester);
    expect(router.canPop(), isFalse);
    await tester.tap(find.byIcon(GirviIcons.backArrow));
    await _pumpNavigation(tester);
    expect(_location(router).path, RoutePaths.customerDefaulters);
  });

  testWidgets('standalone notice retains the dashboard fallback',
      (tester) async {
    final router = _router(RoutePaths.girviNotice);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpNavigation(tester);
    await tester.tap(find.byIcon(GirviIcons.backArrow));
    await _pumpNavigation(tester);
    expect(_location(router).path, RoutePaths.dashboard);
  });

  testWidgets('legacy pushed notice without returnTo still returns to caller',
      (tester) async {
    final router = _router(RoutePaths.customerDefaulters);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpNavigation(tester);
    router.push('${RoutePaths.girviNotice}?ticketNo=GRV-0013');
    await _pumpNavigation(tester);
    await tester.tap(find.byIcon(GirviIcons.backArrow));
    await _pumpNavigation(tester);
    expect(_location(router).path, RoutePaths.customerDefaulters);
    expect(router.canPop(), isFalse);
  });
}

Uri _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;

// Use isolated route bodies: navigation tests must not open the production DB
// or start authentication, finance posting, or automatic retention cleanup.
GoRouter _router(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: RoutePaths.dashboard,
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: RoutePaths.customerDefaulters,
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                const TextField(key: ValueKey('risk-search')),
                TextButton(
                  onPressed: () => context.push(
                    NoticeRecoveryNavigation.fromRiskCollections('GRV-0012'),
                  ),
                  child: const Text('Contact Review'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.girviNotice,
          builder: (context, state) => Scaffold(
            appBar: ContactRecoveryAppBar(
              onBack: () => NoticeRecoveryNavigation.goBack(context, state.uri),
            ),
            body:
                Text('Notice ticket: ${state.uri.queryParameters['ticketNo']}'),
          ),
        ),
      ],
    );

Future<void> _pumpNavigation(WidgetTester tester) async {
  // The real app bar has a repeating status animation; wait for route
  // transitions without waiting for that animation to settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
