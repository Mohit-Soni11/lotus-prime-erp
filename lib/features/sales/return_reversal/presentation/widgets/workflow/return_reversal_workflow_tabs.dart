import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

part 'return_reversal_workflow_inspection.dart';
part 'return_reversal_workflow_valuation.dart';
part 'return_reversal_workflow_settlement.dart';

extension _ReturnReversalWorkflowStepIcon on ReturnReversalWorkflowStep {
  IconData get icon {
    return switch (this) {
      ReturnReversalWorkflowStep.invoiceItems => Icons.receipt_long_rounded,
      ReturnReversalWorkflowStep.verification => Icons.verified_rounded,
      ReturnReversalWorkflowStep.weightCheck => Icons.scale_rounded,
      ReturnReversalWorkflowStep.valuation => Icons.currency_rupee_rounded,
      ReturnReversalWorkflowStep.stockRouting => Icons.account_tree_rounded,
      ReturnReversalWorkflowStep.settlement =>
        Icons.account_balance_wallet_rounded,
      ReturnReversalWorkflowStep.finish => Icons.task_alt_rounded,
    };
  }
}

extension _ReturnReversalStockRouteIcon on ReturnReversalStockRoute {
  IconData get icon {
    return switch (this) {
      ReturnReversalStockRoute.addToStock => Icons.inventory_2_rounded,
      ReturnReversalStockRoute.melting => Icons.local_fire_department_rounded,
      ReturnReversalStockRoute.managerHold =>
        Icons.admin_panel_settings_rounded,
    };
  }
}

class ReturnReversalWorkflowTabs extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalWorkflowTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final sourceDocument = state.selectedSourceDocument;
    final invoiceItems = state.invoiceLineItems;
    final activeLineItem = state.activeInspectionLineItem;
    final activeDraft = state.activeInspectionDraft;
    final isBookingCancellation = state.operationType.isBookingCancellation;

    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: SalesPosColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkflowHeader(
              operationType: state.operationType,
              itemCount: invoiceItems.length,
              cartCount: state.returnCartLineNumbers.length,
              activeStep: state.activeWorkflowStep,
              onStepSelected: controller.selectWorkflowStep,
            ),
            const SizedBox(height: 12),
            if (invoiceItems.isEmpty)
              _EmptyWorkflowState(isBookingCancellation: isBookingCancellation)
            else if (isBookingCancellation)
              _BookingCancellationPanel(controller: controller)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 980;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SelectedItemQueue(
                          controller: controller,
                          invoiceItems: invoiceItems,
                        ),
                        const SizedBox(height: 12),
                        activeLineItem == null
                            ? const _CompletedWorkflowState()
                            : _ActiveReturnInspectionPanel(
                                controller: controller,
                                sourceDocument: sourceDocument,
                                lineItem: activeLineItem,
                                draft: activeDraft,
                              ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 300,
                        child: _SelectedItemQueue(
                          controller: controller,
                          invoiceItems: invoiceItems,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: activeLineItem == null
                            ? const _CompletedWorkflowState()
                            : _ActiveReturnInspectionPanel(
                                controller: controller,
                                sourceDocument: sourceDocument,
                                lineItem: activeLineItem,
                                draft: activeDraft,
                              ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowHeader extends StatelessWidget {
  final ReturnReversalOperationType operationType;
  final int itemCount;
  final int cartCount;
  final ReturnReversalWorkflowStep activeStep;
  final ValueChanged<ReturnReversalWorkflowStep> onStepSelected;

  const _WorkflowHeader({
    required this.operationType,
    required this.itemCount,
    required this.cartCount,
    required this.activeStep,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isBookingCancellation = operationType.isBookingCancellation;
    final title =
        isBookingCancellation ? 'CANCELLATION WORKFLOW' : 'RETURN WORKFLOW';
    final subtitle = isBookingCancellation
        ? '$itemCount booking line${itemCount == 1 ? '' : 's'} loaded | advance settlement'
        : '$itemCount invoice item${itemCount == 1 ? '' : 's'} loaded | $cartCount in return cart';
    final steps = isBookingCancellation
        ? const [
            ReturnReversalWorkflowStep.invoiceItems,
            ReturnReversalWorkflowStep.settlement,
            ReturnReversalWorkflowStep.finish,
          ]
        : ReturnReversalWorkflowStep.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.34),
                ),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: SalesPosColors.brandGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: SalesPosStyles.bodyText.copyWith(
                      color: SalesPosColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final step in steps)
              _StageChip(
                step: step,
                label: isBookingCancellation &&
                        step == ReturnReversalWorkflowStep.invoiceItems
                    ? 'Booking'
                    : step.label,
                subtitle: isBookingCancellation &&
                        step == ReturnReversalWorkflowStep.invoiceItems
                    ? 'Advance source'
                    : step.subtitle,
                active: step == activeStep,
                onTap: () => onStepSelected(step),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  final ReturnReversalWorkflowStep step;
  final String label;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _StageChip({
    required this.step,
    required this.label,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? SalesPosColors.success : SalesPosColors.textDark;
    return Tooltip(
      message: subtitle,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 104),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active
                ? SalesPosColors.success.withValues(alpha: 0.10)
                : SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? SalesPosColors.success.withValues(alpha: 0.38)
                  : SalesPosColors.bodyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(step.icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedItemQueue extends StatelessWidget {
  final ReturnReversalController controller;
  final List<ReturnReversalSourceLineItem> invoiceItems;

  const _SelectedItemQueue({
    required this.controller,
    required this.invoiceItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invoice Return Items'.toUpperCase(),
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.brandGold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final lineItem in invoiceItems) ...[
            _QueueItemTile(
              lineItem: lineItem,
              active:
                  controller.state.activeInspectionLineNo == lineItem.lineNo,
              inCart: controller.isLineInReturnCart(lineItem.lineNo),
              onTap: () => controller.selectInspectionLine(lineItem.lineNo),
            ),
            if (lineItem != invoiceItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BookingCancellationPanel extends StatelessWidget {
  final ReturnReversalController controller;

  const _BookingCancellationPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final document = controller.state.selectedSourceDocument;
    final lineItem =
        document?.lineItems.isEmpty ?? true ? null : document!.lineItems.first;
    if (document == null || lineItem == null) {
      return const _EmptyWorkflowState(isBookingCancellation: true);
    }

    final refundValue = document.paidAmount > 0
        ? document.paidAmount
        : lineItem.displayLineTotal;
    final status =
        lineItem.isReversed ? _processedLineLabel(lineItem) : 'READY';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkflowSection(
            title: 'Booking',
            icon: Icons.event_note_rounded,
            child: _SnapshotBand(
              label: 'Booking Identity',
              children: [
                _SnapshotChip(
                  label: 'Booking No.',
                  value: document.documentNo,
                  width: 220,
                ),
                _SnapshotChip(label: 'Customer', value: document.customerName),
                _SnapshotChip(
                  label: 'Metal',
                  value: _metalLabel(lineItem.metalType),
                ),
                _SnapshotChip(label: 'Item', value: lineItem.description),
                _SnapshotChip(
                  label: 'Order Status',
                  value: _emptyAsDash(lineItem.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _WorkflowSection(
            title: 'Advance Settlement',
            icon: Icons.account_balance_wallet_rounded,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final width = compact
                    ? constraints.maxWidth
                    : math.max(180.0, (constraints.maxWidth - 24) / 4);
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: _MetricBox(
                        label: 'Booking Amount',
                        value: _formatCurrency(document.finalAmount),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricBox(
                        label: 'Advance Paid',
                        value: _formatCurrency(document.paidAmount),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricBox(
                        label: 'Refund Value',
                        value: _formatCurrency(refundValue),
                        highlight: true,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricBox(
                        label: 'Cancellation',
                        value: status,
                        highlight: !lineItem.isReversed,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final bool active;
  final bool inCart;
  final VoidCallback? onTap;

  const _QueueItemTile({
    required this.lineItem,
    required this.active,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(lineItem.metalType);
    final processed = lineItem.isReversed;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? (processed
                  ? SalesPosColors.danger.withValues(alpha: 0.06)
                  : SalesPosColors.success.withValues(alpha: 0.08))
              : processed
                  ? SalesPosColors.danger.withValues(alpha: 0.04)
                  : SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? (processed
                    ? SalesPosColors.danger.withValues(alpha: 0.42)
                    : SalesPosColors.success.withValues(alpha: 0.42))
                : processed
                    ? SalesPosColors.danger.withValues(alpha: 0.30)
                    : SalesPosColors.bodyBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${lineItem.lineNo}',
                style: SalesPosStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lineItem.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      fontSize: SalesPosStyles.fontLabel,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _QueueMetaChip(label: _metalLabel(lineItem.metalType)),
                      _QueueMetaChip(
                        label:
                            '${lineItem.quantity} ${_unitShortName(lineItem)}',
                      ),
                      _QueueMetaChip(
                        label: '${_formatWeight(lineItem.netWeight)} g',
                      ),
                      _QueueMetaChip(
                        label: _formatCurrency(lineItem.displayLineTotal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QueueStatusBadge(
              label: _processedLineLabel(lineItem),
              inCart: inCart,
              processed: processed,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueMetaChip extends StatelessWidget {
  final String label;

  const _QueueMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.textDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QueueStatusBadge extends StatelessWidget {
  final String label;
  final bool inCart;
  final bool processed;

  const _QueueStatusBadge({
    required this.label,
    required this.inCart,
    required this.processed,
  });

  @override
  Widget build(BuildContext context) {
    final color = processed
        ? SalesPosColors.danger
        : inCart
            ? SalesPosColors.success
            : SalesPosColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        processed
            ? label
            : inCart
                ? 'ADDED'
                : 'PENDING',
        style: SalesPosStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
