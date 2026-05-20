// =============================================================================
// FILE        : alert_row.dart
// MODULE      : Dashboard / Alert Row
// LAYER       : UI
// DESCRIPTION : 4 Premium Alert Cards â€” dark gradient design.
//               BillCard/ShopCard ke saath consistent dark theme.
//
//               DESIGN:
//               â€¢ Har card ka apna COLOR IDENTITY (red/amber/emerald gradient)
//               â€¢ Glowing STATUS ORB â€” CRITICAL pe pulse animation
//               â€¢ Diagonal SLASH bg decoration â€” premium depth
//               â€¢ Ghost ICON background â€” layered feel
//               â€¢ SEVERITY PROGRESS BAR â€” animated fill
//               â€¢ CRITICAL card mein border glow pulse
//               â€¢ Hover lift effect (desktop)
//               â€¢ Staggered slide+scale entry
//               â€¢ AnimatedSwitcher on value change
//
//               ARCHITECTURE: Theme files se import karta hai
//               (alert_row_colors, alert_row_styles, alert_row_icons)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../logic/dashboard/alert_row/alert_row_logic.dart';
import '../../models/dashboard/alert_card_model.dart';
import '../../theme/dashboard/alert_row/alert_row_theme.dart';

class AlertRow extends StatefulWidget {
  final Function(String routeId) onNavigate;
  const AlertRow({super.key, required this.onNavigate});

  @override
  State<AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends State<AlertRow> with TickerProviderStateMixin {
  late final AlertRowLogic _logic;

  // Staggered entry â€” 4 cards
  late final List<AnimationController> _entryCtrl;
  late final List<Animation<double>> _entrySlide;
  late final List<Animation<double>> _entryFade;
  late final List<Animation<double>> _entryScale;

  // CRITICAL border + orb pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Interaction states
  final Set<String> _hoveredCards = {};
  final Set<String> _pressedArrows = {};

  @override
  void initState() {
    super.initState();
    _logic = AlertRowLogic();

    // Entry animations
    _entryCtrl = List.generate(
        4,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));

    _entrySlide = _entryCtrl
        .map((c) => Tween<double>(begin: 26.0, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    _entryFade = _entryCtrl
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _entryScale = _entryCtrl
        .map((c) => Tween<double>(begin: 0.93, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)))
        .toList();

    // Pulse for CRITICAL cards
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.25, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _playStaggeredEntry();
  }

  Future<void> _playStaggeredEntry() async {
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _entryCtrl[i].forward();
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    for (final c in _entryCtrl) {
      c.dispose();
    }
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, _) {
        final cards = _logic.data.cards;
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    Expanded(child: _buildAnimatedCard(i, cards[i])),
                    if (i < 3) const SizedBox(width: 14),
                  ],
                ],
              );
            }
            return Column(children: [
              Row(children: [
                Expanded(child: _buildAnimatedCard(0, cards[0])),
                const SizedBox(width: 12),
                Expanded(child: _buildAnimatedCard(1, cards[1])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildAnimatedCard(2, cards[2])),
                const SizedBox(width: 12),
                Expanded(child: _buildAnimatedCard(3, cards[3])),
              ]),
            ]);
          },
        );
      },
    );
  }

  // â”€â”€ Staggered entry wrapper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAnimatedCard(int index, AlertCardModel card) {
    return AnimatedBuilder(
      animation: _entryCtrl[index],
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _entrySlide[index].value),
        child: Transform.scale(
          scale: _entryScale[index].value,
          child: Opacity(opacity: _entryFade[index].value, child: child),
        ),
      ),
      child: card.isLoading ? _buildShimmerCard() : _buildCard(card),
    );
  }

  // ==========================================
  // SHIMMER LOADING CARD
  // ==========================================
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: AlertRowColors.shimmerBase,
      highlightColor: AlertRowColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AlertRowColors.shimmerBase,
          borderRadius: BorderRadius.circular(AlertRowStyles.cardBorderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: AlertRowStyles.contentPad,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row
          Row(children: [
            _sBox(7, 7, circle: true),
            const SizedBox(width: 8),
            _sBox(55, 9),
            const Spacer(),
            _sBox(70, 18, radius: 20),
          ]),
          const SizedBox(height: 16),
          // Icon + value row
          Row(children: [
            _sBox(42, 42, circle: true),
            const SizedBox(width: 12),
            _sBox(100, 18),
          ]),
          const SizedBox(height: 9),
          _sBox(130, 10),
          const SizedBox(height: 16),
          // Severity + button row
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _sBox(45, 8),
                  const SizedBox(height: 4),
                  _sBox(double.infinity, 3, radius: 4),
                ])),
            const SizedBox(width: 12),
            _sBox(30, 30, circle: true),
          ]),
        ]),
      ),
    );
  }

  Widget _sBox(double w, double h, {bool circle = false, double radius = 5}) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }

  // ==========================================
  // MAIN CARD â€” Premium dark design
  // ==========================================
  Widget _buildCard(AlertCardModel card) {
    final bool isCritical = card.status == AlertStatus.critical;
    final bool isHovered = _hoveredCards.contains(card.id);
    final Color accent = AlertRowColors.accentFor(card.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCards.add(card.id)),
      onExit: (_) => setState(() => _hoveredCards.remove(card.id)),
      child: GestureDetector(
        onTap: () => widget.onNavigate(card.routeId),
        child: AnimatedScale(
          scale: isHovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              final borderColor = isCritical
                  ? accent.withValues(alpha: _pulseAnim.value * 0.65)
                  : accent.withValues(alpha: 0.18);

              final glowOpacity = isCritical ? _pulseAnim.value * 0.12 : 0.06;

              return Container(
                decoration: AlertRowStyles.cardDecoration(
                  borderColor: borderColor,
                  isCritical: isCritical,
                  accentColor: accent,
                  glowOpacity: glowOpacity,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AlertRowStyles.cardBorderRadius),
                  child: Stack(children: [
                    // â”€â”€ BG: Diagonal slash decoration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Transform.rotate(
                        angle: 0.45,
                        child: Container(
                          width: 68,
                          height: 108,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // â”€â”€ BG: Ghost icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Icon(
                        _iconFor(card.id),
                        size: 72,
                        color: accent.withValues(alpha: 0.05),
                      ),
                    ),

                    // â”€â”€ MAIN CONTENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Padding(
                      padding: AlertRowStyles.contentPad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // â”€â”€ 1. TOP: Orb + Title + Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Row(children: [
                            // Pulsing status orb
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Container(
                                width: AlertRowStyles.orbSize,
                                height: AlertRowStyles.orbSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(
                                        alpha:
                                            isCritical ? _pulseAnim.value : 0.7,
                                      ),
                                      blurRadius: isCritical ? 9 : 5,
                                      spreadRadius: isCritical ? 2 : 0,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),

                            // Card title
                            Expanded(
                              child: Text(
                                card.title.toUpperCase(),
                                style: AlertRowStyles.titleStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Status badge â€” pill shape
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: AlertRowStyles.badge(card.status),
                              child: Text(
                                AlertRowColors.badgeLabelFor(card.status),
                                style: AlertRowStyles.badgeStyle.copyWith(
                                  color:
                                      AlertRowColors.badgeTextFor(card.status),
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 13),

                          // â”€â”€ 2. MIDDLE: Icon circle + Main value â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Glowing icon circle
                              Container(
                                width: AlertRowStyles.iconCircleSize,
                                height: AlertRowStyles.iconCircleSize,
                                decoration:
                                    AlertRowStyles.iconCircle(card.status),
                                child: Center(
                                  child: Icon(
                                    _iconFor(card.id),
                                    size: AlertRowStyles.iconSize,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),

                              // Main value â€” animated on change
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeOutCubic,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                  child: Align(
                                    key: ValueKey(card.mainValue),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      card.mainValue,
                                      style: AlertRowStyles.mainValueStyle(
                                          card.status),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 7),

                          // â”€â”€ 3. SUB TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Text(
                            card.subText,
                            style: AlertRowStyles.subTextStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 13),

                          // â”€â”€ 4. BOTTOM: Severity bar + Arrow button â”€â”€â”€â”€â”€â”€â”€â”€
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Severity progress bar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('SEVERITY',
                                        style:
                                            AlertRowStyles.severityLabelStyle),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        height:
                                            AlertRowStyles.severityBarHeight,
                                        child: Stack(children: [
                                          // Track
                                          Container(
                                              color: Colors.white
                                                  .withValues(alpha: 0.07)),
                                          // Animated fill
                                          AnimatedFractionallySizedBox(
                                            duration: const Duration(
                                                milliseconds: 900),
                                            curve: Curves.easeOutCubic,
                                            widthFactor:
                                                AlertRowColors.severityFillFor(
                                                    card.status),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient:
                                                    LinearGradient(colors: [
                                                  accent.withValues(alpha: 0.5),
                                                  accent,
                                                ]),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Glowing arrow button
                              _buildArrowBtn(card),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // â”€â”€ Arrow Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildArrowBtn(AlertCardModel card) {
    final bool isPressed = _pressedArrows.contains(card.id);
    final Color accent = AlertRowColors.accentFor(card.status);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedArrows.add(card.id)),
      onTapCancel: () => setState(() => _pressedArrows.remove(card.id)),
      onTapUp: (_) {
        setState(() => _pressedArrows.remove(card.id));
        widget.onNavigate(card.routeId);
      },
      child: AnimatedScale(
        scale: isPressed ? 0.83 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Tooltip(
          message: 'Go to ${card.title}',
          child: Container(
            width: AlertRowStyles.arrowBtnSize,
            height: AlertRowStyles.arrowBtnSize,
            decoration: AlertRowStyles.arrowBtn(card.status),
            child: Center(
              child: Icon(
                AlertRowIcons.arrowBtn,
                size: 14,
                color: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ Icon mapping â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  IconData _iconFor(String id) {
    switch (id) {
      case 'inventory':
        return AlertRowIcons.inventory;
      case 'orders':
        return AlertRowIcons.orders;
      case 'collections':
        return AlertRowIcons.collections;
      case 'deliveries':
        return AlertRowIcons.deliveries;
      default:
        return Icons.info_rounded;
    }
  }
}
