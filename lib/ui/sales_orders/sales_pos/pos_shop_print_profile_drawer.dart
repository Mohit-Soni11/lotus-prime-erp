import 'package:flutter/material.dart';

import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../features/settings/billing_setup/shop_info/presentation/widgets/shop_print_information_widgets.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../theme/settings/billing_setup/billing_setup_colors.dart';

class PosShopPrintProfileDrawer extends StatefulWidget {
  final PosInvoiceController controller;
  final Color accentColor;
  final VoidCallback onClose;

  const PosShopPrintProfileDrawer({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onClose,
  });

  @override
  State<PosShopPrintProfileDrawer> createState() =>
      _PosShopPrintProfileDrawerState();
}

class _PosShopPrintProfileDrawerState extends State<PosShopPrintProfileDrawer> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.controller.saveShopPrintInformationSetup();
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Business print profile saved.'),
      ),
    );
    widget.onClose();
  }

  void _showMissingFieldGuidance(ShopPrintField field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Add ${field.label} in ${field.sourceSection} before enabling it.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 760 ? width - 24 : 720.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: BillingSetupColors.bodyBg,
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
        child: Column(
          children: [
            _DrawerHeader(
              accentColor: widget.accentColor,
              onClose: widget.onClose,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final state = widget.controller.shopPrintInformationState;
                  if (state == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryStrip(state: state),
                      const SizedBox(height: 14),
                      for (final group in ShopPrintFieldGroup.values) ...[
                        ShopPrintInformationSection(
                          group: group,
                          fields: state.fields
                              .where((field) => field.group == group)
                              .toList(growable: false),
                          isEnabled: state.isEnabled,
                          onChanged: widget.controller.setShopPrintFieldEnabled,
                          onMissingFieldTap: _showMissingFieldGuidance,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ),
            _DrawerFooter(
              accentColor: widget.accentColor,
              isSaving: _isSaving,
              onReload: widget.controller.restoreShopPrintInformationSetup,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: SalesPosColors.shellBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storefront_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUSINESS PRINT PROFILE',
                  style: TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontInput,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Shop Print Information controls with live invoice preview',
                  style: TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
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

class _SummaryStrip extends StatelessWidget {
  final ShopPrintInformationState state;

  const _SummaryStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _SummaryMetric(
            icon: Icons.toggle_on_rounded,
            label: '${state.enabledCount} Enabled',
            color: BillingSetupColors.success,
          ),
          const SizedBox(width: 10),
          _SummaryMetric(
            icon: Icons.verified_rounded,
            label: '${state.configuredCount}/${state.fields.length} Ready',
            color: BillingSetupColors.info,
          ),
          const SizedBox(width: 10),
          _SummaryMetric(
            icon: state.missingCount == 0
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            label: '${state.missingCount} Missing',
            color: state.missingCount == 0
                ? BillingSetupColors.success
                : BillingSetupColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final Color accentColor;
  final bool isSaving;
  final VoidCallback onReload;
  final VoidCallback onSave;

  const _DrawerFooter({
    required this.accentColor,
    required this.isSaving,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onReload,
              icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
              label: const Text('Reload Saved'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.shellTextTitle,
                side: const BorderSide(color: Color(0xFFD6DEE8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Business Profile'),
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
        ],
      ),
    );
  }
}
