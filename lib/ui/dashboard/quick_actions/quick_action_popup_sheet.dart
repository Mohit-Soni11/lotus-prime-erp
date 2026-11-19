import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../models/dashboard/quick_action_popup_option.dart';

class QuickActionPopupSheet extends StatefulWidget {
  final String title;
  final Color accentColor;
  final List<QuickActionPopupOption> options;
  final Function(String routeId) onOptionTap;

  const QuickActionPopupSheet({
    super.key,
    required this.title,
    required this.accentColor,
    required this.options,
    required this.onOptionTap,
  });

  @override
  State<QuickActionPopupSheet> createState() => _QuickActionPopupSheetState();
}

class _QuickActionPopupSheetState extends State<QuickActionPopupSheet>
    with TickerProviderStateMixin {
  late final List<AnimationController> _cardControllers;
  late final List<Animation<double>> _cardSlides;
  late final List<Animation<double>> _cardFades;
  String? _pressedOptionId;

  @override
  void initState() {
    super.initState();
    _cardControllers = List.generate(
      widget.options.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350)),
    );
    _cardSlides = _cardControllers
        .map((c) => Tween<double>(begin: 30.0, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();
    _cardFades = _cardControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _playCardEntry();
  }

  Future<void> _playCardEntry() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (mounted) _cardControllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).top -
              12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // â”€â”€ Drag handle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    // Gold accent line
                    Container(
                        width: 3,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withValues(alpha: 0.7)
                        ],
                      ).createShader(b),
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )),
                  ],
                ),

                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select an option to proceed', // <-- Changed to professional English
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // â”€â”€ Option Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                ...List.generate(widget.options.length, (i) {
                  final opt = widget.options[i];
                  return AnimatedBuilder(
                    animation: _cardControllers[i],
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _cardSlides[i].value),
                      child:
                          Opacity(opacity: _cardFades[i].value, child: child),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOptionCard(opt),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(QuickActionPopupOption opt) {
    final bool isPressed = _pressedOptionId == opt.id;

    return GestureDetector(
      key: ValueKey('quick-action-option-${opt.id}'),
      onTapDown: (_) => setState(() => _pressedOptionId = opt.id),
      onTapCancel: () => setState(() => _pressedOptionId = null),
      onTap: () {
        setState(() => _pressedOptionId = null);
        widget.onOptionTap(opt.routeId);
      },
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isPressed
                ? opt.accentColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPressed
                  ? opt.accentColor.withValues(alpha: 0.5)
                  : opt.accentColor.withValues(alpha: 0.18),
              width: isPressed ? 1.5 : 1.0,
            ),
            boxShadow: isPressed
                ? [
                    BoxShadow(
                        color: opt.accentColor.withValues(alpha: 0.15),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: opt.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: opt.accentColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(opt.icon, color: opt.accentColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPressed
                            ? opt.accentColor
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.45),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPressed
                      ? opt.accentColor.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPressed
                      ? opt.accentColor
                      : Colors.white.withValues(alpha: 0.3),
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
