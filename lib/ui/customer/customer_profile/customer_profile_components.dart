import 'package:flutter/material.dart';

import '../../../theme/customer/customer_profile/customer_profile_theme.dart';

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

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<CustomerProfileActionBtn> createState() =>
      CustomerProfileActionBtnState();
}

class CustomerProfileActionBtnState extends State<CustomerProfileActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.border.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          onHover: (hovered) => setState(() => _hovered = hovered),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.icon, color: widget.fg, size: 19),
                const SizedBox(width: 7),
                Flexible(
                    child: Text(widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: widget.fg))),
              ]),
            ),
          ),
        ),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: textColor.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: CustomerProfileColors.bodyTextMain)),
      );
}

class CustomerProfileConvertToSaleButton extends StatelessWidget {
  const CustomerProfileConvertToSaleButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(CustomerProfileIcons.advanceConvert, size: 18),
        label: const Text(CustomerProfileStrings.convertToSale),
        style: OutlinedButton.styleFrom(
          foregroundColor: CustomerProfileColors.bodyTextMain,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          side: const BorderSide(color: CustomerProfileColors.advanceAccent),
          minimumSize: const Size.fromHeight(42),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}
