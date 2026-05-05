import 'package:flutter/material.dart';

class MetalCardShell extends StatefulWidget {
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
  State<MetalCardShell> createState() => _MetalCardShellState();
}

class _MetalCardShellState extends State<MetalCardShell> {
  bool _hovered = false;
  bool _pressed = false;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    final begin = widget.delay;
    final end = (widget.delay + 0.55).clamp(0.0, 1.0);

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(begin, end, curve: Curves.easeOutQuart),
      ),
    );

    _slideIn =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(begin, end, curve: Curves.easeOutQuart),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            child: AnimatedScale(
              scale: _pressed
                  ? 0.98
                  : _hovered
                      ? 1.01
                      : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                constraints: const BoxConstraints(minHeight: 250),
                decoration: BoxDecoration(
                  color: widget.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _hovered
                        ? widget.accent.withOpacity(0.45)
                        : widget.accent.withOpacity(0.18),
                    width: _hovered ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovered
                          ? widget.accent.withOpacity(0.16)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: _hovered ? 26 : 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -30,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _hovered ? 160 : 140,
                          height: _hovered ? 160 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accent.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
