// =============================================================================
// FILE        : quick_actions_card.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : UI
// DESCRIPTION : Four quick action buttons in a 2x2 grid.
//               "New Entry" opens New Sale, Customer Metal Purchase,
//               Collateral / Loan, and Booking Advance actions.
//               "Adjust" opens Due Adjust and Interest Payment actions.
//               "Add Stock" and "Cash Book" navigate directly.
//
//               POPUP DESIGN:
//               Dark glassmorphism bottom sheet with labeled option cards,
//               slide-up motion, backdrop blur, and selection feedback.
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../logic/dashboard/quick_actions/quick_actions_logic.dart';
import '../../../models/dashboard/quick_action_item_model.dart';
import '../../theme/dashboard/quick_actions/quick_actions_theme.dart';

class QuickActionsCard extends StatefulWidget {
  final Function(String routeId) onNavigate;

  const QuickActionsCard({
    super.key,
    required this.onNavigate,
  });

  @override
  State<QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends State<QuickActionsCard>
    with TickerProviderStateMixin {
  late final QuickActionsLogic _logic;

  // Staggered entry animations
  late final List<AnimationController> _entryControllers;
  late final List<Animation<double>> _entrySlides;
  late final List<Animation<double>> _entryFades;

  @override
  void initState() {
    super.initState();
    _logic = QuickActionsLogic();
    _setupEntryAnimations();
    _playStaggeredEntry();
  }

  void _setupEntryAnimations() {
    _entryControllers = List.generate(
      QuickActionsLogic.actions.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _entrySlides = _entryControllers
        .map((c) => Tween<double>(begin: 24.0, end: 0.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
            ))
        .toList();
    _entryFades = _entryControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();
  }

  Future<void> _playStaggeredEntry() async {
    for (int i = 0; i < _entryControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _entryControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    for (final c in _entryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================
  // POPUP BOTTOM SHEET
  // ==========================================
  void _showPopup(BuildContext context, QuickActionItemModel item) {
    final options = _logic.getPopupOptions(item.id);
    final title = _logic.getPopupTitle(item.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _QuickActionPopupSheet(
        title: title,
        accentColor: item.accentColor,
        options: options,
        onOptionTap: (routeId) {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 200), () {
            widget.onNavigate(routeId);
          });
        },
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: QuickActionsStyles.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QuickActionsStyles.borderRadius),
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(child: _AmbientGlows()),
            ),
            Padding(
              padding: QuickActionsStyles.cardPadding,
              child: ListenableBuilder(
                listenable: _logic,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 4),
                    _buildGoldenDivider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildAnimatedButton(
                            index: 0, item: QuickActionsLogic.actions[0]),
                        const SizedBox(width: QuickActionsStyles.buttonSpacing),
                        _buildAnimatedButton(
                            index: 1, item: QuickActionsLogic.actions[1]),
                      ],
                    ),
                    const SizedBox(height: QuickActionsStyles.rowSpacing),
                    Row(
                      children: [
                        _buildAnimatedButton(
                            index: 2, item: QuickActionsLogic.actions[2]),
                        const SizedBox(width: QuickActionsStyles.buttonSpacing),
                        _buildAnimatedButton(
                            index: 3, item: QuickActionsLogic.actions[3]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
          ).createShader(b),
          child: const Icon(QuickActionsIcons.header,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
          ).createShader(b),
          child: const Text(QuickActionsStrings.cardTitle,
              style: QuickActionsStyles.headerStyle),
        ),
      ],
    );
  }

  // â”€â”€ Golden Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildGoldenDivider() {
    const dot = SizedBox(
      width: 4,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QuickActionsColors.divider,
          shape: BoxShape.circle,
        ),
      ),
    );
    return const Row(
      children: [
        dot,
        Expanded(
            child: SizedBox(
                height: 1,
                child: ColoredBox(color: QuickActionsColors.divider))),
        dot,
      ],
    );
  }

  // â”€â”€ Animated Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAnimatedButton({
    required int index,
    required QuickActionItemModel item,
  }) {
    final bool isPressed = _logic.isPressed(item.id);
    final bool isHovered = _logic.isHovered(item.id);

    final decoration = isPressed
        ? QuickActionsStyles.btnPressed(item.accentColor)
        : isHovered
            ? QuickActionsStyles.btnHover(item.accentColor)
            : QuickActionsStyles.btnNormal(item.accentColor);

    return Expanded(
      child: AnimatedBuilder(
        animation: _entryControllers[index],
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _entrySlides[index].value),
          child: Opacity(opacity: _entryFades[index].value, child: child),
        ),
        child: AnimatedScale(
          scale: isPressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: MouseRegion(
            onEnter: (_) => _logic.onHoverEnter(item.id),
            onExit: (_) => _logic.onHoverExit(),
            child: GestureDetector(
              onTapDown: (_) => _logic.onButtonTapDown(item.id),
              onTapCancel: () => _logic.onButtonTapCancel(),
              onTapUp: (_) {
                // âœ… Separate logic for popup vs direct navigation
                if (item.hasPopup) {
                  _logic.onButtonTapCancel();
                  _showPopup(context, item);
                } else {
                  _logic.onDirectButtonTapUp(item.id, widget.onNavigate);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: QuickActionsStyles.buttonHeight,
                decoration: decoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: QuickActionsStyles.iconCircleSize,
                        height: QuickActionsStyles.iconCircleSize,
                        decoration:
                            QuickActionsStyles.iconCircle(item.accentColor),
                        child: Center(
                          child: AnimatedScale(
                            scale: isPressed ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Icon(item.icon,
                                size: QuickActionsStyles.iconSize,
                                color: item.accentColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Label + popup indicator
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 100),
                              style: isPressed
                                  ? QuickActionsStyles.btnLabelPressedStyle
                                  : QuickActionsStyles.btnLabelStyle,
                              child: Text(item.label,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            // âœ… Small chevron hint for popup buttons
                            if (item.hasPopup)
                              Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 11,
                                    color:
                                        item.accentColor.withValues(alpha: 0.7),
                                  ),
                                  Text(
                                    'select',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: item.accentColor
                                          .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
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

// ============================================================================
// POPUP BOTTOM SHEET WIDGET
// Beautiful dark glassmorphism sheet with option cards
// ============================================================================
class _QuickActionPopupSheet extends StatefulWidget {
  final String title;
  final Color accentColor;
  final List<QuickActionPopupOption> options;
  final Function(String routeId) onOptionTap;

  const _QuickActionPopupSheet({
    required this.title,
    required this.accentColor,
    required this.options,
    required this.onOptionTap,
  });

  @override
  State<_QuickActionPopupSheet> createState() => _QuickActionPopupSheetState();
}

class _QuickActionPopupSheetState extends State<_QuickActionPopupSheet>
    with TickerProviderStateMixin {
  late final AnimationController _sheetController;
  late final List<AnimationController> _cardControllers;
  late final List<Animation<double>> _cardSlides;
  late final List<Animation<double>> _cardFades;
  String? _pressedOptionId;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
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

    _sheetController.forward();
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
    _sheetController.dispose();
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
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.7)
                      ],
                    ).createShader(b),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
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
                    child: Opacity(opacity: _cardFades[i].value, child: child),
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
    );
  }

  Widget _buildOptionCard(QuickActionPopupOption opt) {
    final bool isPressed = _pressedOptionId == opt.id;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedOptionId = opt.id),
      onTapCancel: () => setState(() => _pressedOptionId = null),
      onTapUp: (_) {
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

// ============================================================================
// AMBIENT GLOWS
// ============================================================================
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QuickActionsColors.glowTopRight,
              boxShadow: [
                BoxShadow(
                    color: QuickActionsColors.glowTopRight,
                    blurRadius: 60,
                    spreadRadius: 10)
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QuickActionsColors.glowBottomLeft,
              boxShadow: [
                BoxShadow(
                    color: QuickActionsColors.glowBottomLeft,
                    blurRadius: 40,
                    spreadRadius: 5)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
