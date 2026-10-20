import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A short, consistent transition for the dashboard and pledge workspaces.
class WorkspaceTransitionPage extends CustomTransitionPage<void> {
  const WorkspaceTransitionPage({
    required super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: _buildTransition,
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final progress = animation.drive(CurveTween(curve: Curves.easeInOutCubic));
    return FadeTransition(
      opacity: Tween<double>(begin: 0.86, end: 1).animate(progress),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.015, 0),
          end: Offset.zero,
        ).animate(progress),
        child: child,
      ),
    );
  }
}
