import 'package:flutter/material.dart';

import '../../../../features/sales_pos/domain/services/pos_number_formatter.dart';
import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'pos_advance_quick_stock_fields.dart';

enum PosAdvanceStockResolutionAction {
  selectExistingStock,
  quickAddStock,
}

class PosAdvanceStockResolutionDialog extends StatelessWidget {
  final PosBillingController controller;
  final PosStockLinkIssue issue;

  const PosAdvanceStockResolutionDialog({
    super.key,
    required this.controller,
    required this.issue,
  });

  static Future<PosAdvanceStockResolutionAction?> show({
    required BuildContext context,
    required PosBillingController controller,
    required PosStockLinkIssue issue,
  }) {
    return showDialog<PosAdvanceStockResolutionAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PosAdvanceStockResolutionDialog(
        controller: controller,
        issue: issue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = controller.saleItems[issue.rowIndex];
    final itemName = item.descCtrl.text.trim().isEmpty
        ? 'Jewellery Item'
        : item.descCtrl.text.trim();
    final weight = PosNumberFormatter.weight(item.netWt, blankWhenZero: false);
    final isMissing = issue.type == PosStockLinkIssueType.missingStock;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuickStockDialogHeader(
                title: isMissing
                    ? 'Stock Required Before Sale'
                    : 'Stock Link Required',
                subtitle: isMissing
                    ? 'No sale-ready stock is linked with this advance item.'
                    : 'Matching inventory exists, but this row is not linked.',
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: QuickStockItemSnapshot(
                  title: itemName,
                  details:
                      '${item.metal.displayName}  |  ${item.purityCtrl.text.trim()}  |  Net $weight g',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 8),
                child: Text(
                  isMissing
                      ? 'Add this item to stock now, or use the full Add Stock module and return to generate invoice.'
                      : 'Select the visible matching stock result to avoid duplicate inventory. Quick add is available only when you want to create a fresh stock unit.',
                  style: const TextStyle(
                    color: SalesPosColors.textDark,
                    fontSize: 14,
                    height: 1.42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: SalesPosColors.textDark,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    if (!isMissing) ...[
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(
                          PosAdvanceStockResolutionAction.selectExistingStock,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SalesPosColors.goldHoverDark,
                          side: BorderSide(
                            color: SalesPosColors.brandGold
                                .withValues(alpha: 0.55),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.touch_app_rounded, size: 18),
                        label: const Text(
                          'Use Existing Stock',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(
                        PosAdvanceStockResolutionAction.quickAddStock,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: SalesPosColors.brandGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_box_rounded, size: 18),
                      label: const Text(
                        'Quick Add Stock',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
