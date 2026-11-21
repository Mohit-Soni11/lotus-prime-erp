import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/notification_navigation.dart';
import 'package:lotus_erp/core/router/workspace_navigation.dart';
import 'package:lotus_erp/features/notifications/domain/notification_item.dart';
import 'package:lotus_erp/features/notifications/presentation/notification_center_screen.dart';
import 'package:lotus_erp/features/notifications/presentation/notification_view_state.dart';

void main() {
  final cases = <String, NotificationItem>{
    'girvi': NotificationItem(
        id: 1,
        type: 'Girvi',
        title: 'Open girvi',
        desc: '',
        targetRole: 'all',
        loanId: 7),
    'stock': NotificationItem(
        id: 2,
        type: 'Inventory',
        title: 'Open stock',
        desc: '',
        targetRole: 'all',
        routeId: AppRoutes.lowStockAlertRoute),
    'order': NotificationItem(
        id: 3,
        type: 'Orders',
        title: 'Open order',
        desc: '',
        targetRole: 'all',
        routeId: AppRoutes.bookingAdvanceRoute),
    'invoice': NotificationItem(
        id: 4,
        type: 'Collections',
        title: 'Open invoice',
        desc: '',
        targetRole: 'all',
        billId: 8,
        customerId: 9),
    'walk-in invoice': NotificationItem(
        id: 5,
        type: 'Collections',
        title: 'Open walk-in invoice',
        desc: '',
        targetRole: 'all',
        billId: 10),
    'opening verification': NotificationItem(
        id: 6,
        type: 'Day Book',
        title: 'Verify opening balance',
        desc: '',
        targetRole: 'all',
        location: '${RoutePaths.reportDayBook}?action=verify'),
    'day closing': NotificationItem(
        id: 7,
        type: 'Day Book',
        title: 'Close business day',
        desc: '',
        targetRole: 'all',
        location: '${RoutePaths.reportDayBook}?action=close'),
    'metal rates': NotificationItem(
        id: 8,
        type: 'Metal Rates',
        title: 'Update metal rates',
        desc: '',
        targetRole: 'all',
        location: RoutePaths.metalRateMaster),
  };

  for (final entry in cases.entries) {
    for (final systemBack in [false, true]) {
      testWidgets(
          '${entry.key}: ${systemBack ? 'system' : 'page'} Back returns to notifications',
          (tester) async {
        final item = entry.value;
        final destination =
            Uri.parse(NotificationNavigation.location(item)).path;
        final rootKey = GlobalKey<NavigatorState>();
        final storage = PageStorageBucket();
        final view = NotificationViewState();
        final inShell = entry.key != 'girvi' &&
            entry.key != 'order' &&
            entry.key != 'walk-in invoice';
        final router = GoRouter(
          navigatorKey: rootKey,
          initialLocation: RoutePaths.dashboard,
          routes: [
            GoRoute(path: '/outside', builder: (_, __) => const SizedBox()),
            if (!inShell)
              GoRoute(
                  path: destination,
                  builder: (context, state) => _target(context)),
            ShellRoute(
              builder: (_, __, child) => child,
              routes: [
                GoRoute(
                    path: RoutePaths.dashboard,
                    builder: (context, state) => Scaffold(
                            body: TextButton(
                          child: const Text('Open notifications'),
                          onPressed: () => NotificationNavigation.showCenter(
                            context,
                            builder: (dialogContext) => PageStorage(
                                bucket: storage,
                                child: NotificationCenterScreen(
                                  stream: const Stream.empty(),
                                  initialItems: [
                                    item,
                                    for (var i = 1; i <= 12; i++)
                                      NotificationItem(
                                        id: -i,
                                        type: 'General',
                                        title: 'Message $i',
                                        desc: 'Notification details',
                                        targetRole: 'all',
                                      ),
                                  ],
                                  viewState: view,
                                  onMarkAllRead: () async {},
                                  onSelect: (selected) =>
                                      Navigator.pop(dialogContext, selected),
                                )),
                          ),
                        ))),
                if (inShell)
                  GoRoute(
                      path: destination,
                      builder: (context, state) => _target(context)),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.tap(find.text('Open notifications'));
        await tester.pumpAndSettle();
        ScrollPosition listPosition() => tester
            .state<ScrollableState>(find
                .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable))
                .first)
            .position;
        listPosition().jumpTo(80);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(item.title));
        await tester.pumpAndSettle();
        final savedOffset = listPosition().pixels;
        expect(savedOffset, greaterThan(0));
        for (var visit = 0; visit < 3; visit++) {
          await tester.tap(find.text(item.title));
          await tester.pumpAndSettle();
          expect(find.text('Destination'), findsOneWidget);
          expect(find.text('Notifications'), findsNothing);
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.text('Back'));
          }
          await tester.pumpAndSettle();
          expect(find.text('Notifications'), findsOneWidget);
          expect(find.text(item.title), findsOneWidget);
          expect(find.text('Destination'), findsNothing);
          expect(router.routeInformationProvider.value.uri.path,
              RoutePaths.dashboard);
          expect(tester.takeException(), isNull);
          expect(listPosition().pixels, savedOffset);
        }
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Open notifications'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Widget _target(BuildContext context) => Scaffold(
        body: Column(children: [
      const Text('Destination'),
      TextButton(
          onPressed: () => WorkspaceNavigation.backTo(context, '/outside'),
          child: const Text('Back')),
    ]));
