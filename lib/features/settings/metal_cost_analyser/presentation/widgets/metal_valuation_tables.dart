import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class SoldStockValuationTable extends StatelessWidget {
  final List<SoldValuationRow> rows;
  final ValueChanged<SoldValuationRow>? onInvoiceSelected;
  final ValueChanged<SoldValuationRow>? onCustomerSelected;

  const SoldStockValuationTable({
    super.key,
    required this.rows,
    this.onInvoiceSelected,
    this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _TablePanel(
      title: 'Sold Stock Cost Audit',
      subtitle:
          'Every sold line below is linked with stock cost, sale value and margin.',
      icon: Icons.fact_check_rounded,
      emptyMessage: 'No sold stock cost records found.',
      columns: const [
        'S.No',
        'Bill',
        'Date',
        'Customer',
        'Batch',
        'Metal',
        'Item',
        'HUID',
        'Unit',
        'Net Weight',
        'Cost Basis',
        'Sale Value',
        'Profit',
        'Margin %',
      ],
      rows: [
        for (var index = 0; index < rows.length; index++)
          [
            '${index + 1}',
            rows[index].billNo,
            formatDate(rows[index].billDate),
            rows[index].customerLabel,
            rows[index].batchCode,
            titleCase(rows[index].metalType),
            rows[index].itemName,
            rows[index].huidLabel,
            rows[index].unitLabel,
            formatGram(rows[index].netWeight),
            formatMoney(rows[index].costBasis),
            formatMoney(rows[index].saleValue),
            formatMoney(rows[index].profit),
            formatPercent(rows[index].marginPercent),
          ],
      ],
      linkedColumns: {
        if (onInvoiceSelected != null) 1,
        if (onCustomerSelected != null) 3,
      },
      onCellTap: (rowIndex, columnIndex) {
        if (columnIndex == 1) {
          onInvoiceSelected?.call(rows[rowIndex]);
        } else if (columnIndex == 3) {
          onCustomerSelected?.call(rows[rowIndex]);
        }
      },
    );
  }
}

class AvailableStockValuationTable extends StatelessWidget {
  final List<BatchValuationRow> batchRows;
  final List<AvailableValuationRow> rows;
  final ValueChanged<BatchValuationRow>? onBatchSelected;

  const AvailableStockValuationTable({
    super.key,
    required this.batchRows,
    required this.rows,
    this.onBatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BatchValuationSummaryPanel(
          rows: batchRows,
          onBatchSelected: onBatchSelected,
        ),
        const SizedBox(height: 16),
        ItemValuationLedgerTable(rows: rows),
      ],
    );
  }
}

class ItemValuationLedgerTable extends StatelessWidget {
  final List<AvailableValuationRow> rows;

  const ItemValuationLedgerTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _TablePanel(
      title: 'Item Valuation Ledger',
      subtitle: 'Unit-level valuation for exact HUID, item and stock audit.',
      icon: Icons.inventory_rounded,
      emptyMessage: 'No item valuation records found.',
      columns: const [
        'S.No',
        'Item Type',
        'Item',
        'HUID',
        'Unit',
        'Gross Weight',
        'Net Weight',
        'Purity',
        'Wastage',
        'Valuation Purity',
        'Valuation Fine',
        'Rate',
        'Making',
        'Making Type',
        'Valuation Cost',
      ],
      rows: [
        for (var index = 0; index < rows.length; index++)
          [
            '${index + 1}',
            rows[index].itemType,
            rows[index].itemName,
            rows[index].huidLabel,
            rows[index].unitLabel,
            formatGram(rows[index].grossWeight),
            formatGram(rows[index].netWeight),
            formatPercent(rows[index].purityPercent),
            formatPercent(rows[index].wastagePercent),
            formatPercent(rows[index].valuationPurityPercent),
            formatGram(rows[index].valuationFine),
            '${formatMoney(rows[index].ratePerGram)}/g',
            formatMoney(rows[index].makingAmount),
            rows[index].makingChargeType,
            formatMoney(rows[index].unitCost),
          ],
      ],
    );
  }
}

class BatchValuationSummaryPanel extends StatelessWidget {
  final List<BatchValuationRow> rows;
  final ValueChanged<BatchValuationRow>? onBatchSelected;

  const BatchValuationSummaryPanel({
    super.key,
    required this.rows,
    this.onBatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeading(
            title: 'Batch Valuation Summary',
            subtitle:
                'Batch-wise purchase date, supplier, stock weight and valuation cost.',
            icon: Icons.dataset_rounded,
            countLabel: '${rows.length} batches',
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const _PanelEmptyState(message: 'No batch valuation records found.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 820 ? 1 : 2;
                final cardHeight = constraints.maxWidth < 560
                    ? 506.0
                    : constraints.maxWidth < 820
                        ? 374.0
                        : 346.0;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _BatchValuationCard(
                      row: row,
                      onTap: onBatchSelected == null
                          ? null
                          : () => onBatchSelected!(row),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BatchValuationCard extends StatelessWidget {
  final BatchValuationRow row;
  final VoidCallback? onTap;

  const _BatchValuationCard({
    required this.row,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MetalValuationColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MetalValuationMetalImage(
                    metalType: row.metalType,
                    borderColor: MetalValuationColors.line,
                    fallbackColor: MetalValuationColors.goldDark,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.batchCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MetalValuationText.sectionTitle.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDate(row.createdAt)}  |  ${row.supplierName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MetalValuationText.body.copyWith(
                            fontSize: 12,
                            color: MetalValuationColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: MetalValuationColors.goldDark,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final factColumns = constraints.maxWidth < 420
                      ? 2
                      : constraints.maxWidth < 820
                          ? 3
                          : 4;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: factColumns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: factColumns == 2 ? 2.65 : 3.25,
                    children: [
                      _CardFact(
                        label: 'Total Units',
                        value: '${row.totalUnits}',
                      ),
                      _CardFact(
                        label: 'Total Net Weight',
                        value: formatGram(row.totalNetWeight),
                        valueColor: MetalValuationColors.green,
                      ),
                      _CardFact(
                        label: 'Purity',
                        value: formatPercent(row.purityPercent),
                        valueColor: MetalValuationColors.green,
                      ),
                      _CardFact(
                        label: 'Wastage',
                        value: formatPercent(row.wastagePercent),
                        valueColor: MetalValuationColors.blue,
                      ),
                      _CardFact(
                        label: 'Valuation Purity',
                        value: formatPercent(row.valuationPurityPercent),
                        valueColor: MetalValuationColors.goldDark,
                      ),
                      _CardFact(
                        label: 'Total Valuation Fine',
                        value: formatGram(row.valuationFineWeight),
                        valueColor: MetalValuationColors.goldDark,
                      ),
                      _CardFact(
                        label: 'Rate',
                        value: '${formatMoney(row.ratePerGram)}/g',
                        valueColor: MetalValuationColors.goldDark,
                      ),
                      _CardFact(
                        label: 'Making',
                        value: formatMoney(row.makingAmount),
                      ),
                      _CardFact(
                        label: 'Valuation Cost',
                        value: formatMoney(row.totalCost),
                        valueColor: MetalValuationColors.goldDark,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CardFact({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.label.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor ?? MetalValuationColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String emptyMessage;
  final List<String> columns;
  final List<List<String>> rows;
  final Set<int> linkedColumns;
  final void Function(int rowIndex, int columnIndex)? onCellTap;

  const _TablePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyMessage,
    required this.columns,
    required this.rows,
    this.linkedColumns = const {},
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PanelHeading(
              title: title,
              subtitle: subtitle,
              icon: icon,
              countLabel: '${rows.length} rows',
            ),
          ),
          const Divider(height: 1, color: MetalValuationColors.line),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: _PanelEmptyState(message: emptyMessage),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 58,
                      columnSpacing: 26,
                      headingTextStyle: MetalValuationText.label.copyWith(
                        fontSize: 12,
                      ),
                      dataTextStyle: MetalValuationText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      columns: columns
                          .map((column) => DataColumn(label: Text(column)))
                          .toList(),
                      rows: [
                        for (var index = 0; index < rows.length; index++)
                          DataRow(
                            cells: [
                              for (var columnIndex = 0;
                                  columnIndex < rows[index].length;
                                  columnIndex++)
                                DataCell(
                                  _TableCellText(
                                    value: rows[index][columnIndex],
                                    isLink: linkedColumns.contains(columnIndex),
                                  ),
                                  onTap: linkedColumns.contains(columnIndex)
                                      ? () => onCellTap?.call(
                                            index,
                                            columnIndex,
                                          )
                                      : null,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String value;
  final bool isLink;

  const _TableCellText({
    required this.value,
    required this.isLink,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? 'Not recorded' : value;
    final text = Text(
      displayValue,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: isLink
          ? MetalValuationText.body.copyWith(
              color: MetalValuationColors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: MetalValuationColors.blue,
            )
          : null,
    );

    if (!isLink) return text;
    return MouseRegion(cursor: SystemMouseCursors.click, child: text);
  }
}

class _PanelHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String countLabel;

  const _PanelHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MetalValuationColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: MetalValuationColors.goldDark, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MetalValuationText.sectionTitle),
              const SizedBox(height: 3),
              Text(subtitle, style: MetalValuationText.body),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: MetalValuationColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MetalValuationColors.line),
          ),
          child: Text(
            countLabel,
            style: MetalValuationText.label.copyWith(
              color: MetalValuationColors.goldDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final String message;

  const _PanelEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: MetalValuationText.body));
  }
}
