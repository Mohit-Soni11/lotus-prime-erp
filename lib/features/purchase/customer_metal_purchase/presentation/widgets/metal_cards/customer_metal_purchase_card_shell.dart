import 'package:flutter/material.dart';

class CustomerMetalPurchaseCardShell extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;
  final Widget child;

  const CustomerMetalPurchaseCardShell({
    super.key,
    required this.animationController,
    required this.delay,
    required this.accent,
    required this.surface,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay.clamp(0.0, 0.85),
          (delay + 0.36).clamp(0.12, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          delay.clamp(0.0, 0.85),
          (delay + 0.36).clamp(0.12, 1.0),
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
            borderRadius: BorderRadius.circular(8),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            hoverColor: accent.withValues(alpha: 0.03),
            child: Ink(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
