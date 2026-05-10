// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_toggle_row.dart
// MODULE  : Tax & GST Configuration
// DESC    : Animated toggle row with icon box, title, subtitle.
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstToggleRow extends StatefulWidget {
  const TaxGstToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.isEnabled,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData          icon;
  final String            title;
  final String            subtitle;
  final bool              value;
  final Color             accentColor;
  final bool              isEnabled;
  final ValueChanged<bool> onChanged;
  final bool              showDivider;

  @override
  State<TaxGstToggleRow> createState() => _TaxGstToggleRowState();
}

class _TaxGstToggleRowState extends State<TaxGstToggleRow>
    with SingleTickerProviderStateMixin {

  late AnimationController _switchCtrl;
  late Animation<double>   _thumbAnim;
  late Animation<Color?>   _trackAnim;

  @override
  void initState() {
    super.initState();
    _switchCtrl = AnimationController(
      vsync: this,
      duration: TaxGstStyles.animFast,
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _switchCtrl, curve: Curves.easeInOut),
    );
    _trackAnim = ColorTween(
      begin: const Color(0xFFD1D5DB),
      end:   widget.accentColor,
    ).animate(_switchCtrl);
  }

  @override
  void didUpdateWidget(TaxGstToggleRow old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      widget.value ? _switchCtrl.forward() : _switchCtrl.reverse();
    }
  }

  @override
  void dispose() { _switchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Icon box
              Container(
                width: TaxGstStyles.iconBoxSizeSmall,
                height: TaxGstStyles.iconBoxSizeSmall,
                decoration: BoxDecoration(
                  color: widget.value
                      ? widget.accentColor.withOpacity(0.12)
                      : TaxGstColors.sectionSeparator,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.icon,
                  size: TaxGstStyles.sectionIconSize,
                  color: widget.value
                      ? widget.accentColor
                      : TaxGstColors.textDisabled,
                ),
              ),
              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TaxGstStyles.toggleTitle(context)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: TaxGstStyles.toggleSubtitle(context)),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Custom animated toggle
              GestureDetector(
                onTap: widget.isEnabled
                    ? () => widget.onChanged(!widget.value)
                    : null,
                child: AnimatedBuilder(
                  animation: _switchCtrl,
                  builder: (_, __) => Opacity(
                    opacity: widget.isEnabled ? 1.0 : 0.5,
                    child: Container(
                      width: 46,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _trackAnim.value,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Align(
                          alignment: Alignment.lerp(
                            Alignment.centerLeft,
                            Alignment.centerRight,
                            _thumbAnim.value,
                          )!,
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: TaxGstColors.dividerColor,
          ),
      ],
    );
  }
}
