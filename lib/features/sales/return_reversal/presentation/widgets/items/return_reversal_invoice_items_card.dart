import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

const double _sourceItemsTableWidth = 1280;

class ReturnReversalInvoiceItemsCard extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalInvoiceItemsCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final operationType = controller.state.operationType;
    final selectedDocument = controller.state.selectedSourceDocument;
    final lineItems = selectedDocument?.lineItems ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.itemsTableBg,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemsHeader(
            itemCount: lineItems.length,
            operationType: operationType,
          ),
          const _ColumnHeaderRow(),
          if (lineItems.isEmpty)
            _EmptyItemsState(operationType: operationType)
          else
            _LoadedItemsList(
              controller: controller,
              lineItems: lineItems,
            ),
          _ItemsFooter(
            controller: controller,
            document: selectedDocument,
            operationType: operationType,
          ),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  final int itemCount;
  final ReturnReversalOperationType operationType;

  const _ItemsHeader({
    required this.itemCount,
    required this.operationType,
  });

  String get _title {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'INVOICE ITEMS'
        : 'BOOKING ITEMS';
  }

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Select sold items that are being returned'
        : 'Review booked items before cancellation';
  }

  String get _counterLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'RETURN : $itemCount'
        : 'CANCEL : $itemCount';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.06),
        border: const Border(
          bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.40),
                ),
              ),
              child: const Center(
                child: Icon(
                  SalesPosIcons.invoiceItemsHeader,
                  color: SalesPosColors.brandGold,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.highVisHeader,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.subTitleMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SalesPosColors.brandGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _counterLabel,
                    style: const TextStyle(
                      fontSize: SalesPosStyles.fontBody,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      color: SalesPosColors.bodyTextMain,
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

class _ColumnHeaderRow extends StatelessWidget {
  const _ColumnHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SalesPosColors.bodyBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _sourceItemsTableWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: SalesPosColors.bodyBg,
              border: Border(
                bottom: BorderSide(
                  color: SalesPosColors.bodyBorder,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _header('S.NO', flex: 1, center: true),
                const SizedBox(width: 6),
                _header('METAL', flex: 3),
                const SizedBox(width: 6),
                _header('ITEM DESCRIPTION', flex: 4),
                const SizedBox(width: 6),
                _header('PCS', flex: 2, center: true),
                const SizedBox(width: 6),
                _header('HUID / SET', flex: 3, center: true),
                const SizedBox(width: 6),
                _header('PURITY', flex: 2, center: true),
                const SizedBox(width: 6),
                _header('NET WT', flex: 2, center: true),
                const SizedBox(width: 6),
                _header('RATE', flex: 3, right: true),
                const SizedBox(width: 6),
                _header('MAKING', flex: 3, right: true),
                const SizedBox(width: 6),
                _header('TOTAL', flex: 3, right: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
    String text, {
    required int flex,
    bool right = false,
    bool center = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.tableColumnHeader,
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  final ReturnReversalOperationType operationType;

  const _EmptyItemsState({required this.operationType});

  String get _title {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'NO INVOICE SELECTED'
        : 'NO BOOKING SELECTED';
  }

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Enter or search an invoice number to load returnable items'
        : 'Enter or search a booking number to load cancellable items';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 58),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SalesPosColors.bodyBorder, width: 2),
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                color: SalesPosColors.brandGold,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SalesPosColors.bodyTextMain,
                fontSize: SalesPosStyles.fontTitle,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: SalesPosStyles.subTitleMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedItemsList extends StatelessWidget {
  final ReturnReversalController controller;
  final List<ReturnReversalSourceLineItem> lineItems;

  const _LoadedItemsList({
    required this.controller,
    required this.lineItems,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _sourceItemsTableWidth,
        child: Column(
          children: [
            for (final lineItem in lineItems) ...[
              _SourceItemRow(
                lineItem: lineItem,
                selected: controller.isSourceLineSelected(lineItem.lineNo),
                onTap: () =>
                    controller.toggleSourceLineSelection(lineItem.lineNo),
              ),
              const Divider(height: 1, color: SalesPosColors.bodyBorder),
            ],
            _SourceItemsTotalRow(lineItems: controller.state.selectedLineItems),
          ],
        ),
      ),
    );
  }
}

class _SourceItemRow extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final bool selected;
  final VoidCallback onTap;

  const _SourceItemRow({
    required this.lineItem,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metalColor = _metalColor(lineItem.metalType);

    return InkWell(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.success.withValues(alpha: 0.06)
                : SalesPosColors.bodyPanelBg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: _SourceLineNumber(
                  number: lineItem.lineNo,
                  color: metalColor,
                  selected: selected,
                ),
              ),
              const SizedBox(width: 6),
              _MetalSnapshotCell(lineItem: lineItem, color: metalColor),
              const SizedBox(width: 6),
              _ItemDetailsCell(lineItem: lineItem),
              const SizedBox(width: 6),
              _QuantitySnapshotCell(lineItem: lineItem),
              const SizedBox(width: 6),
              _HuidChip(value: lineItem.huidNumber),
              const SizedBox(width: 6),
              _ReadOnlyPosCell(
                value: lineItem.purity,
                flex: 2,
                center: true,
                color: metalColor,
                tooltip: 'Purity snapshot',
              ),
              const SizedBox(width: 6),
              _ReadOnlyPosCell(
                value: _formatWeight(lineItem.netWeight),
                flex: 2,
                center: true,
                color: metalColor,
                tooltip: 'Net weight',
                strong: true,
              ),
              const SizedBox(width: 6),
              _ReadOnlyPosCell(
                value: _formatCurrency(lineItem.rate),
                flex: 3,
                right: true,
                tooltip: 'Rate snapshot',
              ),
              const SizedBox(width: 6),
              _MakingSnapshotCell(lineItem: lineItem),
              const SizedBox(width: 6),
              _ReadOnlyPosCell(
                value: _formatCurrency(lineItem.displayLineTotal),
                flex: 3,
                right: true,
                tooltip: 'Invoice line total',
                strong: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDetailsCell extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _ItemDetailsCell({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: SizedBox(
        height: 38,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lineItem.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyStrong.copyWith(height: 1),
              ),
              if (lineItem.hsnCode.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'HSN ${lineItem.hsnCode.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.bodyTextMuted,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceLineNumber extends StatelessWidget {
  final int number;
  final Color color;
  final bool selected;

  const _SourceLineNumber({
    required this.number,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? SalesPosColors.success.withValues(alpha: 0.14)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected
                ? SalesPosColors.success.withValues(alpha: 0.55)
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                color: SalesPosColors.success,
                size: 18,
              )
            : Text(
                '$number',
                style: TextStyle(
                  color: color,
                  fontSize: SalesPosStyles.fontBody,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}

class _MetalSnapshotCell extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final Color color;

  const _MetalSnapshotCell({
    required this.lineItem,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.40)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _metalLabel(lineItem.metalType),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.inputText.copyWith(
                  color: color,
                  fontSize: SalesPosStyles.fontBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySnapshotCell extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _QuantitySnapshotCell({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Tooltip(
        message: 'Sold quantity',
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            color: SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lineItem.quantity.toString(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.inputText.copyWith(
                    color: SalesPosColors.bodyTextMain,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _UnitSuffixBadge(lineItem: lineItem),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitSuffixBadge extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _UnitSuffixBadge({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(lineItem.metalType);

    return Container(
      height: 26,
      constraints: const BoxConstraints(minWidth: 42),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _unitShortName(lineItem),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReadOnlyPosCell extends StatelessWidget {
  final String value;
  final int flex;
  final bool center;
  final bool right;
  final bool strong;
  final String tooltip;
  final Color color;

  const _ReadOnlyPosCell({
    required this.value,
    required this.flex,
    required this.tooltip,
    this.center = false,
    this.right = false,
    this.strong = false,
    this.color = SalesPosColors.bodyTextMain,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = center
        ? Alignment.center
        : right
            ? Alignment.centerRight
            : Alignment.centerLeft;

    return Expanded(
      flex: flex,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: alignment,
          decoration: BoxDecoration(
            color:
                strong ? color.withValues(alpha: 0.08) : SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: strong
                  ? color.withValues(alpha: 0.25)
                  : SalesPosColors.bodyBorder,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: right
                  ? TextAlign.right
                  : center
                      ? TextAlign.center
                      : TextAlign.left,
              style: SalesPosStyles.inputText.copyWith(
                color: color,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MakingSnapshotCell extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _MakingSnapshotCell({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          _MakingInputBadge(lineItem: lineItem),
          const SizedBox(width: 4),
          Expanded(
            child: _ReadOnlyBox(
              value: _formatMoneyOrDash(lineItem.makingAmount),
              tooltip: 'Making amount snapshot',
              right: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MakingInputBadge extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _MakingInputBadge({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Original making input',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        width: 54,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: 0.12),
          border: Border.all(
            color: SalesPosColors.brandGold.withValues(alpha: 0.40),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatMakingInput(lineItem),
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: SalesPosColors.brandGold,
              fontSize: SalesPosStyles.fontLabel,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String value;
  final String tooltip;
  final bool right;

  const _ReadOnlyBox({
    required this.value,
    required this.tooltip,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: SalesPosColors.bodyBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: SalesPosStyles.inputText.copyWith(
              color: SalesPosColors.bodyTextMain,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceItemsTotalRow extends StatelessWidget {
  final List<ReturnReversalSourceLineItem> lineItems;

  const _SourceItemsTotalRow({required this.lineItems});

  @override
  Widget build(BuildContext context) {
    final quantity = lineItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
    final netWeight = lineItems.fold<double>(
      0,
      (total, item) => total + item.netWeight,
    );
    final making = lineItems.fold<double>(
      0,
      (total, item) => total + item.makingAmount,
    );
    final value = lineItems.fold<double>(
      0,
      (total, item) => total + item.displayLineTotal,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: SalesPosColors.bodyBg,
      child: Row(
        children: [
          _totalCell('TOTAL', flex: 1, center: true),
          const SizedBox(width: 6),
          _totalCell('${lineItems.length} lines', flex: 3),
          const SizedBox(width: 6),
          _totalCell('SOURCE SNAPSHOT', flex: 4),
          const SizedBox(width: 6),
          _totalCell(quantity.toString(), flex: 2, center: true),
          const SizedBox(width: 6),
          _totalCell('-', flex: 3, center: true),
          const SizedBox(width: 6),
          _totalCell('-', flex: 2, center: true),
          const SizedBox(width: 6),
          _totalCell('${_formatWeight(netWeight)} g', flex: 2, center: true),
          const SizedBox(width: 6),
          _totalCell('-', flex: 3, right: true),
          const SizedBox(width: 6),
          _totalCell(_formatMoneyOrDash(making), flex: 3, right: true),
          const SizedBox(width: 6),
          _totalCell(_formatCurrency(value), flex: 3, right: true),
        ],
      ),
    );
  }

  Widget _totalCell(
    String value, {
    required int flex,
    bool center = false,
    bool right = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SalesPosColors.bodyTextMain,
          fontSize: SalesPosStyles.fontLabel,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HuidChip extends StatelessWidget {
  final String value;

  const _HuidChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim();
    final hasValue = cleanValue.isNotEmpty;

    return Expanded(
      flex: 3,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: hasValue
                ? SalesPosColors.bodyTextMain.withValues(alpha: 0.05)
                : SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? SalesPosColors.bodyTextMain.withValues(alpha: 0.16)
                  : SalesPosColors.bodyBorder,
            ),
          ),
          child: Text(
            hasValue ? cleanValue : '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasValue
                  ? SalesPosColors.bodyTextMain
                  : SalesPosColors.bodyTextMuted,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsFooter extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalSourceDocument? document;
  final ReturnReversalOperationType operationType;

  const _ItemsFooter({
    required this.controller,
    required this.document,
    required this.operationType,
  });

  String get _actionLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'LOAD INVOICE ITEMS'
        : 'LOAD BOOKING ITEMS';
  }

  String get _loadedLabel {
    return document == null ? _actionLabel : 'LOADED : ${document!.documentNo}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = controller.state.selectedLineNumbers.length;
    final totalCount = document?.lineItems.length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        border: Border(
          top: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: document == null ? () => controller.searchRecords() : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SalesPosColors.success.withValues(alpha: 0.08),
                border: Border.all(
                  color: SalesPosColors.success.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.playlist_add_check_rounded,
                    color: SalesPosColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _loadedLabel,
                    style: const TextStyle(
                      color: SalesPosColors.success,
                      fontSize: SalesPosStyles.fontBody,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (document != null) ...[
            const Spacer(),
            _SelectionFooterChip(
              label: '$selectedCount / $totalCount selected',
              onTap: controller.selectAllSourceLines,
            ),
            const SizedBox(width: 10),
            _SelectionFooterChip(
              label: 'CLEAR',
              onTap: controller.clearSourceLineSelection,
              danger: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionFooterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _SelectionFooterChip({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? SalesPosColors.danger : SalesPosColors.brandGold;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(
          label,
          style: SalesPosStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _formatWeight(double value) => value.toStringAsFixed(3);

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

String _formatMoneyOrDash(double value) {
  if (value.abs() < 0.01) {
    return '-';
  }
  return _formatCurrency(value);
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
