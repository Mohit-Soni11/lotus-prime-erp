import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosMetalPaymentAllocationCard extends StatelessWidget {
  const PosMetalPaymentAllocationCard({
    super.key,
    required this.allocations,
    required this.settleFirstMetals,
    required this.onToggle,
    required this.metalDiscounts,
    required this.onDiscountChanged,
    this.billId,
    required this.manualMode,
    required this.onManualModeChanged,
    required this.manualPaidByMetal,
    required this.onManualPaidChanged,
    this.allocationError,
  });

  final List<PosInvoiceMetalPaymentAllocation> allocations;
  final Set<MetalType> settleFirstMetals;
  final ValueChanged<MetalType> onToggle;
  final Map<MetalType, double> metalDiscounts;
  final void Function(MetalType, double) onDiscountChanged;
  final int? billId;
  final bool manualMode;
  final ValueChanged<bool> onManualModeChanged;
  final Map<MetalType, double> manualPaidByMetal;
  final void Function(MetalType, double) onManualPaidChanged;
  final String? allocationError;

  @override
  Widget build(BuildContext context) {
    if (allocations.length <= 1) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_tree_rounded,
                size: 20, color: SalesPosColors.textDark),
            SizedBox(width: 8),
            Expanded(
              child: Text('METAL PAYMENT SETTLEMENT',
                  style: TextStyle(
                      color: SalesPosColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Choose the metal to clear first, or enter exact paid amounts. Set each discount separately.',
            style: TextStyle(
                color: SalesPosColors.textDark,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => onManualModeChanged(!manualMode),
            style: TextButton.styleFrom(
              foregroundColor: SalesPosColors.textDark,
              backgroundColor: SalesPosColors.brandGold.withValues(alpha: 0.13),
              side: BorderSide(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.75),
                  width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            icon: Icon(manualMode ? Icons.tune_rounded : Icons.edit_rounded,
                size: 18),
            label: Text(manualMode
                ? 'Use settle-first order'
                : 'Enter paid amounts manually'),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < allocations.length; index++) ...[
            _MetalSettlementRow(
              allocation: allocations[index],
              isSelected: settleFirstMetals.contains(allocations[index].metal),
              onSelect: () => onToggle(allocations[index].metal),
              discount: metalDiscounts[allocations[index].metal] ?? 0,
              onDiscountChanged: (value) =>
                  onDiscountChanged(allocations[index].metal, value),
              billId: billId,
              manualMode: manualMode,
              manualPaid: manualPaidByMetal[allocations[index].metal] ?? 0,
              onManualPaidChanged: (value) =>
                  onManualPaidChanged(allocations[index].metal, value),
            ),
            if (index < allocations.length - 1) const SizedBox(height: 10),
          ],
          if (allocationError != null) ...[
            const SizedBox(height: 10),
            Text(allocationError!,
                style: const TextStyle(
                    color: SalesPosColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ],
        ],
      ),
    );
  }
}

class _MetalSettlementRow extends StatelessWidget {
  const _MetalSettlementRow({
    required this.allocation,
    required this.isSelected,
    required this.onSelect,
    required this.discount,
    required this.onDiscountChanged,
    required this.billId,
    required this.manualMode,
    required this.manualPaid,
    required this.onManualPaidChanged,
  });

  final PosInvoiceMetalPaymentAllocation allocation;
  final bool isSelected;
  final VoidCallback onSelect;
  final double discount;
  final ValueChanged<double> onDiscountChanged;
  final int? billId;
  final bool manualMode;
  final double manualPaid;
  final ValueChanged<double> onManualPaidChanged;

  @override
  Widget build(BuildContext context) {
    final due = allocation.balanceDue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? SalesPosColors.brandGold.withValues(alpha: 0.09)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isSelected
                ? SalesPosColors.brandGold
                : SalesPosColors.bodyBorder,
            width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: manualMode ? null : onSelect,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  if (!manualMode) ...[
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: SalesPosColors.textDark,
                      size: 22,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      manualMode
                          ? allocation.metal.displayName
                          : '${allocation.metal.displayName} first',
                      style: const TextStyle(
                          color: SalesPosColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 126,
            child: _SettlementInput(
              key: ValueKey(
                  'metal-discount-${billId ?? 'new'}-${allocation.metal.name}'),
              label: 'Discount (Rs)',
              initialValue: discount <= 0 ? '' : discount.toStringAsFixed(2),
              onChanged: onDiscountChanged,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                _SettlementAmount(label: 'Net Bill', amount: allocation.netPayable),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: manualMode
                ? _SettlementInput(
                    key: ValueKey(
                        'metal-paid-${billId ?? 'new'}-${allocation.metal.name}'),
                    label: 'Paid (Rs)',
                    initialValue: manualPaid.toStringAsFixed(2),
                    onChanged: onManualPaidChanged,
                  )
                : _SettlementAmount(
                    label: 'Paid', amount: allocation.totalPaid),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SettlementAmount(
                label: due > 0.005 ? 'Due' : 'Clear',
                amount: due.abs(),
                isDue: due > 0.005),
          ),
        ]),
      ]),
    );
  }
}

class _SettlementAmount extends StatelessWidget {
  const _SettlementAmount({
    required this.label,
    required this.amount,
    this.isDue = false,
  });

  final String label;
  final double amount;
  final bool isDue;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDue
              ? SalesPosColors.danger.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: SalesPosColors.bodyBorder, width: 1.2),
        ),
        child: Text(
          'Rs ${amount.toStringAsFixed(2)}',
          maxLines: 1,
          style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900),
        ),
      ),
    ]);
  }
}

class _SettlementInput extends StatelessWidget {
  const _SettlementInput({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      SizedBox(
        height: 40,
        child: TextFormField(
          initialValue: initialValue,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(
                color: SalesPosColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide:
                  const BorderSide(color: SalesPosColors.textDark, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide:
                  const BorderSide(color: SalesPosColors.brandGold, width: 2),
            ),
          ),
          onChanged: (text) =>
              onChanged(double.tryParse(text.replaceAll(',', '')) ?? 0),
        ),
      ),
    ]);
  }
}
