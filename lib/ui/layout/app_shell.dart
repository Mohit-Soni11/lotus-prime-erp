// =============================================================================
// FILE        : app_shell.dart
// LAYER       : UI / Layout
// DESCRIPTION : Clean layout shell — sidebar + animated content area.
//               NO routing logic. NO if-else. NO screen imports.
//               The router (go_router) decides WHAT child to show.
//               This widget decides HOW to show it (layout, animation, responsive).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../theme/dashboard/app/uv.dart';
import 'sidebar/custom_sidebar.dart';
import 'application_exit_flow.dart';
import '../../database/db/app_database.dart';
import '../../features/business_day/data/business_day_repository.dart';
import '../../core/logging/app_logger.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _exitInProgress = false;

  @override
  void initState() {
    super.initState();
    _recordBusinessOpening();
  }

  Future<void> _recordBusinessOpening() async {
    try {
      await BusinessDayRepository(AppDatabase()).activeDay(DateTime.now());
    } catch (error) {
      AppLogger.error('Business opening could not be recorded: $error');
    }
  }

  Future<void> _exitBusinessDay() async {
    if (_exitInProgress) return;
    _exitInProgress = true;
    try {
      await ApplicationExitFlow.run(context);
    } finally {
      _exitInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    final location = GoRouterState.of(context).matchedLocation;
    final showShellNavigation =
        location == RoutePaths.dashboard || location == RoutePaths.settings;

    return Scaffold(
      backgroundColor: UV.colors.bgPrimary,

      // ── Mobile Drawer ────────────────────────────────────────────────────────
      drawer: isSmallScreen && showShellNavigation
          ? Drawer(
              child: CustomSidebar(
                onExitApp: _exitBusinessDay,
              ),
            )
          : null,

      // ── Mobile AppBar ────────────────────────────────────────────────────────
      appBar: isSmallScreen && showShellNavigation
          ? AppBar(
              backgroundColor: UV.colors.bgPrimary,
              title: Text(
                'LOTUS ERP',
                style: UV.styles.hero.copyWith(fontSize: 20),
              ),
              centerTitle: true,
              iconTheme: IconThemeData(color: UV.colors.textPrimary),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: UV.colors.glassBorder,
                  height: 1,
                ),
              ),
            )
          : null,

      // ── Body: Sidebar + Content ──────────────────────────────────────────────
      body: Row(
        children: [
          // Desktop Sidebar
          if (!isSmallScreen && showShellNavigation)
            CustomSidebar(
              onExitApp: _exitBusinessDay,
            ),

          // Content Area
          Expanded(
            child: Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: UV.colors.bgSecondary.withValues(alpha: 0.5),
                border: Border(
                  left: BorderSide(
                    color: showShellNavigation
                        ? UV.colors.glassBorder
                        : Colors.transparent,
                    width: showShellNavigation ? 1 : 0,
                  ),
                ),
                boxShadow: [
                  if (!isSmallScreen && showShellNavigation)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(-4, 0),
                    ),
                ],
              ),
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  child: KeyedSubtree(
                    key: ValueKey(
                      GoRouterState.of(context).matchedLocation,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
