import 'package:flutter/material.dart';

import '../../../theme/customer/customer_list/customer_list_theme.dart';
import '../../shared/system_status_badge.dart';

class CustomerListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final SystemStatus status;

  const CustomerListAppBar({
    super.key,
    required this.onBack,
    this.status = SystemStatus.online,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomerListStyles.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Container(
        height: CustomerListStyles.appBarHeight,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
        decoration: const BoxDecoration(
          color: CustomerListColors.shellPanelBg,
          border: Border(
            bottom: BorderSide(color: CustomerListColors.shellBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Material(
                color: CustomerListColors.shellBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: const Tooltip(
                    message: 'Back',
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        CustomerListIcons.backArrow,
                        color: CustomerListColors.shellTextTitle,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 18),
              if (!compact) ...[
                Container(
                  width: 1,
                  height: 32,
                  color: CustomerListColors.shellBorder,
                ),
                const SizedBox(width: 18),
              ],
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomerListColors.goldGradientStart,
                      CustomerListColors.brandGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CustomerListIcons.moduleIcon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Text(
                  CustomerListStrings.appBarTitle,
                  style: CustomerListStyles.appBarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SystemStatusBadge(
                status: status,
                showLabel: constraints.maxWidth >= 650,
              ),
            ],
          ),
        ),
      );
    });
  }
}
