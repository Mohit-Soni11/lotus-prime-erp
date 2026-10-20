import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/workspace_navigation.dart';
import 'package:lotus_erp/core/router/workspace_transition_page.dart';

void main() {
  testWidgets('back returns to the mounted dashboard through the transition',
      (tester) async {
    var dashboardMounts = 0;
    final router = GoRouter(
      initialLocation: RoutePaths.dashboard,
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => WorkspaceTransitionPage(
            key: state.pageKey,
            child: child,
          ),
          routes: [
            GoRoute(
              path: RoutePaths.dashboard,
              builder: (context, state) => _DashboardProbe(
                onMount: () => dashboardMounts++,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.girviNew,
          pageBuilder: (context, state) => WorkspaceTransitionPage(
            key: state.pageKey,
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => WorkspaceNavigation.backTo(
                    context,
                    RoutePaths.dashboard,
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(dashboardMounts, 1);

    await tester.tap(find.text('Open Pledge'));
    await tester.pumpAndSettle();
    expect(find.text('Back to Dashboard'), findsOneWidget);

    await tester.tap(find.text('Back to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Open Pledge'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(dashboardMounts, 1);
  });
}

class _DashboardProbe extends StatefulWidget {
  const _DashboardProbe({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_DashboardProbe> createState() => _DashboardProbeState();
}

class _DashboardProbeState extends State<_DashboardProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => WorkspaceNavigation.open(
            context,
            RoutePaths.girviNew,
          ),
          child: const Text('Open Pledge'),
        ),
      ),
    );
  }
}
