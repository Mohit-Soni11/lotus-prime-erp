import 'package:flutter/material.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_profile/supplier_profile_theme.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

class SupplierProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SupplierProfileAppBar({
    super.key,
    required this.onBack,
    this.status = SystemStatus.online,
  });

  final VoidCallback onBack;
  final SystemStatus status;

  @override
  Size get preferredSize =>
      const Size.fromHeight(SupplierProfileStyles.appBarHeight);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 500 ? 12 : 20),
          decoration: const BoxDecoration(
            color: SupplierProfileColors.shellPanelBg,
            border: Border(
                bottom: BorderSide(color: SupplierProfileColors.shellBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              Material(
                color: SupplierProfileColors.shellBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: const Tooltip(
                    message: 'Back',
                    child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_rounded,
                            color: SupplierProfileColors.shellTextTitle)),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              if (constraints.maxWidth >= 500) ...[
                Container(
                    width: 1,
                    height: 32,
                    color: SupplierProfileColors.shellBorder),
                const SizedBox(width: 18),
              ],
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    SupplierProfileColors.brandGoldStart,
                    SupplierProfileColors.brandGold,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(SupplierProfileIcons.moduleIcon,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text('SUPPLIER PROFILE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SupplierProfileStyles.appBarTitle)),
              SystemStatusBadge(
                  status: status, showLabel: constraints.maxWidth >= 650),
            ]),
          ),
        ),
      );
}
