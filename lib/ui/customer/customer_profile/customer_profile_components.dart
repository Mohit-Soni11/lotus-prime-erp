import 'package:flutter/material.dart';

import '../../../theme/customer/customer_profile/customer_profile_theme.dart';

// STAT BOX
class CustomerProfileStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;

  const CustomerProfileStatBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CustomerProfileColors.bodyTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub!,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomerProfileBillStatusChip extends StatelessWidget {
  const CustomerProfileBillStatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ACTION BUTTON
class CustomerProfileRecordAction {
  const CustomerProfileRecordAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class CustomerProfileActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final bool filled;
  final VoidCallback onTap;

  const CustomerProfileActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<CustomerProfileActionBtn> createState() =>
      CustomerProfileActionBtnState();
}

class CustomerProfileActionBtnState extends State<CustomerProfileActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.border, width: widget.filled ? 0 : 1.5),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.border.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.fg, size: 20),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.fg,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TYPE TOGGLE (Regular / VIP)
class CustomerProfileTypeToggle extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const CustomerProfileTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ["Regular", "VIP"].map((type) {
        final bool active = value == type;
        final Color color = type == "VIP"
            ? CustomerProfileColors.vipText
            : CustomerProfileColors.editText;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? (type == "VIP"
                      ? CustomerProfileColors.vipBg
                      : CustomerProfileColors.editBg)
                  : CustomerProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? color : CustomerProfileColors.bodyBorder,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? color : CustomerProfileColors.bodyTextMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// CONVERT TO SALE BUTTON
class CustomerProfileConvertToSaleButton extends StatefulWidget {
  final VoidCallback onTap;
  const CustomerProfileConvertToSaleButton({
    super.key,
    required this.onTap,
  });

  @override
  State<CustomerProfileConvertToSaleButton> createState() =>
      CustomerProfileConvertToSaleButtonState();
}

class CustomerProfileConvertToSaleButtonState
    extends State<CustomerProfileConvertToSaleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: _hovered
                ? CustomerProfileColors.advanceConvertBtn
                : CustomerProfileColors.advanceBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CustomerProfileColors.advanceConvertBtn,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: CustomerProfileColors.advanceConvertBtn
                          .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CustomerProfileIcons.advanceConvert,
                size: 16,
                color: _hovered
                    ? CustomerProfileColors.advanceConvertText
                    : CustomerProfileColors.advanceConvertBtn,
              ),
              const SizedBox(width: 8),
              Text(
                CustomerProfileStrings.convertToSale,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _hovered
                      ? CustomerProfileColors.advanceConvertText
                      : CustomerProfileColors.advanceConvertBtn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
