import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: _SummaryBoard(
                operationType: operationType,
                sourceDocument: sourceDocument,
              ),
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
  }
}

class _SummaryBoard extends StatelessWidget {
  final ReturnReversalOperationType operationType;
  final ReturnReversalSourceDocument? sourceDocument;

  const _SummaryBoard({
    required this.operationType,
    required this.sourceDocument,
  });

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Return value and stock reversal'
        : 'Advance refund and booking closure';
  }

  String get _netLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Refundable Value'
        : 'Refundable Advance';
  }

  @override
  Widget build(BuildContext context) {
    final grossValue = sourceDocument?.grossValue ?? 0;
    final refundableValue = sourceDocument?.paidAmount ?? 0;
    final itemCount = sourceDocument?.itemCount ?? 0;
    final netWeight = sourceDocument?.netWeight ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          icon: SalesPosIcons.invoiceOutline,
          title: 'INVOICE SUMMARY',
          subtitle: _subtitle,
        ),
        const SizedBox(height: 18),
        _SubtleRow(label: 'Gross Value', value: _formatCurrency(grossValue)),
        const SizedBox(height: 10),
        _SubtleRow(label: 'Returned Items', value: itemCount.toString()),
        const SizedBox(height: 10),
        _SubtleRow(
          label: 'Restored Net Weight',
          value: '${netWeight.toStringAsFixed(3)} g',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
          ),
          child: _PillarRow(
            label: _netLabel,
            value: _formatCurrency(refundableValue),
          ),
        ),
      ],
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
