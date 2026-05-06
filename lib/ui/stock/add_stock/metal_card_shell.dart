// =============================================================================
// FILE        : metal_card_shell.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / Widgets
// DESCRIPTION : Animated card shell used by all metal stock cards.
//               Slide-up + fade-in animation with accent border and surface.
// =============================================================================

import 'package:flutter/material.dart';

class MetalCardShell extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;
  final Widget child;

  const MetalCardShell({
    super.key,
    required this.animationController,
    required this.delay,
    required this.accent,
    required this.surface,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Slide + fade animation with per-card delay
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay.clamp(0.0, 0.9),
          (delay + 0.35).clamp(0.1, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay.clamp(0.0, 0.9),
          (delay + 0.35).clamp(0.1, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: accent.withOpacity(0.08),
            highlightColor: accent.withOpacity(0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withOpacity(0.22),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.10),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
