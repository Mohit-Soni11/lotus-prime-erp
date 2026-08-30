import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

const double _sourceItemsTableWidth = 1240;

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
            _LoadedItemsList(lineItems: lineItems),
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
                _header('ITEM DETAILS', flex: 5),
                const SizedBox(width: 6),
                _header('PCS', flex: 1, center: true),
                const SizedBox(width: 6),
                _header('GROSS WT', flex: 2, center: true),
                const SizedBox(width: 6),
                _header('NET WT', flex: 2, center: true),
                const SizedBox(width: 6),
                _header('RATE', flex: 2, right: true),
                const SizedBox(width: 6),
                _header('MAKING', flex: 2, right: true),
                const SizedBox(width: 6),
                _header('HUID NO.', flex: 3, center: true),
                const SizedBox(width: 6),
                _header('VALUE', flex: 2, right: true),
                const SizedBox(width: 6),
                _header('STATUS', flex: 2, center: true),
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
  final List<ReturnReversalSourceLineItem> lineItems;

  const _LoadedItemsList({required this.lineItems});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _sourceItemsTableWidth,
        child: Column(
          children: [
            for (final lineItem in lineItems) ...[
              _SourceItemRow(lineItem: lineItem),
              const Divider(height: 1, color: SalesPosColors.bodyBorder),
            ],
            _SourceItemsTotalRow(lineItems: lineItems),
          ],
        ),
      ),
    );
  }
}

class _SourceItemRow extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _SourceItemRow({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell(lineItem.lineNo.toString(), flex: 1, center: true),
          const SizedBox(width: 6),
          _ItemDetailsCell(lineItem: lineItem),
          const SizedBox(width: 6),
          _cell(lineItem.quantity.toString(), flex: 1, center: true),
          const SizedBox(width: 6),
          _cell(
            '${_formatWeight(lineItem.grossWeight)} g',
            flex: 2,
            center: true,
          ),
          const SizedBox(width: 6),
          _cell('${_formatWeight(lineItem.netWeight)} g',
              flex: 2, center: true),
          const SizedBox(width: 6),
          _cell(_formatCurrency(lineItem.rate), flex: 2, right: true),
          const SizedBox(width: 6),
          _cell(_formatMoneyOrDash(lineItem.makingAmount),
              flex: 2, right: true),
          const SizedBox(width: 6),
          _HuidChip(value: lineItem.huidNumber),
          const SizedBox(width: 6),
          _cell(_formatCurrency(lineItem.value), flex: 2, right: true),
          const SizedBox(width: 6),
          _StatusChip(label: lineItem.status),
        ],
      ),
    );
  }

  Widget _cell(
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
        style: SalesPosStyles.bodyStrong,
      ),
    );
  }
}

class _ItemDetailsCell extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;

  const _ItemDetailsCell({required this.lineItem});

  @override
  Widget build(BuildContext context) {
    final isGold = lineItem.metalType.toUpperCase().contains('GOLD');
    final color =
        isGold ? SalesPosColors.brandGold : SalesPosColors.brandSilver;

    return Expanded(
      flex: 5,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(
              isGold ? Icons.diamond_rounded : Icons.auto_awesome_rounded,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lineItem.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong,
                ),
                const SizedBox(height: 3),
                Text(
                  lineItem.metalType.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final grossWeight = lineItems.fold<double>(
      0,
      (total, item) => total + item.grossWeight,
    );
    final making = lineItems.fold<double>(
      0,
      (total, item) => total + item.makingAmount,
    );
    final value = lineItems.fold<double>(
      0,
      (total, item) => total + item.value,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: SalesPosColors.bodyBg,
      child: Row(
        children: [
          _totalCell('TOTAL', flex: 1, center: true),
          const SizedBox(width: 6),
          _totalCell('${lineItems.length} lines', flex: 5),
          const SizedBox(width: 6),
          _totalCell(quantity.toString(), flex: 1, center: true),
          const SizedBox(width: 6),
          _totalCell('${_formatWeight(grossWeight)} g',
              flex: 2, center: true),
          const SizedBox(width: 6),
          _totalCell('${_formatWeight(netWeight)} g', flex: 2, center: true),
          const SizedBox(width: 6),
          _totalCell('-', flex: 2, right: true),
          const SizedBox(width: 6),
          _totalCell(_formatMoneyOrDash(making), flex: 2, right: true),
          const SizedBox(width: 6),
          _totalCell('-', flex: 3, center: true),
          const SizedBox(width: 6),
          _totalCell(_formatCurrency(value), flex: 2, right: true),
          const SizedBox(width: 6),
          _totalCell('READY', flex: 2, center: true),
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

class _MetalBadge extends StatelessWidget {
  final String metalType;

  const _MetalBadge({required this.metalType});

  @override
  Widget build(BuildContext context) {
    final isGold = metalType.toUpperCase().contains('GOLD');
    final color =
        isGold ? SalesPosColors.brandGold : SalesPosColors.brandSilver;

    return Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            metalType.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
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

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SalesPosColors.bodyBorder),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SalesPosColors.bodyTextMain,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        border: Border(
          top: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
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
      ),
    );
  }
}

String _formatWeight(double value) => value.toStringAsFixed(3);

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
