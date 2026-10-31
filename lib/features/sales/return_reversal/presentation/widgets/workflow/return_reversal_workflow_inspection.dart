part of 'return_reversal_workflow_tabs.dart';

class _ActiveReturnInspectionPanel extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalSourceDocument? sourceDocument;
  final ReturnReversalSourceLineItem? lineItem;
  final ReturnReversalLineInspectionDraft? draft;

  const _ActiveReturnInspectionPanel({
    required this.controller,
    required this.sourceDocument,
    required this.lineItem,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final item = lineItem;
    final inspectionDraft = draft;
    final document = sourceDocument;
    if (item == null || inspectionDraft == null) {
      return const _EmptyWorkflowState(isBookingCancellation: false);
    }

    final readOnly = item.isReversed;
    final ratio = _receivedWeightRatio(item, inspectionDraft);
    final adjustedLineValue = item.displayLineTotal * ratio;
    final adjustedMaking = item.makingAmount * ratio;
    final metalReturnValue = (readOnly
            ? item.reversalMetalReturnAmount ??
                math.max(0.0, adjustedLineValue - adjustedMaking)
            : math.max(0.0, adjustedLineValue - adjustedMaking))
        .toDouble();
    final makingReturnValue = (readOnly
            ? item.reversalMakingReturnedAmount ?? 0
            : inspectionDraft.includeMakingCharge
                ? adjustedMaking
                : 0)
        .toDouble();
    final returnAmount = (readOnly
            ? item.reversalLineReturnValue ??
                metalReturnValue + makingReturnValue
            : metalReturnValue + makingReturnValue)
        .toDouble();
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
          _ActiveItemHeader(
            lineItem: item,
            documentDate: document?.documentDate,
            readOnly: readOnly,
          ),
          if (readOnly) ...[
            const SizedBox(height: 10),
            _ReturnAuditBanner(lineItem: item),
          ],
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
                        readOnly: readOnly,
                        onChanged: (value) =>
                            controller.setHuidMatched(item.lineNo, value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VerificationToggle(
                        label: 'Unit matched',
                        value: inspectionDraft.unitMatched,
                        readOnly: readOnly,
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
              readOnly: readOnly,
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
              makingValue: readOnly && makingReturnValue > 0
                  ? makingReturnValue
                  : adjustedMaking,
              returnAmount: returnAmount,
              readOnly: readOnly,
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
              readOnly: readOnly,
              onRouteSelected: (route) =>
                  controller.setStockRoute(item.lineNo, route),
            ),
          ),
          const SizedBox(height: 12),
          _ReturnCartActionBar(
            inCart: controller.isLineInReturnCart(item.lineNo),
            processed: item.isReversed,
            voucherNo: item.reversalVoucherNo,
            returnAmount: returnAmount,
            route: inspectionDraft.stockRoute,
            onAdd: () => controller.addLineToReturnCart(item.lineNo),
            onRemove: () => controller.removeLineFromReturnCart(item.lineNo),
          ),
        ],
      ),
    );
  }
}

class _ActiveItemHeader extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final DateTime? documentDate;
  final bool readOnly;

  const _ActiveItemHeader({
    required this.lineItem,
    required this.documentDate,
    required this.readOnly,
  });

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
                '${readOnly ? 'Read-only return audit' : '${_metalLabel(lineItem.metalType)} invoice item verification'} | Invoice Date ${_formatDate(documentDate)}',
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
    );
  }
}

class _ReturnAuditBanner extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _ReturnAuditBanner({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.danger.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_rounded,
            color: SalesPosColors.danger,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${_processedLineLabel(lineItem)} | Voucher ${_emptyAsDash(lineItem.reversalVoucherNo)} | Returned ${_formatDate(lineItem.reversalDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.textDark,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SnapshotBand(
          label: 'Item Identity',
          children: [
            _SnapshotChip(
                label: 'Metal', value: _metalLabel(lineItem.metalType)),
            _SnapshotChip(label: 'Item', value: lineItem.description),
            _SnapshotChip(
                label: 'HUID', value: _emptyAsDash(lineItem.huidNumber)),
            _SnapshotChip(
                label: 'Unit',
                value: '${lineItem.quantity} ${_unitShortName(lineItem)}'),
            _SnapshotChip(label: 'Purity', value: lineItem.purity),
            _SnapshotChip(label: 'HSN', value: _emptyAsDash(lineItem.hsnCode)),
          ],
        ),
        const SizedBox(height: 10),
        _SnapshotBand(
          label: 'Original Sale',
          children: [
            _SnapshotChip(
              label: 'Sold Net Weight',
              value: '${_formatWeight(lineItem.netWeight)} g',
            ),
            _SnapshotChip(label: 'Rate', value: _formatCurrency(lineItem.rate)),
            _SnapshotChip(
              label: 'Making Input',
              value: _formatMakingInput(lineItem),
            ),
            _SnapshotChip(
              label: 'Making Amount',
              value: _formatCurrency(lineItem.makingAmount),
            ),
            _SnapshotChip(
              label: 'Item Value',
              value: _formatCurrency(lineItem.displayLineTotal),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SnapshotBand(
          label: 'Tax Snapshot',
          children: [
            _SnapshotChip(
              label: 'Discount',
              value: _formatCurrency(lineItem.discountAmount),
            ),
            _SnapshotChip(
              label: 'Taxable Value',
              value: _formatCurrency(lineItem.taxableAmount),
            ),
            _SnapshotChip(
                label: 'GST', value: _formatCurrency(lineItem.gstAmount)),
            _SnapshotChip(
              label: 'Invoice Line Total',
              value: _formatCurrency(
                lineItem.invoiceValue > 0
                    ? lineItem.invoiceValue
                    : lineItem.displayLineTotal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SnapshotBand extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SnapshotBand({
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.brandGold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  final String label;
  final String value;
  final double width;

  const _SnapshotChip({
    required this.label,
    required this.value,
    this.width = 132,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
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
