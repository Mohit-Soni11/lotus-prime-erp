// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_action_button.dart
// MODULE  : Tax & GST Configuration
// DESC    : Hover-animated Edit / Save / Cancel button.
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstActionButton extends StatefulWidget {
  const TaxGstActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.isFilled  = false,
    this.isSaving  = false,
  });

  final String        label;
  final IconData      icon;
  final Color         accentColor;
  final VoidCallback? onTap;
  final bool          isFilled;
  final bool          isSaving;

  @override
  State<TaxGstActionButton> createState() => _TaxGstActionButtonState();
}

class _TaxGstActionButtonState extends State<TaxGstActionButton>
    with SingleTickerProviderStateMixin {

  late final AnimationController _hoverCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: TaxGstStyles.animFast,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _hoverCtrl.forward(),
      onExit:  (_) => _hoverCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (_, __) => Container(
              padding: TaxGstStyles.btnPadding,
              decoration: TaxGstStyles.btnDecoration(
                color:     widget.accentColor,
                isFilled:  widget.isFilled,
                isHovered: _hoverCtrl.value > 0.3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isSaving)
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: widget.isFilled
                            ? Colors.white
                            : widget.accentColor,
                      ),
                    )
                  else
                    Icon(
                      widget.icon,
                      size: 13,
                      color: widget.isFilled
                          ? Colors.white
                          : widget.accentColor,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TaxGstStyles.btnText(
                      context,
                      color: widget.isFilled
                          ? Colors.white
                          : widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
