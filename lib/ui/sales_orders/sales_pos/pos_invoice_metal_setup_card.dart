import 'package:flutter/material.dart';

import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

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

  static const List<_InvoiceFieldOption> _fieldOptions = [
    _InvoiceFieldOption(
      key: 'huid',
      title: 'HUID',
      subtitle: 'Item identification details',
      icon: Icons.fingerprint_rounded,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'pcs',
      title: 'Pieces',
      subtitle: 'Quantity column',
      icon: Icons.numbers_rounded,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'gw',
      title: 'Gross Weight',
      subtitle: 'Gross weight column',
      icon: Icons.scale_rounded,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'lw',
      title: 'Less Weight',
      subtitle: 'Less weight column',
      icon: Icons.remove_circle_outline_rounded,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'net',
      title: 'Net / Fine Weight',
      subtitle: 'Net or fine weight column',
      icon: Icons.balance_rounded,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'purity',
      title: 'Purity',
      subtitle: 'Metal purity column',
      icon: Icons.diamond_outlined,
      group: _FieldGroupType.identity,
    ),
    _InvoiceFieldOption(
      key: 'rate',
      title: 'Rate',
      subtitle: 'Item rate column',
      icon: Icons.trending_up_rounded,
      group: _FieldGroupType.rate,
    ),
    _InvoiceFieldOption(
      key: 'making',
      title: 'Making Amount',
      subtitle: 'Calculated making charge',
      icon: Icons.payments_rounded,
      group: _FieldGroupType.rate,
    ),
    _InvoiceFieldOption(
      key: 'makingType',
      title: 'Making Rate / Type',
      subtitle: 'Entry such as 12% or 400/g',
      icon: Icons.percent_rounded,
      group: _FieldGroupType.rate,
    ),
    _InvoiceFieldOption(
      key: 'amount',
      title: 'Line Amount',
      subtitle: 'Final line amount column',
      icon: Icons.receipt_long_rounded,
      group: _FieldGroupType.rate,
    ),
    _InvoiceFieldOption(
      key: 'exchange',
      title: 'Exchange Breakdown',
      subtitle: 'Metal-wise exchange deduction',
      icon: Icons.compare_arrows_rounded,
      group: _FieldGroupType.settlement,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeFieldCount = _fieldOptions
        .where((option) => controller.getMetalCustomizationValue(
              metal,
              option.key,
            ))
        .length;
    final copyCount = _activeCopyCount(controller.getMetalConfig(metal));
    final copyEnabled = copyCount > 0;

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
      child: Column(
        children: [
          Padding(
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
                            color: accentColor.withValues(alpha: 0.22)),
                      ),
                      child: Icon(Icons.tune_rounded,
                          size: 18, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${metal.displayName} Invoice Setup",
                            style: const TextStyle(
                              color: SalesPosColors.shellTextTitle,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Metal-specific print controls",
                            style: TextStyle(
                              color: SalesPosColors.shellTextMuted,
                              fontSize: SalesPosStyles.fontCaption,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: 'Saved Setup',
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      icon: Icons.view_column_rounded,
                      label: '$activeFieldCount Fields',
                      color: accentColor,
                    ),
                    _MetricPill(
                      icon: Icons.article_outlined,
                      label: copyEnabled ? 'Copy On' : 'Copy Off',
                      color: copyEnabled
                          ? SalesPosColors.success
                          : SalesPosColors.shellTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Use Saved Setup',
            subtitle: 'Reload field visibility from Billing Setup',
            accentColor: accentColor,
            actionLabel: 'Apply',
            onPressed: () => controller.restoreMetalSavedSetup(metal),
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.dashboard_customize_rounded,
            title: 'Invoice Fields',
            subtitle:
                '$activeFieldCount of ${_fieldOptions.length} fields visible',
            accentColor: accentColor,
            actionLabel: 'Add More',
            onPressed: () => _showFieldSelector(context),
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CopySuiteRow(
            activeCount: copyCount,
            accentColor: accentColor,
            onChanged: (enabled) =>
                controller.setMetalCopySuiteEnabled(metal, enabled),
          ),
        ],
      ),
    );
  }

  void _showFieldSelector(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close invoice field panel',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _FieldSelectorPanel(
              metal: metal,
              controller: controller,
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

  int _activeCopyCount(BillSettings settings) {
    return [
      settings.printTermsAndConditions,
      settings.printReturnPolicy,
      settings.printBuybackPolicy,
      settings.printFooterMessage,
    ].where((enabled) => enabled).length;
  }
}

class _FieldSelectorPanel extends StatelessWidget {
  final MetalType metal;
  final PosInvoiceController controller;
  final Color accentColor;
  final VoidCallback onClose;

  const _FieldSelectorPanel({
    required this.metal,
    required this.controller,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 460.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesPosColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setPanelState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.dashboard_customize_rounded,
                            color: accentColor, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${metal.displayName} Field Setup",
                              style: const TextStyle(
                                color: SalesPosColors.shellTextTitle,
                                fontSize: SalesPosStyles.fontInput,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Choose invoice columns for this metal",
                              style: TextStyle(
                                color: SalesPosColors.shellTextMuted,
                                fontSize: SalesPosStyles.fontCaption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: SalesPosColors.shellTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: SalesPosColors.shellBorder, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _FieldGroup(
                        title: 'Identity & Weight',
                        options: PosInvoiceMetalSetupCard._fieldOptions
                            .where((option) =>
                                option.group == _FieldGroupType.identity)
                            .toList(),
                        metal: metal,
                        controller: controller,
                        accentColor: accentColor,
                        onChanged: setPanelState,
                      ),
                      const SizedBox(height: 12),
                      _FieldGroup(
                        title: 'Rate & Charges',
                        options: PosInvoiceMetalSetupCard._fieldOptions
                            .where((option) =>
                                option.group == _FieldGroupType.rate)
                            .toList(),
                        metal: metal,
                        controller: controller,
                        accentColor: accentColor,
                        onChanged: setPanelState,
                      ),
                      const SizedBox(height: 12),
                      _FieldGroup(
                        title: 'Settlement',
                        options: PosInvoiceMetalSetupCard._fieldOptions
                            .where((option) =>
                                option.group == _FieldGroupType.settlement)
                            .toList(),
                        metal: metal,
                        controller: controller,
                        accentColor: accentColor,
                        onChanged: setPanelState,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'APPLY CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String title;
  final List<_InvoiceFieldOption> options;
  final MetalType metal;
  final PosInvoiceController controller;
  final Color accentColor;
  final StateSetter onChanged;

  const _FieldGroup({
    required this.title,
    required this.options,
    required this.metal,
    required this.controller,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: SalesPosColors.shellTextTitle,
                      fontSize: SalesPosStyles.fontCaption,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...options.map((option) {
            final enabled = controller.getMetalCustomizationValue(
              metal,
              option.key,
            );
            return _FieldOptionTile(
              option: option,
              enabled: enabled,
              accentColor: accentColor,
              onChanged: (value) async {
                await controller.setMetalCustomization(
                  metal,
                  option.key,
                  value,
                );
                onChanged(() {});
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CompactActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color accentColor;
  final VoidCallback onPressed;

  const _CompactActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor.withValues(alpha: 0.55)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopySuiteRow extends StatelessWidget {
  final int activeCount;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _CopySuiteRow({
    required this.activeCount,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = activeCount > 0;
    final subtitle = enabled
        ? 'Terms, policies, and footer included'
        : 'Saved copy is hidden on this invoice';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.article_outlined, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Print Saved Copy',
                  style: TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: accentColor,
            inactiveTrackColor: SalesPosColors.shellBg,
          ),
        ],
      ),
    );
  }
}

class _FieldOptionTile extends StatelessWidget {
  final _InvoiceFieldOption option;
  final bool enabled;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _FieldOptionTile({
    required this.option,
    required this.enabled,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: accentColor,
      inactiveTrackColor: SalesPosColors.shellBg,
      secondary: Icon(
        option.icon,
        color: enabled ? accentColor : SalesPosColors.shellTextMuted,
        size: 18,
      ),
      title: Text(
        option.title,
        style: const TextStyle(
          color: SalesPosColors.shellTextTitle,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        option.subtitle,
        style: const TextStyle(
          color: SalesPosColors.shellTextMuted,
          fontSize: SalesPosStyles.fontCaption,
        ),
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

enum _FieldGroupType {
  identity,
  rate,
  settlement,
}

class _InvoiceFieldOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final _FieldGroupType group;

  const _InvoiceFieldOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.group,
  });
}
