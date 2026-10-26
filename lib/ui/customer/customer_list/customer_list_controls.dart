import 'package:flutter/material.dart';

import '../../../theme/customer/customer_list/customer_list_theme.dart';

class CustomerListFilterChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const CustomerListFilterChipButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CustomerListStyles.chipBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: CustomerListStyles.chipPadding,
        decoration: BoxDecoration(
          color: isActive
              ? CustomerListColors.chipActiveBg
              : CustomerListColors.chipInactiveBg,
          borderRadius:
              BorderRadius.circular(CustomerListStyles.chipBorderRadius),
          border: Border.all(
            color: isActive
                ? CustomerListColors.chipActive
                : CustomerListColors.bodyBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: CustomerListColors.brandGoldDark,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: isActive
                  ? CustomerListStyles.chipActive
                  : CustomerListStyles.chipInactive,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerListToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const CustomerListToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        filled ? CustomerListColors.brandGold : CustomerListColors.bodyPanelBg;
    final border =
        filled ? CustomerListColors.brandGold : CustomerListColors.bodyBorder;
    final foreground = filled ? Colors.black : CustomerListColors.bodyTextMain;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: CustomerListStyles.toolbarButton.copyWith(
                  color: foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerListResultPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const CustomerListResultPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: CustomerListColors.infoBg,
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: CustomerListColors.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CustomerListColors.info),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: CustomerListStyles.resultMeta.copyWith(
                color: CustomerListColors.info,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
