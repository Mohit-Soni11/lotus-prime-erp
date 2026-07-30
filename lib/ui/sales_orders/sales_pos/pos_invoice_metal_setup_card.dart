import 'package:flutter/material.dart';

import '../../../features/settings/billing_setup/sales/domain/sales_billing_metal_profile.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'pos_shop_print_profile_drawer.dart';
import 'pos_sales_billing_profile_drawer.dart';

class PosInvoiceMetalSetupCard extends StatelessWidget {
  final MetalType metal;
  final PosInvoiceController controller;
  final Color accentColor;

  const PosInvoiceMetalSetupCard({
    super.key,
    required this.metal,
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fields = SalesBillingMetalProfiles.fieldsFor(metal.name);
    final activeFieldCount =
        fields.where((field) => _fieldEnabled(field.key)).length;

    return _SetupCardShell(
      accentColor: accentColor,
      child: Column(
        children: [
          _SetupHeader(
            icon: Icons.tune_rounded,
            title: '${metal.displayName} Display Profile',
            subtitle: 'Sales Billing Setup controls',
            accentColor: accentColor,
            statusLabel: null,
            metrics: [
              _MetricPill(
                icon: Icons.view_column_rounded,
                label: '$activeFieldCount/${fields.length} Fields',
                color: accentColor,
              ),
            ],
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _ProfileActionStrip(
            accentColor: accentColor,
            visibleLabel: '$activeFieldCount of ${fields.length} visible',
            onConfigure: () => _showBillingProfileEditor(context),
            onReload: () => controller.restoreMetalSavedSetup(metal),
          ),
        ],
      ),
    );
  }

  void _showBillingProfileEditor(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close sales billing profile editor',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: PosSalesBillingProfileDrawer(
              metal: metal,
              invoiceController: controller,
              accentColor: accentColor,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  bool _fieldEnabled(SalesBillingFieldKey key) {
    switch (key) {
      case SalesBillingFieldKey.pieces:
        return controller.getMetalCustomizationValue(metal, 'pcs');
      case SalesBillingFieldKey.grossWeight:
        return controller.getMetalCustomizationValue(metal, 'gw');
      case SalesBillingFieldKey.lessWeight:
        return controller.getMetalCustomizationValue(metal, 'lw');
      case SalesBillingFieldKey.netWeight:
        return controller.getMetalCustomizationValue(metal, 'net');
      case SalesBillingFieldKey.purity:
        return controller.getMetalCustomizationValue(metal, 'purity');
      case SalesBillingFieldKey.rate:
        return controller.getMetalCustomizationValue(metal, 'rate');
      case SalesBillingFieldKey.makingCharges:
        return controller.getMetalCustomizationValue(metal, 'making');
      case SalesBillingFieldKey.makingChargeType:
        return controller.getMetalCustomizationValue(metal, 'makingType');
      case SalesBillingFieldKey.stoneDetails:
        return controller.getMetalCustomizationValue(metal, 'stoneDetails');
      case SalesBillingFieldKey.stoneValue:
        return controller.getMetalCustomizationValue(metal, 'stoneValue');
      case SalesBillingFieldKey.totalValue:
        return controller.getMetalCustomizationValue(metal, 'amount');
      case SalesBillingFieldKey.huid:
        return controller.getMetalCustomizationValue(metal, 'huid');
      case SalesBillingFieldKey.wastage:
        return controller.getMetalCustomizationValue(metal, 'wastage');
      case SalesBillingFieldKey.oldGoldLine:
        return controller.getMetalCustomizationValue(metal, 'exchange');
      case SalesBillingFieldKey.diamondClarity:
        return controller.getMetalCustomizationValue(metal, 'diamondClarity');
      case SalesBillingFieldKey.certificationNo:
        return controller.getMetalCustomizationValue(metal, 'certificationNo');
      case SalesBillingFieldKey.diamondCarats:
        return controller.getMetalCustomizationValue(metal, 'diamondCarats');
      case SalesBillingFieldKey.diamondPieces:
        return controller.getMetalCustomizationValue(metal, 'diamondPieces');
      case SalesBillingFieldKey.metalWeight:
        return controller.getMetalCustomizationValue(metal, 'metalWeight');
      case SalesBillingFieldKey.fineWeight:
        return controller.getMetalCustomizationValue(metal, 'fineWeight');
      case SalesBillingFieldKey.gstBreakup:
        return controller.getMetalCustomizationValue(metal, 'gstBreakup');
      case SalesBillingFieldKey.hsnCode:
        return controller.getMetalCustomizationValue(metal, 'hsnCode');
    }
  }
}

class PosInvoiceShopPrintSetupCard extends StatelessWidget {
  final PosInvoiceController controller;

  const PosInvoiceShopPrintSetupCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.shopPrintInformationState;
    const accentColor = SalesPosColors.success;

    if (state == null) {
      return const _SetupCardShell(
        accentColor: accentColor,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Loading shop print information...',
                  style: TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SetupCardShell(
      accentColor: accentColor,
      child: Column(
        children: [
          _SetupHeader(
            icon: Icons.storefront_rounded,
            title: 'Business Print Profile',
            subtitle: 'Business details on this invoice',
            accentColor: accentColor,
            statusLabel: null,
            metrics: [
              _MetricPill(
                icon: Icons.toggle_on_rounded,
                label: '${state.enabledCount}/${state.configuredCount} Enabled',
                color: accentColor,
              ),
              _MetricPill(
                icon: Icons.inventory_2_rounded,
                label: '${state.missingCount} Missing',
                color: state.missingCount == 0
                    ? SalesPosColors.success
                    : SalesPosColors.warning,
              ),
            ],
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _ProfileActionStrip(
            accentColor: accentColor,
            visibleLabel: '${state.enabledCount} visible',
            configureLabel: 'Configure Business Info',
            reloadLabel: 'Reload Saved Business Setup',
            onConfigure: () => _showShopProfileEditor(context),
            onReload: controller.restoreShopPrintInformationSetup,
          ),
        ],
      ),
    );
  }

  void _showShopProfileEditor(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close business print profile editor',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: PosShopPrintProfileDrawer(
              controller: controller,
              accentColor: SalesPosColors.success,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

class _SetupCardShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _SetupCardShell({
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.05),
          SalesPosColors.shellPanelBg,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SetupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Widget> metrics;
  final String? statusLabel;

  const _SetupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.metrics,
    this.statusLabel = 'Saved Profile',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SalesPosColors.shellTextTitle,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SalesPosColors.shellTextMuted,
                        fontSize: SalesPosStyles.fontCaption,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null)
                _StatusPill(
                  label: statusLabel!,
                  color: accentColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionStrip extends StatelessWidget {
  final Color accentColor;
  final String visibleLabel;
  final String configureLabel;
  final String reloadLabel;
  final VoidCallback onConfigure;
  final VoidCallback onReload;

  const _ProfileActionStrip({
    required this.accentColor,
    required this.visibleLabel,
    this.configureLabel = 'Configure Display',
    this.reloadLabel = 'Reload Saved Master Setup',
    required this.onConfigure,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
              label: Text(
                '$configureLabel  •  $visibleLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.14),
                foregroundColor: accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: accentColor.withValues(alpha: 0.34),
                  ),
                ),
                textStyle: const TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.settings_backup_restore_rounded, size: 17),
              label: Text(reloadLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.shellTextMuted,
                side: const BorderSide(color: SalesPosColors.shellBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
