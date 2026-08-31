import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

class ReturnReversalInvoiceSummaryPanel extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalInvoiceSummaryPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final operationType = controller.state.operationType;
    final sourceDocument = controller.state.selectedSourceDocument;
    final returnCartLineItems = controller.state.returnCartLineItems;
    final inspectionDrafts = controller.state.lineInspectionDrafts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final summaryBoard = _SummaryBoard(
          operationType: operationType,
          sourceDocument: sourceDocument,
          returnCartLineItems: returnCartLineItems,
          inspectionDrafts: inspectionDrafts,
        );

        return Container(
          decoration: BoxDecoration(
            color: SalesPosColors.billingRightPanelBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: SalesPosColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: SalesPosColors.shadowDark,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasBoundedHeight
                ? Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                          child: summaryBoard,
                        ),
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: _SummaryActions(operationType: operationType),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: summaryBoard,
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: _SummaryActions(operationType: operationType),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SummaryBoard extends StatelessWidget {
  final ReturnReversalOperationType operationType;
  final ReturnReversalSourceDocument? sourceDocument;
  final List<ReturnReversalSourceLineItem> returnCartLineItems;
  final Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts;

  const _SummaryBoard({
    required this.operationType,
    required this.sourceDocument,
    required this.returnCartLineItems,
    required this.inspectionDrafts,
  });

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Original invoice, return cart, and settlement'
        : 'Advance refund and booking closure';
  }

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    final metalBreakdowns = _buildMetalBreakdowns(document);
    final selectedMetalAmount = returnCartLineItems.fold<double>(
      0,
      (total, item) => total + _metalReturnAmount(item, inspectionDrafts),
    );
    final availableMaking = returnCartLineItems.fold<double>(
      0,
      (total, item) => total + _adjustedMakingAmount(item, inspectionDrafts),
    );
    final returnedMaking = returnCartLineItems.fold<double>(
      0,
      (total, item) {
        final draft = _draftFor(item, inspectionDrafts);
        if (!draft.includeMakingCharge) {
          return total;
        }
        return total + _adjustedMakingAmount(item, inspectionDrafts);
      },
    );
    final returnValue = selectedMetalAmount + returnedMaking;
    final netWeight = returnCartLineItems.fold<double>(
      0,
      (total, item) =>
          total +
          (inspectionDrafts[item.lineNo]?.receivedNetWeight ?? item.netWeight),
    );
    final originalInvoiceTotal = document == null
        ? 0.0
        : document.finalAmount > 0
            ? document.finalAmount
            : metalBreakdowns.fold<double>(
                0,
                (total, breakdown) => total + breakdown.displayInvoiceTotal,
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          icon: SalesPosIcons.invoiceOutline,
          title: 'RETURN SETTLEMENT',
          subtitle: _subtitle,
        ),
        const SizedBox(height: 18),
        const _MiniSectionLabel('Original Invoice Pricing'),
        const SizedBox(height: 8),
        if (metalBreakdowns.isEmpty)
          const _EmptySummaryText('Select an invoice to view metal totals.')
        else
          ...metalBreakdowns.map(_MetalSummaryTile.new),
        const SizedBox(height: 14),
        _InvoiceTotalBox(
          label: 'Original Invoice Total',
          value: _formatCurrency(originalInvoiceTotal),
        ),
        const SizedBox(height: 14),
        const _MiniSectionLabel('Payment Method'),
        const SizedBox(height: 8),
        _PaymentBreakupRow(sourceDocument: document),
        const SizedBox(height: 12),
        _PaymentStatusBox(sourceDocument: document),
        const SizedBox(height: 16),
        const _MiniSectionLabel('Return Cart'),
        const SizedBox(height: 8),
        _SelectedReturnCard(
          selectedCount: returnCartLineItems.length,
          netWeight: netWeight,
          metalAmount: selectedMetalAmount,
          availableMaking: availableMaking,
          returnedMaking: returnedMaking,
          returnValue: returnValue,
        ),
      ],
    );
  }

  List<_MetalInvoiceBreakdown> _buildMetalBreakdowns(
    ReturnReversalSourceDocument? document,
  ) {
    if (document == null || document.lineItems.isEmpty) {
      return const [];
    }

    final grouped = <String, _MetalInvoiceBreakdown>{};
    for (final item in document.lineItems) {
      final metal = item.metalType.trim().isEmpty
          ? 'OTHER'
          : item.metalType.trim().toUpperCase();
      grouped.putIfAbsent(metal, () => _MetalInvoiceBreakdown(metal)).add(item);
    }

    final values = grouped.values.toList(growable: false)
      ..sort((a, b) {
        final aRank = _metalRank(a.metal);
        final bRank = _metalRank(b.metal);
        if (aRank != bRank) {
          return aRank.compareTo(bRank);
        }
        return a.metal.compareTo(b.metal);
      });
    return values;
  }

  int _metalRank(String metal) {
    if (metal.contains('GOLD')) {
      return 0;
    }
    if (metal.contains('SILVER')) {
      return 1;
    }
    if (metal.contains('DIAMOND')) {
      return 2;
    }
    return 3;
  }
}

class _MetalInvoiceBreakdown {
  final String metal;
  var itemCount = 0;
  var netWeight = 0.0;
  var itemValue = 0.0;
  var makingAmount = 0.0;
  var discountAmount = 0.0;
  var taxableAmount = 0.0;
  var gstAmount = 0.0;
  var invoiceTotal = 0.0;

  _MetalInvoiceBreakdown(this.metal);

  double get gstPercent {
    final taxable = displayTaxableValue;
    if (taxable <= 0 || gstAmount <= 0) {
      return 0;
    }
    return gstAmount / taxable * 100;
  }

  double get displayTaxableValue {
    if (taxableAmount > 0) {
      return taxableAmount;
    }
    return math.max(0.0, itemValue - discountAmount);
  }

  double get displayInvoiceTotal {
    if (invoiceTotal > 0) {
      return invoiceTotal;
    }
    return math.max(0.0, displayTaxableValue + gstAmount);
  }

  void add(ReturnReversalSourceLineItem item) {
    final lineValue = item.displayLineTotal;
    itemCount += 1;
    netWeight += item.netWeight;
    itemValue += lineValue;
    makingAmount += item.makingAmount;
    discountAmount += item.discountAmount;
    taxableAmount += item.taxableAmount;
    gstAmount += item.gstAmount;
    invoiceTotal += item.invoiceValue > 0
        ? item.invoiceValue
        : math.max(0.0, lineValue - item.discountAmount + item.gstAmount);
  }
}

class _MetalSummaryTile extends StatelessWidget {
  final _MetalInvoiceBreakdown breakdown;

  const _MetalSummaryTile(this.breakdown);

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final gstLabel = breakdown.gstPercent > 0
        ? 'GST (${_formatPercent(breakdown.gstPercent)})'
        : 'GST';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$metalTitle Pricing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.bodyStrong.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCountLabel | ${breakdown.netWeight.toStringAsFixed(3)} g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.caption.copyWith(
                        color: SalesPosColors.bodyTextMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatCurrency(breakdown.displayInvoiceTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: SalesPosColors.bodyTextMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.72),
              ),
            ),
            child: Column(
              children: [
                _SubtleRow(
                  label: '$metalTitle Value',
                  value: _formatCurrency(breakdown.itemValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Discount',
                  value: _formatCurrency(breakdown.discountAmount),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Taxable Value',
                  value: _formatCurrency(breakdown.displayTaxableValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: gstLabel,
                  value: _formatCurrency(breakdown.gstAmount),
                ),
                const SizedBox(height: 9),
                _TotalRow(
                  label: '$metalTitle Total',
                  value: _formatCurrency(breakdown.displayInvoiceTotal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get itemCountLabel {
    final suffix = breakdown.itemCount == 1 ? 'item' : 'items';
    return '${breakdown.itemCount} $suffix';
  }
}

class _SelectedReturnCard extends StatelessWidget {
  final int selectedCount;
  final double netWeight;
  final double metalAmount;
  final double availableMaking;
  final double returnedMaking;
  final double returnValue;

  const _SelectedReturnCard({
    required this.selectedCount,
    required this.netWeight,
    required this.metalAmount,
    required this.availableMaking,
    required this.returnedMaking,
    required this.returnValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: Column(
        children: [
          _SubtleRow(label: 'Cart Items', value: selectedCount.toString()),
          const SizedBox(height: 9),
          _SubtleRow(
            label: 'Restored Net Weight',
            value: '${netWeight.toStringAsFixed(3)} g',
          ),
          const SizedBox(height: 9),
          _SubtleRow(
            label: 'Metal Amount',
            value: _formatCurrency(metalAmount),
          ),
          const SizedBox(height: 9),
          _SubtleRow(
            label: 'Making Available',
            value: _formatCurrency(availableMaking),
          ),
          const SizedBox(height: 9),
          _SubtleRow(
            label: 'Making Returned',
            value: _formatCurrency(returnedMaking),
          ),
          const SizedBox(height: 12),
          _PillarRow(
            label: 'Return Value',
            value: _formatCurrency(returnValue),
          ),
        ],
      ),
    );
  }
}

class _MiniSectionLabel extends StatelessWidget {
  final String label;

  const _MiniSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: SalesPosStyles.caption.copyWith(
        color: SalesPosColors.brandGold,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, color: SalesPosColors.brandGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.subTitleMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentBreakupRow extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;

  const _PaymentBreakupRow({required this.sourceDocument});

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    if (document == null) {
      return const _EmptySummaryText('Select an invoice to view payments.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (document.cashPaid > 0)
          _PaymentChip(label: 'Cash', value: document.cashPaid),
        if (document.upiPaid > 0)
          _PaymentChip(label: 'UPI', value: document.upiPaid),
        if (document.cardPaid > 0)
          _PaymentChip(label: 'Card', value: document.cardPaid),
        if (document.advancePaid > 0)
          _PaymentChip(label: 'Advance', value: document.advancePaid),
        if (document.cashPaid <= 0 &&
            document.upiPaid <= 0 &&
            document.cardPaid <= 0 &&
            document.advancePaid <= 0)
          _PaymentChip(label: 'Paid', value: document.paidAmount),
      ],
    );
  }
}

class _PaymentStatusBox extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;

  const _PaymentStatusBox({required this.sourceDocument});

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    final paidAmount = document?.paidAmount ?? 0;
    final dueAmount = document?.dueAmount ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        children: [
          _SubtleRow(label: 'Collected', value: _formatCurrency(paidAmount)),
          const SizedBox(height: 8),
          _SubtleRow(label: 'Balance Due', value: _formatCurrency(dueAmount)),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final double value;

  const _PaymentChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Text(
        '$label ${_formatCurrency(value)}',
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.bodyTextMain,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InvoiceTotalBox extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceTotalBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: _PillarRow(label: label, value: value),
    );
  }
}

class _EmptySummaryText extends StatelessWidget {
  final String text;

  const _EmptySummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SalesPosStyles.caption.copyWith(
        color: SalesPosColors.bodyTextMuted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SubtleRow extends StatelessWidget {
  final String label;
  final String value;

  const _SubtleRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.label,
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: SalesPosStyles.bodyStrong),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyStrong,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: SalesPosStyles.bodyStrong.copyWith(
              color: SalesPosColors.bodyTextMain,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String label;
  final String value;

  const _PillarRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyStrong,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: SalesPosColors.brandGold,
            fontSize: SalesPosStyles.fontValue,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.05),
            SalesPosColors.bodyBorder,
            SalesPosColors.brandGold.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

class _SummaryActions extends StatelessWidget {
  final ReturnReversalOperationType operationType;

  const _SummaryActions({required this.operationType});

  String get _buttonLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Process Return'
        : 'Process Cancellation';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimarySummaryButton(label: _buttonLabel),
        const SizedBox(height: 10),
        const _SecondarySummaryButton(label: 'Preview Document'),
      ],
    );
  }
}

class _PrimarySummaryButton extends StatelessWidget {
  final String label;

  const _PrimarySummaryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          disabledBackgroundColor: SalesPosColors.brandGold.withValues(
            alpha: 0.35,
          ),
          disabledForegroundColor: Colors.white,
          textStyle: SalesPosStyles.buttonText,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _SecondarySummaryButton extends StatelessWidget {
  final String label;

  const _SecondarySummaryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.visibility_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: SalesPosColors.bodyTextMuted,
          textStyle: SalesPosStyles.buttonText,
          side: const BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

String _formatMetalName(String metal) {
  final normalized = metal.trim().toUpperCase();
  if (normalized.isEmpty) {
    return 'Other';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1)}${word.substring(1).toLowerCase()}')
      .join(' ');
}

double _receivedWeightRatio(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  if (lineItem.netWeight <= 0) {
    return 1;
  }
  final receivedWeight = inspectionDrafts[lineItem.lineNo]?.receivedNetWeight ??
      lineItem.netWeight;
  return (receivedWeight / lineItem.netWeight).clamp(0.0, 1.0);
}

ReturnReversalLineInspectionDraft _draftFor(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return inspectionDrafts[lineItem.lineNo] ??
      ReturnReversalLineInspectionDraft.fromLine(lineItem);
}

double _adjustedLineAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.displayLineTotal *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _adjustedMakingAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.makingAmount *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _metalReturnAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return math.max(
    0.0,
    _adjustedLineAmount(lineItem, inspectionDrafts) -
        _adjustedMakingAmount(lineItem, inspectionDrafts),
  );
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return '${rounded.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(2)}%';
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
