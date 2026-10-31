part of 'return_reversal_workflow_tabs.dart';

class _StockRouteSelector extends StatelessWidget {
  final ReturnReversalStockRoute selectedRoute;
  final bool readOnly;
  final ValueChanged<ReturnReversalStockRoute> onRouteSelected;

  const _StockRouteSelector({
    required this.selectedRoute,
    required this.readOnly,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final route in ReturnReversalStockRoute.values)
              SizedBox(
                width: compact ? constraints.maxWidth : 190,
                child: _RouteTile(
                  route: route,
                  selected: route == selectedRoute,
                  onTap: readOnly ? null : () => onRouteSelected(route),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RouteTile extends StatelessWidget {
  final ReturnReversalStockRoute route;
  final bool selected;
  final VoidCallback? onTap;

  const _RouteTile({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? SalesPosColors.success : SalesPosColors.textDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? SalesPosColors.success.withValues(alpha: 0.08)
              : SalesPosColors.bodyBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? SalesPosColors.success.withValues(alpha: 0.38)
                : SalesPosColors.bodyBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(route.icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      color: color,
                      fontSize: SalesPosStyles.fontLabel,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    route.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.caption.copyWith(
                      color: SalesPosColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnCartActionBar extends StatelessWidget {
  final bool inCart;
  final bool processed;
  final String voucherNo;
  final double returnAmount;
  final ReturnReversalStockRoute route;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ReturnCartActionBar({
    required this.inCart,
    required this.processed,
    required this.voucherNo,
    required this.returnAmount,
    required this.route,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: processed
            ? SalesPosColors.bodyBg
            : inCart
                ? SalesPosColors.success.withValues(alpha: 0.08)
                : SalesPosColors.brandGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: processed
              ? SalesPosColors.success.withValues(alpha: 0.30)
              : inCart
                  ? SalesPosColors.success.withValues(alpha: 0.36)
                  : SalesPosColors.brandGold.withValues(alpha: 0.34),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final status = _CartAmountSummary(
            inCart: inCart,
            processed: processed,
            voucherNo: voucherNo,
            returnAmount: returnAmount,
            route: route,
          );
          final actions = _CartActions(
            inCart: inCart,
            processed: processed,
            onAdd: onAdd,
            onRemove: onRemove,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CartAmountSummary extends StatelessWidget {
  final bool inCart;
  final bool processed;
  final String voucherNo;
  final double returnAmount;
  final ReturnReversalStockRoute route;

  const _CartAmountSummary({
    required this.inCart,
    required this.processed,
    required this.voucherNo,
    required this.returnAmount,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          processed
              ? Icons.verified_rounded
              : inCart
                  ? Icons.check_circle_rounded
                  : Icons.shopping_cart_checkout,
          color: processed || inCart
              ? SalesPosColors.success
              : SalesPosColors.brandGold,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                processed
                    ? 'Already Returned'
                    : inCart
                        ? 'Added to Return Cart'
                        : 'Ready for Return Cart',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: processed || inCart
                      ? SalesPosColors.success
                      : SalesPosColors.brandGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                processed
                    ? '${_formatCurrency(returnAmount)} | Voucher: ${voucherNo.trim().isEmpty ? 'Returned' : voucherNo}'
                    : '${_formatCurrency(returnAmount)} | Route: ${route.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartActions extends StatelessWidget {
  final bool inCart;
  final bool processed;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartActions({
    required this.inCart,
    required this.processed,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (processed)
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('Returned'),
            style: FilledButton.styleFrom(
              disabledBackgroundColor:
                  SalesPosColors.success.withValues(alpha: 0.18),
              disabledForegroundColor: SalesPosColors.success,
              textStyle: SalesPosStyles.buttonText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          )
        else ...[
          if (inCart) ...[
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_shopping_cart_rounded, size: 18),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.danger,
                textStyle: SalesPosStyles.buttonText,
                side: BorderSide(
                  color: SalesPosColors.danger.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton.icon(
            onPressed: onAdd,
            icon: Icon(
              inCart ? Icons.sync_rounded : Icons.add_shopping_cart_rounded,
              size: 18,
            ),
            label: Text(inCart ? 'Update Cart' : 'Add To Return Cart'),
            style: FilledButton.styleFrom(
              backgroundColor: SalesPosColors.success,
              foregroundColor: Colors.white,
              textStyle: SalesPosStyles.buttonText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyWorkflowState extends StatelessWidget {
  final bool isBookingCancellation;

  const _EmptyWorkflowState({required this.isBookingCancellation});

  @override
  Widget build(BuildContext context) {
    final message = isBookingCancellation
        ? 'Select an advance booking above to prepare cancellation settlement.'
        : 'Select invoice items above to start HUID, unit, weight, and stock-route verification.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: SalesPosColors.brandGold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyText.copyWith(
                color: SalesPosColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedWorkflowState extends StatelessWidget {
  const _CompletedWorkflowState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: SalesPosColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_rounded,
            color: SalesPosColors.danger,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All invoice lines are already returned. No editable return item is available.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyText.copyWith(
                color: SalesPosColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _receivedWeightRatio(
  ReturnReversalSourceLineItem lineItem,
  ReturnReversalLineInspectionDraft draft,
) {
  if (lineItem.netWeight <= 0) {
    return 1;
  }
  return (draft.receivedNetWeight / lineItem.netWeight).clamp(0.0, 1.0);
}

Color _metalColor(String metalType) {
  final normalized = metalType.trim().toUpperCase();
  if (normalized.contains('SILVER')) {
    return SalesPosColors.brandSilver;
  }
  if (normalized.contains('PLATINUM')) {
    return SalesPosColors.brandPlatinum;
  }
  if (normalized.contains('DIAMOND')) {
    return SalesPosColors.brandDiamond;
  }
  return SalesPosColors.brandGold;
}

String _metalLabel(String metalType) {
  final normalized = metalType.trim().toUpperCase();
  return normalized.isEmpty ? 'GOLD' : normalized;
}

String _emptyAsDash(String value) {
  final cleanValue = value.trim();
  return cleanValue.isEmpty ? '-' : cleanValue;
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final day = value.day.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]} ${value.year}';
}

String _processedLineLabel(ReturnReversalSourceLineItem lineItem) {
  final status = lineItem.reversalStatus.trim().toUpperCase();
  if (status.contains('CANCEL')) {
    return 'CANCELLED';
  }
  return 'RETURNED';
}

String _formatWeight(double value) => value.toStringAsFixed(3);

String _unitShortName(ReturnReversalSourceLineItem lineItem) {
  return _unitProfileFor(lineItem).shortName;
}

PosItemUnitProfile _unitProfileFor(ReturnReversalSourceLineItem lineItem) {
  final storedUnit = PosItemUnitProfile.fromStorageValue(
    lineItem.quantityUnitCode,
  );
  final inferredUnit = PosItemUnitProfile.infer(
    metal: _metalTypeFromLabel(lineItem.metalType),
    itemName: lineItem.description,
  );
  if (storedUnit != null &&
      (storedUnit.code != PosItemUnitCode.pieces ||
          inferredUnit.code == PosItemUnitCode.pieces)) {
    return storedUnit;
  }
  return inferredUnit;
}

MetalType _metalTypeFromLabel(String metalType) {
  final normalized = metalType.trim().toUpperCase();
  if (normalized.contains('SILVER')) {
    return MetalType.silver;
  }
  if (normalized.contains('PLATINUM')) {
    return MetalType.platinum;
  }
  if (normalized.contains('DIAMOND')) {
    return MetalType.diamond;
  }
  return MetalType.gold;
}

String _formatCompactNumber(double value) {
  if (value.abs() < 0.01) {
    return '0';
  }
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}

String _formatMakingInput(ReturnReversalSourceLineItem lineItem) {
  if (lineItem.makingChargeInput.abs() < 0.01) {
    return '-';
  }
  final value = _formatCompactNumber(lineItem.makingChargeInput);
  return switch (lineItem.makingChargeType.trim().toUpperCase()) {
    'PERCENTAGE' => '$value%',
    'PER_KG' => '$value/kg',
    'PER_PIECE' => '$value/pc',
    _ => '$value${lineItem.makingChargeSymbol}',
  };
}

String _formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  if (digits.length <= 3) {
    return 'Rs $sign$digits';
  }
  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);
  final groupedLeading = leading.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs $sign$groupedLeading,$lastThree';
}
