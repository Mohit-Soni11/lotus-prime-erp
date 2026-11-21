import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'workspace_transition_page.dart';

/// Opens workspaces above the shell without resizing the dashboard beneath.
GoRoute workspaceRoute({
  required String path,
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required Widget Function(BuildContext, GoRouterState) builder,
}) =>
    GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => WorkspaceTransitionPage(
        key: state.pageKey,
        child: builder(context, state),
      ),
    );
