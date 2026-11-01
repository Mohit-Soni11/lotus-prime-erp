import 'package:flutter/material.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

class SupplierListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SupplierListAppBar({
    super.key,
    required this.onBack,
    this.status = SystemStatus.online,
  });

  final VoidCallback onBack;
  final SystemStatus status;

  @override
  Size get preferredSize =>
      const Size.fromHeight(SupplierListStyles.appBarHeight);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Container(
            height: preferredSize.height,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            decoration: const BoxDecoration(
              color: SupplierListColors.shellPanelBg,
              border: Border(
                  bottom: BorderSide(color: SupplierListColors.shellBorder)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(children: [
                Material(
                  color: SupplierListColors.shellBorder.withValues(alpha: 0.3),
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
                            color: SupplierListColors.shellTextTitle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                if (!compact) ...[
                  Container(
                      width: 1,
                      height: 32,
                      color: SupplierListColors.shellBorder),
                  const SizedBox(width: 18),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      SupplierListColors.goldGradientStart,
                      SupplierListColors.brandGold,
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(SupplierListIcons.moduleIcon,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(SupplierListStrings.appBarTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SupplierListStyles.appBarTitle),
                ),
                SystemStatusBadge(
                    status: status, showLabel: constraints.maxWidth >= 650),
              ]),
            ),
          );
        },
      );
}
