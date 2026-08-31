import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

class ReturnReversalWorkflowTabs extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalWorkflowTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItems = controller.state.selectedLineItems;
    final activeLineItem = controller.state.activeInspectionLineItem;
    final activeDraft = controller.state.activeInspectionDraft;

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
              selectedCount: selectedItems.length,
              activeStep: controller.state.activeWorkflowStep,
              onStepSelected: controller.selectWorkflowStep,
            ),
            const SizedBox(height: 12),
            if (selectedItems.isEmpty)
              const _EmptyWorkflowState()
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
                          selectedItems: selectedItems,
                        ),
                        const SizedBox(height: 12),
                        _ActiveReturnInspectionPanel(
                          controller: controller,
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
                          selectedItems: selectedItems,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActiveReturnInspectionPanel(
                          controller: controller,
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
  final int selectedCount;
  final ReturnReversalWorkflowStep activeStep;
  final ValueChanged<ReturnReversalWorkflowStep> onStepSelected;

  const _WorkflowHeader({
    required this.selectedCount,
    required this.activeStep,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'RETURN WORKFLOW',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.highVisHeader,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$selectedCount selected item${selectedCount == 1 ? '' : 's'} in physical verification',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.subTitleMuted,
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
            for (final step in ReturnReversalWorkflowStep.values)
              _StageChip(
                step: step,
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
  final bool active;
  final VoidCallback onTap;

  const _StageChip({
    required this.step,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? SalesPosColors.success : SalesPosColors.bodyTextMuted;
    return Tooltip(
      message: step.subtitle,
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
                step.label,
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
  final List<ReturnReversalSourceLineItem> selectedItems;

  const _SelectedItemQueue({
    required this.controller,
    required this.selectedItems,
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
            'Selected Return Items'.toUpperCase(),
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.brandGold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final lineItem in selectedItems) ...[
            _QueueItemTile(
              lineItem: lineItem,
              active:
                  controller.state.activeInspectionLineNo == lineItem.lineNo,
              onTap: () => controller.selectInspectionLine(lineItem.lineNo),
            ),
            if (lineItem != selectedItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final bool active;
  final VoidCallback onTap;

  const _QueueItemTile({
    required this.lineItem,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(lineItem.metalType);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? SalesPosColors.success.withValues(alpha: 0.08)
              : SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? SalesPosColors.success.withValues(alpha: 0.42)
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
                  Text(
                    '${_metalLabel(lineItem.metalType)} | ${_formatWeight(lineItem.netWeight)} g | ${_formatCurrency(lineItem.displayLineTotal)}',
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
          ],
        ),
      ),
    );
  }
}

class _ActiveReturnInspectionPanel extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalSourceLineItem? lineItem;
  final ReturnReversalLineInspectionDraft? draft;

  const _ActiveReturnInspectionPanel({
    required this.controller,
    required this.lineItem,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final item = lineItem;
    final inspectionDraft = draft;
    if (item == null || inspectionDraft == null) {
      return const _EmptyWorkflowState();
    }

    final ratio = _receivedWeightRatio(item, inspectionDraft);
    final adjustedLineValue = item.displayLineTotal * ratio;
    final adjustedMaking = item.makingAmount * ratio;
    final metalReturnValue = math.max(0.0, adjustedLineValue - adjustedMaking);
    final returnAmount = metalReturnValue +
        (inspectionDraft.includeMakingCharge ? adjustedMaking : 0);
    final shortageWeight =
        math.max(0.0, item.netWeight - inspectionDraft.receivedNetWeight);
    final shortageValue =
        math.max(0.0, item.displayLineTotal - adjustedLineValue);

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
          _ActiveItemHeader(lineItem: item),
          const SizedBox(height: 12),
          _WorkflowSection(
            title: 'Verification',
            icon: Icons.verified_rounded,
            child: Column(
              children: [
                _SnapshotGrid(lineItem: item),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _VerificationToggle(
                        label: 'HUID matched',
                        value: inspectionDraft.huidMatched,
                        onChanged: (value) =>
                            controller.setHuidMatched(item.lineNo, value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VerificationToggle(
                        label: 'Unit matched',
                        value: inspectionDraft.unitMatched,
                        onChanged: (value) =>
                            controller.setUnitMatched(item.lineNo, value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _WorkflowSection(
            title: 'Weight Check',
            icon: Icons.scale_rounded,
            child: _WeightCheckGrid(
              lineItem: item,
              draft: inspectionDraft,
              shortageWeight: shortageWeight,
              shortageValue: shortageValue,
              metalValue: metalReturnValue,
              onReceivedWeightChanged: (weight) =>
                  controller.updateReceivedNetWeight(item.lineNo, weight),
            ),
          ),
          const SizedBox(height: 10),
          _WorkflowSection(
            title: 'Valuation',
            icon: Icons.currency_rupee_rounded,
            child: _MakingReturnDecision(
              includeMaking: inspectionDraft.includeMakingCharge,
              metalValue: metalReturnValue,
              makingValue: adjustedMaking,
              returnAmount: returnAmount,
              onChanged: (includeMaking) => controller.setLineMakingReturn(
                item.lineNo,
                includeMaking,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _WorkflowSection(
            title: 'Stock Routing',
            icon: Icons.account_tree_rounded,
            child: _StockRouteSelector(
              selectedRoute: inspectionDraft.stockRoute,
              onRouteSelected: (route) =>
                  controller.setStockRoute(item.lineNo, route),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveItemHeader extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _ActiveItemHeader({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(lineItem.metalType);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            '${lineItem.lineNo}',
            style: SalesPosStyles.bodyStrong.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lineItem.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 3),
              Text(
                '${_metalLabel(lineItem.metalType)} invoice item verification',
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

class _WorkflowSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _WorkflowSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: SalesPosColors.brandGold, size: 17),
              const SizedBox(width: 7),
              Text(
                title,
                style: SalesPosStyles.bodyStrong.copyWith(
                  fontSize: SalesPosStyles.fontLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _SnapshotGrid({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SnapshotChip(label: 'HUID', value: _emptyAsDash(lineItem.huidNumber)),
        _SnapshotChip(
          label: 'Unit',
          value:
              '${lineItem.quantity} ${lineItem.quantityUnitCode.isEmpty ? 'PCS' : lineItem.quantityUnitCode}',
        ),
        _SnapshotChip(label: 'Purity', value: lineItem.purity),
        _SnapshotChip(label: 'HSN', value: _emptyAsDash(lineItem.hsnCode)),
        _SnapshotChip(
          label: 'Sold Net',
          value: '${_formatWeight(lineItem.netWeight)} g',
        ),
        _SnapshotChip(
          label: 'Sold Item Value',
          value: _formatCurrency(lineItem.displayLineTotal),
        ),
        _SnapshotChip(
          label: 'Sold Making',
          value: _formatCurrency(lineItem.makingAmount),
        ),
      ],
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.bodyTextMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyStrong.copyWith(
              fontSize: SalesPosStyles.fontLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VerificationToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? SalesPosColors.success : SalesPosColors.danger;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: color,
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

class _WeightCheckGrid extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final ReturnReversalLineInspectionDraft draft;
  final double shortageWeight;
  final double shortageValue;
  final double metalValue;
  final ValueChanged<double> onReceivedWeightChanged;

  const _WeightCheckGrid({
    required this.lineItem,
    required this.draft,
    required this.shortageWeight,
    required this.shortageValue,
    required this.metalValue,
    required this.onReceivedWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final fieldWidth = compact
            ? constraints.maxWidth
            : math.max(180.0, (constraints.maxWidth - 24) / 4);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Sold Net Weight',
                value: '${_formatWeight(lineItem.netWeight)} g',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _ReceivedWeightInput(
                key: ValueKey('received-weight-${lineItem.lineNo}'),
                value: draft.receivedNetWeight,
                onChanged: onReceivedWeightChanged,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Short Weight',
                value: '${_formatWeight(shortageWeight)} g',
                danger: shortageWeight > 0,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Metal Value',
                value: _formatCurrency(metalValue),
                highlight: true,
              ),
            ),
            if (shortageValue > 0)
              SizedBox(
                width: fieldWidth,
                child: _MetricBox(
                  label: 'Value Deduction',
                  value: _formatCurrency(shortageValue),
                  danger: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MakingReturnDecision extends StatelessWidget {
  final bool includeMaking;
  final double metalValue;
  final double makingValue;
  final double returnAmount;
  final ValueChanged<bool> onChanged;

  const _MakingReturnDecision({
    required this.includeMaking,
    required this.metalValue,
    required this.makingValue,
    required this.returnAmount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final optionWidth = compact ? constraints.maxWidth : 210.0;
        final metricWidth = compact
            ? constraints.maxWidth
            : math.max(190.0, constraints.maxWidth - (optionWidth * 2) - 16);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: optionWidth,
              child: _ValuationChoiceTile(
                title: 'Metal Value Only',
                subtitle: _formatCurrency(metalValue),
                icon: Icons.workspace_premium_rounded,
                selected: !includeMaking,
                onTap: () => onChanged(false),
              ),
            ),
            SizedBox(
              width: optionWidth,
              child: _ValuationChoiceTile(
                title: 'Metal + Making',
                subtitle: '+ ${_formatCurrency(makingValue)}',
                icon: Icons.add_circle_rounded,
                selected: includeMaking,
                onTap: () => onChanged(true),
              ),
            ),
            SizedBox(
              width: metricWidth,
              child: _MetricBox(
                label: 'This Item Return',
                value: _formatCurrency(returnAmount),
                highlight: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ValuationChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ValuationChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? SalesPosColors.success : SalesPosColors.bodyTextMain;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      color: color,
                      fontSize: SalesPosStyles.fontLabel,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.caption.copyWith(
                      color: selected
                          ? SalesPosColors.success
                          : SalesPosColors.bodyTextMuted,
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

class _ReceivedWeightInput extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ReceivedWeightInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Received Net Weight',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.bodyTextMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(
            height: 26,
            child: TextFormField(
              initialValue: _formatWeight(value),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text.trim());
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
              style: SalesPosStyles.bodyStrong.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixText: 'g',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool danger;

  const _MetricBox({
    required this.label,
    required this.value,
    this.highlight = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? SalesPosColors.danger
        : highlight
            ? SalesPosColors.brandGold
            : SalesPosColors.bodyTextMain;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: danger
              ? SalesPosColors.danger.withValues(alpha: 0.28)
              : SalesPosColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.bodyTextMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRouteSelector extends StatelessWidget {
  final ReturnReversalStockRoute selectedRoute;
  final ValueChanged<ReturnReversalStockRoute> onRouteSelected;

  const _StockRouteSelector({
    required this.selectedRoute,
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
                  onTap: () => onRouteSelected(route),
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
  final VoidCallback onTap;

  const _RouteTile({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? SalesPosColors.success : SalesPosColors.bodyTextMain;
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
                      color: SalesPosColors.bodyTextMuted,
                      fontWeight: FontWeight.w800,
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

class _EmptyWorkflowState extends StatelessWidget {
  const _EmptyWorkflowState();

  @override
  Widget build(BuildContext context) {
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
              'Select invoice items above to start HUID, unit, weight, and stock-route verification.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.subTitleMuted,
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

String _formatWeight(double value) => value.toStringAsFixed(3);

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
