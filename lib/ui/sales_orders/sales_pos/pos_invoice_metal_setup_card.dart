import 'package:flutter/material.dart';

import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
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

  @override
  Widget build(BuildContext context) {
    final options = _InvoiceSetupCatalog.fieldOptionsFor(metal);
    final activeFieldCount = options
        .where((option) =>
            controller.getMetalCustomizationValue(metal, option.key))
        .length;
    final copyCount = _activeCopyCount(controller.getMetalConfig(metal));
    final copyEnabled = copyCount > 0;

    return _SetupCardShell(
      accentColor: accentColor,
      child: Column(
        children: [
          _SetupHeader(
            icon: Icons.tune_rounded,
            title: '${metal.displayName} Display Profile',
            subtitle: 'Column and copy controls',
            accentColor: accentColor,
            metrics: [
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
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Reload Saved Profile',
            subtitle: 'Apply defaults from Sales Billing Setup',
            accentColor: accentColor,
            actionLabel: 'Apply',
            onPressed: () => controller.restoreMetalSavedSetup(metal),
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.dashboard_customize_rounded,
            title: 'Invoice Columns',
            subtitle: '$activeFieldCount of ${options.length} fields visible',
            accentColor: accentColor,
            actionLabel: 'Configure',
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
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _InvoiceFieldSelectorPanel(
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
            metrics: [
              _MetricPill(
                icon: Icons.toggle_on_rounded,
                label: '${state.enabledCount} Enabled',
                color: accentColor,
              ),
              _MetricPill(
                icon: Icons.inventory_2_rounded,
                label: '${state.configuredCount}/${state.fields.length} Ready',
                color: state.missingCount == 0
                    ? SalesPosColors.success
                    : SalesPosColors.warning,
              ),
            ],
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Reload Business Profile',
            subtitle: 'Apply saved business print visibility',
            actionLabel: 'Apply',
            accentColor: accentColor,
            onPressed: controller.restoreShopPrintInformationSetup,
          ),
          const Divider(color: SalesPosColors.shellBorder, height: 1),
          _CompactActionRow(
            icon: Icons.store_mall_directory_rounded,
            title: 'Business Fields',
            subtitle:
                '${state.enabledCount} of ${state.configuredCount} configured fields visible',
            actionLabel: 'Configure',
            accentColor: accentColor,
            onPressed: () => _showShopFieldSelector(context, state),
          ),
        ],
      ),
    );
  }

  void _showShopFieldSelector(
    BuildContext context,
    ShopPrintInformationState state,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close shop print panel',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _ShopPrintFieldSelectorPanel(
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

class _InvoiceFieldSelectorPanel extends StatelessWidget {
  final MetalType metal;
  final PosInvoiceController controller;
  final Color accentColor;
  final VoidCallback onClose;

  const _InvoiceFieldSelectorPanel({
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
                _PanelHeader(
                  icon: Icons.dashboard_customize_rounded,
                  title: '${metal.displayName} Column Setup',
                  subtitle: 'Choose invoice columns for this metal',
                  accentColor: accentColor,
                  onClose: onClose,
                ),
                const Divider(color: SalesPosColors.shellBorder, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      for (final group in _InvoiceFieldGroup.values) ...[
                        _InvoiceFieldGroupCard(
                          title: group.title,
                          options: _InvoiceSetupCatalog.fieldOptionsFor(metal)
                              .where((option) => option.group == group)
                              .toList(),
                          metal: metal,
                          controller: controller,
                          accentColor: accentColor,
                          onChanged: setPanelState,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                _PanelApplyButton(
                  accentColor: accentColor,
                  onPressed: onClose,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopPrintFieldSelectorPanel extends StatelessWidget {
  final PosInvoiceController controller;
  final Color accentColor;
  final VoidCallback onClose;

  const _ShopPrintFieldSelectorPanel({
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
            final state = controller.shopPrintInformationState;
            if (state == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelHeader(
                  icon: Icons.storefront_rounded,
                  title: 'Business Print Fields',
                  subtitle: 'Choose shop details for this invoice',
                  accentColor: accentColor,
                  onClose: onClose,
                ),
                const Divider(color: SalesPosColors.shellBorder, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      for (final group in ShopPrintFieldGroup.values) ...[
                        _ShopFieldGroupCard(
                          title: _shopGroupTitle(group),
                          fields: state.fields
                              .where((field) => field.group == group)
                              .toList(),
                          state: state,
                          controller: controller,
                          accentColor: accentColor,
                          onChanged: setPanelState,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                _PanelApplyButton(
                  accentColor: accentColor,
                  onPressed: onClose,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _shopGroupTitle(ShopPrintFieldGroup group) {
    switch (group) {
      case ShopPrintFieldGroup.identity:
        return 'Identity';
      case ShopPrintFieldGroup.contact:
        return 'Contact';
      case ShopPrintFieldGroup.statutory:
        return 'Legal & Tax';
      case ShopPrintFieldGroup.address:
        return 'Address';
      case ShopPrintFieldGroup.social:
        return 'Social';
      case ShopPrintFieldGroup.banking:
        return 'Banking';
    }
  }
}

class _InvoiceFieldGroupCard extends StatelessWidget {
  final String title;
  final List<_InvoiceFieldOption> options;
  final MetalType metal;
  final PosInvoiceController controller;
  final Color accentColor;
  final StateSetter onChanged;

  const _InvoiceFieldGroupCard({
    required this.title,
    required this.options,
    required this.metal,
    required this.controller,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return _OptionGroupShell(
      title: title,
      accentColor: accentColor,
      children: [
        for (final option in options)
          _InvoiceFieldOptionTile(
            option: option,
            enabled: controller.getMetalCustomizationValue(metal, option.key),
            accentColor: accentColor,
            onChanged: (value) async {
              await controller.setMetalCustomization(
                metal,
                option.key,
                value,
              );
              onChanged(() {});
            },
          ),
      ],
    );
  }
}

class _ShopFieldGroupCard extends StatelessWidget {
  final String title;
  final List<ShopPrintField> fields;
  final ShopPrintInformationState state;
  final PosInvoiceController controller;
  final Color accentColor;
  final StateSetter onChanged;

  const _ShopFieldGroupCard({
    required this.title,
    required this.fields,
    required this.state,
    required this.controller,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return _OptionGroupShell(
      title: title,
      accentColor: accentColor,
      children: [
        for (final field in fields)
          _ShopFieldOptionTile(
            field: field,
            enabled: state.isEnabled(field),
            accentColor: accentColor,
            onChanged: field.isConfigured
                ? (value) async {
                    await controller.setShopPrintFieldEnabled(field, value);
                    onChanged(() {});
                  }
                : null,
          ),
      ],
    );
  }
}

class _OptionGroupShell extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;

  const _OptionGroupShell({
    required this.title,
    required this.accentColor,
    required this.children,
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
          ...children,
        ],
      ),
    );
  }
}

class _InvoiceFieldOptionTile extends StatelessWidget {
  final _InvoiceFieldOption option;
  final bool enabled;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _InvoiceFieldOptionTile({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
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
          height: 1.2,
        ),
      ),
    );
  }
}

class _ShopFieldOptionTile extends StatelessWidget {
  final ShopPrintField field;
  final bool enabled;
  final Color accentColor;
  final ValueChanged<bool>? onChanged;

  const _ShopFieldOptionTile({
    required this.field,
    required this.enabled,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final configured = field.isConfigured;

    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      activeThumbColor: accentColor,
      inactiveTrackColor: SalesPosColors.shellBg,
      secondary: Icon(
        _fieldIcon(field),
        color: configured
            ? (enabled ? accentColor : SalesPosColors.shellTextMuted)
            : SalesPosColors.warning,
        size: 18,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              field.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: configured
                    ? SalesPosColors.shellTextTitle
                    : SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!configured)
            const _StatusPill(
              label: 'Missing',
              color: SalesPosColors.warning,
            ),
        ],
      ),
      subtitle: Text(
        configured
            ? _compact(field.value)
            : 'Add this detail in ${field.sourceSection}.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SalesPosColors.shellTextMuted,
          fontSize: SalesPosStyles.fontCaption,
          height: 1.2,
        ),
      ),
    );
  }

  IconData _fieldIcon(ShopPrintField field) {
    switch (field.group) {
      case ShopPrintFieldGroup.identity:
        if (field.id == 'logo') return Icons.image_rounded;
        if (field.id == 'signature') return Icons.draw_rounded;
        return Icons.badge_rounded;
      case ShopPrintFieldGroup.contact:
        return Icons.call_rounded;
      case ShopPrintFieldGroup.statutory:
        return Icons.verified_user_rounded;
      case ShopPrintFieldGroup.address:
        return Icons.location_on_rounded;
      case ShopPrintFieldGroup.social:
        return Icons.share_rounded;
      case ShopPrintFieldGroup.banking:
        return Icons.account_balance_rounded;
    }
  }

  String _compact(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 72) return compact;
    return '${compact.substring(0, 69)}...';
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

  const _SetupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.metrics,
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
              _StatusPill(
                label: 'Saved Profile',
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
                  maxLines: 2,
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
                  'Print Policy Copy',
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

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Icon(icon, color: accentColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontInput,
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
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: SalesPosColors.shellTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelApplyButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onPressed;

  const _PanelApplyButton({
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
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

enum _InvoiceFieldGroup {
  identity,
  weight,
  rate,
  settlement,
}

extension _InvoiceFieldGroupLabel on _InvoiceFieldGroup {
  String get title {
    switch (this) {
      case _InvoiceFieldGroup.identity:
        return 'Identity';
      case _InvoiceFieldGroup.weight:
        return 'Weight & Purity';
      case _InvoiceFieldGroup.rate:
        return 'Rate & Charges';
      case _InvoiceFieldGroup.settlement:
        return 'Settlement & Tax';
    }
  }
}

class _InvoiceFieldOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final _InvoiceFieldGroup group;

  const _InvoiceFieldOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.group,
  });
}

class _InvoiceSetupCatalog {
  _InvoiceSetupCatalog._();

  static List<_InvoiceFieldOption> fieldOptionsFor(MetalType metal) {
    return _fieldOptions;
  }

  static const List<_InvoiceFieldOption> _fieldOptions = [
    _InvoiceFieldOption(
      key: 'huid',
      title: 'HUID',
      subtitle: 'Item identification details',
      icon: Icons.fingerprint_rounded,
      group: _InvoiceFieldGroup.identity,
    ),
    _InvoiceFieldOption(
      key: 'pcs',
      title: 'Pieces',
      subtitle: 'Quantity column',
      icon: Icons.numbers_rounded,
      group: _InvoiceFieldGroup.identity,
    ),
    _InvoiceFieldOption(
      key: 'purity',
      title: 'Purity',
      subtitle: 'Metal purity column',
      icon: Icons.diamond_outlined,
      group: _InvoiceFieldGroup.weight,
    ),
    _InvoiceFieldOption(
      key: 'gw',
      title: 'Gross Weight',
      subtitle: 'Gross weight column',
      icon: Icons.scale_rounded,
      group: _InvoiceFieldGroup.weight,
    ),
    _InvoiceFieldOption(
      key: 'lw',
      title: 'Less Weight',
      subtitle: 'Less or stone weight column',
      icon: Icons.remove_circle_outline_rounded,
      group: _InvoiceFieldGroup.weight,
    ),
    _InvoiceFieldOption(
      key: 'net',
      title: 'Net Weight',
      subtitle: 'Net weight column',
      icon: Icons.balance_rounded,
      group: _InvoiceFieldGroup.weight,
    ),
    _InvoiceFieldOption(
      key: 'fineWeight',
      title: 'Fine Weight',
      subtitle: 'Calculated fine weight column',
      icon: Icons.analytics_rounded,
      group: _InvoiceFieldGroup.weight,
    ),
    _InvoiceFieldOption(
      key: 'rate',
      title: 'Rate',
      subtitle: 'Item rate column',
      icon: Icons.trending_up_rounded,
      group: _InvoiceFieldGroup.rate,
    ),
    _InvoiceFieldOption(
      key: 'making',
      title: 'Making Amount',
      subtitle: 'Calculated making charge',
      icon: Icons.payments_rounded,
      group: _InvoiceFieldGroup.rate,
    ),
    _InvoiceFieldOption(
      key: 'makingType',
      title: 'Making Rate / Type',
      subtitle: 'Entry such as 12% or 400/g',
      icon: Icons.percent_rounded,
      group: _InvoiceFieldGroup.rate,
    ),
    _InvoiceFieldOption(
      key: 'amount',
      title: 'Line Amount',
      subtitle: 'Final line amount column',
      icon: Icons.receipt_long_rounded,
      group: _InvoiceFieldGroup.rate,
    ),
    _InvoiceFieldOption(
      key: 'exchange',
      title: 'Exchange Breakdown',
      subtitle: 'Metal-wise exchange deduction',
      icon: Icons.compare_arrows_rounded,
      group: _InvoiceFieldGroup.settlement,
    ),
    _InvoiceFieldOption(
      key: 'gstBreakup',
      title: 'GST Breakup',
      subtitle: 'CGST and SGST lines on GST invoices',
      icon: Icons.request_quote_rounded,
      group: _InvoiceFieldGroup.settlement,
    ),
    _InvoiceFieldOption(
      key: 'hsnCode',
      title: 'HSN Code',
      subtitle: 'Tax classification code on invoice lines',
      icon: Icons.qr_code_2_rounded,
      group: _InvoiceFieldGroup.settlement,
    ),
  ];
}
