// =============================================================================
// FILE        : quick_actions_card.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : UI
// DESCRIPTION : Dashboard shortcuts with contextual action sheets.
// =============================================================================

import 'package:flutter/material.dart';

import '../../logic/dashboard/quick_actions/quick_actions_logic.dart';
import 'quick_actions/quick_action_popup_sheet.dart';
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
  Future<void> _showPopup(QuickActionItemModel item) async {
    final options = _logic.getPopupOptions(item.id);
    final title = _logic.getPopupTitle(item.id);

    final routeId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetContext) => QuickActionPopupSheet(
        title: title,
        accentColor: item.accentColor,
        options: options,
        onOptionTap: (selectedRouteId) =>
            Navigator.of(sheetContext).pop(selectedRouteId),
      ),
    );
    if (mounted && routeId != null) widget.onNavigate(routeId);
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
                    ...List.generate(
                      (QuickActionsLogic.actions.length + 1) ~/ 2,
                      (rowIndex) {
                        final firstIndex = rowIndex * 2;
                        final secondIndex = firstIndex + 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            top: rowIndex == 0
                                ? 0
                                : QuickActionsStyles.rowSpacing,
                          ),
                          child: Row(
                            children: [
                              _buildAnimatedButton(
                                index: firstIndex,
                                item: QuickActionsLogic.actions[firstIndex],
                              ),
                              const SizedBox(
                                  width: QuickActionsStyles.buttonSpacing),
                              if (secondIndex <
                                  QuickActionsLogic.actions.length)
                                _buildAnimatedButton(
                                  index: secondIndex,
                                  item: QuickActionsLogic.actions[secondIndex],
                                )
                              else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        );
                      },
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
              key: ValueKey('quick-action-${item.id}'),
              onTapDown: (_) => _logic.onButtonTapDown(item.id),
              onTapCancel: () => _logic.onButtonTapCancel(),
              onTap: () {
                // âœ… Separate logic for popup vs direct navigation
                if (item.hasPopup) {
                  _logic.onButtonTapCancel();
                  _showPopup(item);
                } else {
                  _logic.onDirectButtonTap(item.id, widget.onNavigate);
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
