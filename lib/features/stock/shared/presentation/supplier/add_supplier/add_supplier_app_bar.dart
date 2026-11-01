import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/application/add_supplier_logic.dart';
import 'package:lotus_erp/theme/stock/supplier/add_supplier/add_supplier_theme.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

class AddSupplierAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AddSupplierAppBar({
    super.key,
    required this.onBack,
    required this.logic,
  });

  final VoidCallback onBack;
  final AddSupplierLogic logic;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AddSupplierStyles.appBarHeight);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 500 ? 12 : 20),
          decoration: const BoxDecoration(
            color: AddSupplierColors.shellPanelBg,
            border: Border(
                bottom: BorderSide(color: AddSupplierColors.shellBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              Material(
                color: AddSupplierColors.shellBorder.withValues(alpha: 0.3),
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
                            color: AddSupplierColors.shellTextTitle)),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              if (constraints.maxWidth >= 500) ...[
                Container(
                    width: 1, height: 32, color: AddSupplierColors.shellBorder),
                const SizedBox(width: 18),
              ],
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AddSupplierColors.goldGradientStart,
                    AddSupplierColors.brandGold,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AddSupplierIcons.moduleIcon,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  logic.isEditMode
                      ? AddSupplierStrings.appBarTitleEdit
                      : AddSupplierStrings.appBarTitleAdd,
                  style: AddSupplierStyles.appBarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SystemStatusBadge(
                status: logic.isSaving
                    ? SystemStatus.loading
                    : logic.errorMessage != null
                        ? SystemStatus.unavailable
                        : SystemStatus.online,
                showLabel: constraints.maxWidth >= 650,
              ),
            ]),
          ),
        ),
      );
}
