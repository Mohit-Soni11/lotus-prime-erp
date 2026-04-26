// =============================================================================
// FILE : lib/ui/settings/settings_dashboard/settings_ui/settings_card.dart
// SIZING: Larger icon (26px), larger text, better padding, taller card
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../theme/settings/settings_dashboard/settings_theme.dart';
import '../../../../models/setting/settings_model.dart';

class SettingsCard extends StatefulWidget {
  final SettingsModel item;
  final VoidCallback onTap;

  const SettingsCard({super.key, required this.item, required this.onTap});

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _arrowSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.025)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _arrowSlide = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovered = true);
    _ctrl.forward();
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.item.accentColor;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: SettingsStyles.cardPadding,
            decoration: BoxDecoration(
              gradient: SettingsColors.cardGradient,
              borderRadius: BorderRadius.circular(SettingsStyles.cardRadius),
              border: Border.all(
                color: _hovered
                    ? color.withOpacity(0.70)
                    : SettingsColors.cardBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x45000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top Row: Icon Box + Arrow ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colored icon box — larger
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? color.withOpacity(0.22)
                            : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withOpacity(_hovered ? 0.45 : 0.20),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.item.icon, size: 26, color: color),
                    ),

                    // Arrow slides in on hover
                    AnimatedBuilder(
                      animation: _arrowSlide,
                      builder: (_, __) => Transform.translate(
                        offset: Offset((-1 + _arrowSlide.value) * 8, 0),
                        child: Opacity(
                          opacity: _arrowSlide.value,
                          child: Icon(
                            SettingsIcons.navArrow,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Bottom: Title + Subtitle ───────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: SettingsStyles.cardTitle.copyWith(
                        color: _hovered ? color : SettingsColors.textTitle,
                      ),
                      child: Text(widget.item.title, maxLines: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.subtitle,
                      style: SettingsStyles.cardSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
