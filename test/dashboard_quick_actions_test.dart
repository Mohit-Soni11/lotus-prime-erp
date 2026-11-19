import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/logic/dashboard/quick_actions/quick_actions_logic.dart';
import 'package:lotus_erp/ui/dashboard/quick_actions_card.dart';

void main() {
  test('every quick action points to a mapped feature route', () {
    final directActions =
        QuickActionsLogic.actions.where((action) => !action.hasPopup);
    final popupActions = [
      ...QuickActionsLogic.newEntryOptions,
      ...QuickActionsLogic.collectionOptions,
    ];

    for (final action in directActions) {
      expect(action.routeId, isNotEmpty, reason: action.label);
      expect(RouteMapper.toPath(action.routeId), isNot(RoutePaths.dashboard),
          reason: action.label);
    }
    for (final option in popupActions) {
      expect(RouteMapper.toPath(option.routeId), isNot(RoutePaths.dashboard),
          reason: option.label);
    }
  });

  testWidgets('direct actions and every popup option dispatch their own route',
      (tester) async {
    final navigatedRoutes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: QuickActionsCard(onNavigate: navigatedRoutes.add),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final action in QuickActionsLogic.actions.where((a) => !a.hasPopup)) {
      await tester.tap(find.byKey(ValueKey('quick-action-${action.id}')));
      await tester.pumpAndSettle();
      expect(navigatedRoutes.last, action.routeId);
    }

    for (final popupAction
        in QuickActionsLogic.actions.where((a) => a.hasPopup)) {
      final options = popupAction.id == 'new_entry'
          ? QuickActionsLogic.newEntryOptions
          : QuickActionsLogic.collectionOptions;
      for (final option in options) {
        await tester
            .tap(find.byKey(ValueKey('quick-action-${popupAction.id}')));
        await tester.pumpAndSettle();
        await tester
            .tap(find.byKey(ValueKey('quick-action-option-${option.id}')));
        await tester.pumpAndSettle();
        expect(navigatedRoutes.last, option.routeId);
      }
    }
  });

  testWidgets('quick action popup remains usable in a compact window',
      (tester) async {
    tester.view.physicalSize = const Size(360, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickActionsCard(onNavigate: routes.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-action-new_entry')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
        find.byKey(const ValueKey('quick-action-option-booking_advance')));
    await tester
        .tap(find.byKey(const ValueKey('quick-action-option-booking_advance')));
    await tester.pumpAndSettle();
    expect(routes.single, AppRoutes.bookingAdvanceRoute);
  });
}
