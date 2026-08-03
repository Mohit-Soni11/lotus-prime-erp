import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class SoldStockValuationTable extends StatelessWidget {
  final List<SoldValuationRow> rows;

  const SoldStockValuationTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _TablePanel(
      title: 'Sold Stock Cost Audit',
      subtitle:
          'Every sold line below is linked with stock cost, sale value and margin.',
      icon: Icons.fact_check_rounded,
      emptyMessage: 'No sold stock cost records found.',
      columns: const [
        'Bill',
        'Date',
        'Metal',
        'Item',
        'HUID / Unit',
        'Net Weight',
        'Cost Basis',
        'Sale Value',
        'Margin',
      ],
      rows: rows
          .map(
            (row) => [
              row.billNo,
              formatDate(row.billDate),
              titleCase(row.metalType),
              row.itemName,
              row.identifier,
              formatGram(row.netWeight),
              formatMoney(row.costBasis),
              formatMoney(row.saleValue),
              '${formatMoney(row.profit)} (${formatPercent(row.marginPercent)})',
            ],
          )
          .toList(),
    );
  }
}

class AvailableStockValuationTable extends StatelessWidget {
  final List<AvailableValuationRow> rows;

  const AvailableStockValuationTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _TablePanel(
      title: 'Available Stock Valuation',
      subtitle:
          'Live inventory cost is read directly from available stock units.',
      icon: Icons.inventory_rounded,
      emptyMessage: 'No available stock valuation records found.',
      columns: const [
        'Metal',
        'Batch',
        'Item Type',
        'Item',
        'Company',
        'HUID / Unit',
        'Gross Weight',
        'Net Weight',
        'Actual Fine',
        'Valuation Fine',
        'Unit Cost',
      ],
      rows: rows
          .map(
            (row) => [
              titleCase(row.metalType),
              row.batchCode,
              row.itemType,
              row.itemName,
              row.companyName.isEmpty ? 'Unbranded' : row.companyName,
              row.identifier,
              formatGram(row.grossWeight),
              formatGram(row.netWeight),
              formatGram(row.actualFine),
              formatGram(row.valuationFine),
              formatMoney(row.unitCost),
            ],
          )
          .toList(),
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

  const _TablePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyMessage,
    required this.columns,
    required this.rows,
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
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MetalValuationColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: MetalValuationColors.goldDark,
                    size: 21,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: MetalValuationColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MetalValuationColors.line),
                  ),
                  child: Text(
                    '${rows.length} rows',
                    style: MetalValuationText.label.copyWith(
                      color: MetalValuationColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MetalValuationColors.line),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(emptyMessage, style: MetalValuationText.body),
              ),
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
                      rows: rows
                          .map(
                            (row) => DataRow(
                              cells: row
                                  .map(
                                    (value) => DataCell(
                                      Text(
                                        value.isEmpty ? 'Not recorded' : value,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                          .toList(),
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
