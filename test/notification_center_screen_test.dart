import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/notifications/domain/notification_item.dart';
import 'package:lotus_erp/features/notifications/presentation/notification_center_screen.dart';
import 'package:lotus_erp/features/notifications/presentation/notification_view_state.dart';
import 'package:lotus_erp/features/notifications/presentation/widgets/notification_bell_button.dart';

void main() {
  testWidgets('scroll offsets and expanded filters restore independently',
      (tester) async {
    final storage = PageStorageBucket();
    final view = NotificationViewState();
    Widget panel(int generation) => MaterialApp(
        home: PageStorage(
            bucket: storage,
            child: NotificationCenterScreen(
                key: ValueKey(generation),
                viewState: view,
                stream: const Stream.empty(),
                initialItems: [
                  for (var i = 0; i < 12; i++)
                    NotificationItem(
                        id: i,
                        type: 'Category $i',
                        title: 'Message $i',
                        desc: 'Notification details',
                        targetRole: 'all'),
                ],
                onMarkAllRead: () async {},
                onSelect: (_) {})));
    ScrollPosition position(Type type) => tester
        .state<ScrollableState>(find
            .descendant(
                of: find.byType(type), matching: find.byType(Scrollable))
            .first)
        .position;

    await tester.pumpWidget(panel(0));
    await tester.tap(find.text('Search and filters'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    final filterOffset = position(SingleChildScrollView).pixels;
    expect(filterOffset, greaterThan(0));
    position(CustomScrollView).jumpTo(80);
    await tester.pumpAndSettle();

    for (var generation = 1; generation <= 3; generation++) {
      await tester.pumpWidget(panel(generation));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(position(CustomScrollView).pixels, 80);
      expect(position(SingleChildScrollView).pixels, filterOffset);
    }
    await tester.ensureVisible(find.text('Search and filters'));
    await tester.tap(find.text('Search and filters'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(panel(4));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid repeated card clicks open only one destination',
      (tester) async {
    final saved = Completer<void>();
    var saves = 0;
    var opened = 0;
    final item = NotificationItem(
        id: 1,
        type: 'Girvi',
        title: 'Open account',
        desc: '',
        targetRole: 'all',
        loanId: 7);
    await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
            stream: const Stream.empty(),
            initialItems: [item],
            onMarkAllRead: () async {},
            onMarkRead: (_) {
              saves++;
              return saved.future;
            },
            onSelect: (_) => opened++)));
    await tester.ensureVisible(find.text(item.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.title));
    await tester.tap(find.text(item.title));
    expect(saves, 1);
    saved.complete();
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification opens its invoice and resolves from live stream',
      (tester) async {
    final controller = StreamController<List<NotificationItem>>.broadcast();
    addTearDown(controller.close);
    final item = NotificationItem(
      id: -1,
      type: 'Collections',
      title: 'Call customer · due today',
      desc: 'Collect ₹ 250.00 for INV-1.',
      targetRole: 'all',
      billId: 12,
      isOperational: true,
    );
    NotificationItem? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: NotificationCenterScreen(
        stream: controller.stream,
        initialItems: [item],
        onMarkAllRead: () async {},
        onSelect: (value) => selected = value,
      ),
    )));
    final panel = find.descendant(
        of: find.byType(NotificationCenterScreen),
        matching: find.byType(Scaffold));
    expect(
        tester.getSize(panel).width,
        lessThan(
            tester.view.physicalSize.width / tester.view.devicePixelRatio));
    expect(find.text('Retained until resolved'), findsOneWidget);
    await tester.ensureVisible(find.text(item.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.title));
    expect(selected?.billId, 12);
    controller.add([]);
    await tester.pump();
    expect(find.text('All caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mark all read and clear messages leave important tasks visible',
      (tester) async {
    final source = StreamController<List<NotificationItem>>.broadcast();
    addTearDown(source.close);
    var items = [
      NotificationItem(
          id: -1,
          type: 'Day Book',
          title: 'Verify opening',
          desc: 'Pending',
          targetRole: 'all',
          eventKey: 'business:opening:today',
          isOperational: true),
      NotificationItem(
          id: 1,
          type: 'General',
          title: 'Ordinary message',
          desc: 'Information',
          targetRole: 'all'),
    ];
    await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
      stream: source.stream,
      initialItems: items,
      onMarkAllRead: () async {
        items = items.map((item) => item.copyWith(isRead: true)).toList();
        source.add(items);
      },
      onClearMessages: () async {
        items = items.where((item) => item.isProtected).toList();
        source.add(items);
      },
      onSelect: (_) {},
    )));
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 unread'), findsOneWidget);
    await tester.tap(find.text('Clear messages'));
    await tester.pumpAndSettle();
    expect(find.text('Verify opening'), findsOneWidget);
    expect(find.text('Ordinary message'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bell shows exact red count and hides badge after reading',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NotificationBellButton(
      unreadCount: 125,
      onPressed: () {},
    ))));
    expect(find.text('125'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-unread-count')),
        findsOneWidget);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NotificationBellButton(
      unreadCount: 0,
      onPressed: () {},
    ))));
    expect(
        find.byKey(const ValueKey('notification-unread-count')), findsNothing);
  });

  testWidgets('short desktop window scrolls without overflow', (tester) async {
    tester.view.physicalSize = const Size(800, 340);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
      stream: const Stream.empty(),
      initialItems: [
        NotificationItem(
            id: 1,
            type: 'General',
            title: 'Message',
            desc: 'Details',
            targetRole: 'all')
      ],
      onMarkAllRead: () async {},
      onSelect: (_) {},
    )));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact notification dialog fits with long alerts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: NotificationCenterScreen(
        stream: const Stream.empty(),
        initialItems: [
          NotificationItem(
            id: -1,
            type: 'Inventory',
            targetRole: 'all',
            isOperational: true,
            title: 'Gold long necklace stock low (22KT)',
            desc: '2 pieces available. Check reorder level.',
          )
        ],
        onMarkAllRead: () async {},
        onSelect: (_) {},
      ),
    )));
    expect(tester.takeException(), isNull);
  });
}
