// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_section_card.dart
// MODULE  : Tax & GST Configuration
// DESC    : Animated expandable card with spring animation,
//           hover glow, accent border & chevron rotation.
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstSectionCard extends StatefulWidget {
  const TaxGstSectionCard({
    super.key,
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    required this.accentLight,
    required this.isExpanded,
    required this.onTap,
    required this.expandedChild,
  });

  final int         index;
  final IconData    icon;
  final String      title;
  final String      subtitle;
  final String      tag;
  final Color       accentColor;
  final Color       accentLight;
  final bool        isExpanded;
  final VoidCallback onTap;
  final Widget      expandedChild;

  @override
  State<TaxGstSectionCard> createState() => _TaxGstSectionCardState();
}

class _TaxGstSectionCardState extends State<TaxGstSectionCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _expandCtrl;
  late final Animation<double>   _expandAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: TaxGstStyles.animNormal,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve:  Curves.easeInOutCubic,
    );
    if (widget.isExpanded) _expandCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(TaxGstSectionCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded
          ? _expandCtrl.forward()
          : _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: TaxGstStyles.animFast,
        decoration: TaxGstStyles.cardDecoration(
          accentColor: widget.accentColor,
          isHovered:   _hovered,
          isExpanded:  widget.isExpanded,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Card Header (always visible) ─────────────────────
            GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: TaxGstStyles.cardPadding,
                child: Row(
                  children: [

                    // Icon Box
                    AnimatedContainer(
                      duration: TaxGstStyles.animFast,
                      width: TaxGstStyles.iconBoxSize,
                      height: TaxGstStyles.iconBoxSize,
                      decoration: BoxDecoration(
                        color: widget.isExpanded
                            ? widget.accentColor.withOpacity(0.18)
                            : widget.accentLight,
                        borderRadius: BorderRadius.circular(
                            TaxGstStyles.radiusIconBox),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(
                              widget.isExpanded ? 0.40 : 0.22),
                        ),
                        boxShadow: widget.isExpanded
                            ? [
                                BoxShadow(
                                  color: widget.accentColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        size: TaxGstStyles.cardIconSize,
                        color: widget.accentColor,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Title + Subtitle + Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TaxGstStyles.cardTitle(context),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: TaxGstStyles.cardSubtitle(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          // Tag pill
                          Container(
                            padding: TaxGstStyles.chipPadding,
                            decoration: TaxGstStyles.tagDecoration(
                                widget.accentColor),
                            child: Text(
                              widget.tag,
                              style: TaxGstStyles.cardTagText(
                                context,
                                color: widget.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Animated Chevron
                    AnimatedRotation(
                      duration: TaxGstStyles.animNormal,
                      turns: widget.isExpanded ? 0.25 : 0.0,
                      child: Icon(
                        TaxGstIcons.chevronRight,
                        size: 22,
                        color: widget.isExpanded
                            ? widget.accentColor
                            : TaxGstColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Animated Expand Panel ─────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _expandAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Accent divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          widget.accentColor.withOpacity(0.3),
                          widget.accentColor.withOpacity(0.3),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    // Section content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      child: widget.expandedChild,
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
}
