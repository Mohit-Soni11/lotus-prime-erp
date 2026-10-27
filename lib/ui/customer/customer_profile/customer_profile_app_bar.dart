import 'package:flutter/material.dart';

import '../../../theme/customer/customer_profile/customer_profile_theme.dart';
import '../../shared/system_status_badge.dart';

class CustomerProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomerProfileAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomerProfileStyles.appBarHeight);

  @override
  Widget build(BuildContext context) => Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: CustomerProfileColors.shellPanelBg,
          border: Border(
              bottom: BorderSide(color: CustomerProfileColors.shellBorder)),
        ),
        child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 590;
                return Row(children: [
                  Tooltip(
                    message: 'Back to Customer List',
                    child: IconButton.filledTonal(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: CustomerProfileColors.shellBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                      width: 1,
                      height: 30,
                      color: CustomerProfileColors.shellBorder),
                  const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.brandGold,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(CustomerProfileIcons.moduleIcon,
                        size: 19, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(CustomerProfileStrings.appBarTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomerProfileStyles.appBarTitle)),
                  const SizedBox(width: 8),
                  SystemStatusBadge(
                      status: SystemStatus.online, showLabel: !compact),
                ]);
              },
            )),
      );
}
