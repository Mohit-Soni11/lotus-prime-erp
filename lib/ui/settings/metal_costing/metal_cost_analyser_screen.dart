import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/database/db/app_database.dart';

class MetalCostAnalyserScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MetalCostAnalyserScreen({super.key, this.onBack});

  @override
  State<MetalCostAnalyserScreen> createState() =>
      _MetalCostAnalyserScreenState();
}

class _MetalCostAnalyserScreenState extends State<MetalCostAnalyserScreen> {
  late Future<_MetalCostAnalyserData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_MetalCostAnalyserData> _loadData() async {
    final db = AppDatabase();
    final available = await db.customSelect('''
      SELECT
        COUNT(*) AS units,
        COALESCE(SUM(unit_cost), 0) AS cost,
        COALESCE(SUM(actual_fine_weight), 0) AS actual_fine,
        COALESCE(SUM(valuation_fine_weight), 0) AS valuation_fine
      FROM stock_item_units
      WHERE status = 'Available'
    ''').getSingle();

    final sold = await db.customSelect('''
      SELECT
        COUNT(*) AS units,
        COALESCE(SUM(stock_unit_cost), 0) AS cost,
        COALESCE(SUM(item_total), 0) AS sales,
        COALESCE(SUM(stock_profit_amount), 0) AS profit
      FROM bill_items
      WHERE stock_unit_cost > 0
    ''').getSingle();

    final recentSoldRows = await db.customSelect('''
      SELECT
        b.bill_no AS bill_no,
        b.bill_date AS bill_date,
        i.item_name AS item_name,
        i.huid AS huid,
        i.linked_stock_sku AS unit_code,
        i.stock_unit_cost AS cost,
        i.item_total AS sale,
        i.stock_profit_amount AS profit
      FROM bill_items i
      INNER JOIN bills b ON b.id = i.bill_id
      WHERE i.stock_unit_cost > 0
      ORDER BY b.bill_date DESC, i.id DESC
      LIMIT 80
    ''').get();

    final availableRows = await db.customSelect('''
      SELECT
        batch_code,
        item_name,
        huid,
        unit_code,
        net_weight,
        actual_fine_weight,
        valuation_fine_weight,
        unit_cost
      FROM stock_item_units
      WHERE status = 'Available'
      ORDER BY created_at DESC, id DESC
      LIMIT 80
    ''').get();

    return _MetalCostAnalyserData(
      availableUnits: available.read<int>('units'),
      availableCost: available.read<double>('cost'),
      availableActualFine: available.read<double>('actual_fine'),
      availableValuationFine: available.read<double>('valuation_fine'),
      soldUnits: sold.read<int>('units'),
      soldCost: sold.read<double>('cost'),
      soldValue: sold.read<double>('sales'),
      soldProfit: sold.read<double>('profit'),
      recentSold: recentSoldRows.map(_SoldCostRow.fromRow).toList(),
      availableStock: availableRows.map(_AvailableCostRow.fromRow).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Metal Cost Analyser'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _loadData()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<_MetalCostAnalyserData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(data: data),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Available Stock Cost',
                  subtitle:
                      'Current stock cost based on valuation fine, rate and making.',
                  child: _AvailableTable(rows: data.availableStock),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Sold Stock Profit Audit',
                  subtitle:
                      'Sold stock cost, sale value and profit from linked stock units.',
                  child: _SoldTable(rows: data.recentSold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _MetalCostAnalyserData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _Metric('Available Units', data.availableUnits.toString(),
            Icons.inventory_2_rounded),
        _Metric('Stock Cost', _money(data.availableCost),
            Icons.account_balance_wallet_rounded),
        _Metric(
            'Actual Fine',
            '${data.availableActualFine.toStringAsFixed(3)} g',
            Icons.scale_rounded),
        _Metric(
            'Valuation Fine',
            '${data.availableValuationFine.toStringAsFixed(3)} g',
            Icons.trending_up_rounded),
        _Metric(
            'Sold Value', _money(data.soldValue), Icons.point_of_sale_rounded),
        _Metric('Profit', _money(data.soldProfit), Icons.insights_rounded,
            accent: data.soldProfit >= 0
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _Metric(
    this.label,
    this.value,
    this.icon, {
    this.accent = const Color(0xFFB8860B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _mutedStyle()),
                const SizedBox(height: 4),
                Text(value, style: _valueStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle()),
                const SizedBox(height: 4),
                Text(subtitle, style: _mutedStyle()),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _AvailableTable extends StatelessWidget {
  final List<_AvailableCostRow> rows;

  const _AvailableTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState('No available stock valuation yet.');
    }
    return _TableShell(
      columns: const [
        'Batch',
        'Item',
        'HUID/Unit',
        'Net WT',
        'Actual Fine',
        'Valuation Fine',
        'Cost'
      ],
      rows: rows
          .map(
            (row) => [
              row.batchCode,
              row.itemName,
              row.huid.isEmpty ? row.unitCode : row.huid,
              '${row.netWeight.toStringAsFixed(3)} g',
              '${row.actualFine.toStringAsFixed(3)} g',
              '${row.valuationFine.toStringAsFixed(3)} g',
              _money(row.cost),
            ],
          )
          .toList(),
    );
  }
}

class _SoldTable extends StatelessWidget {
  final List<_SoldCostRow> rows;

  const _SoldTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState('No linked stock sale yet.');
    }
    return _TableShell(
      columns: const ['Bill', 'Item', 'HUID/Unit', 'Cost', 'Sale', 'Profit'],
      rows: rows
          .map(
            (row) => [
              row.billNo,
              row.itemName,
              row.huid.isEmpty ? row.unitCode : row.huid,
              _money(row.cost),
              _money(row.sale),
              _money(row.profit),
            ],
          )
          .toList(),
    );
  }
}

class _TableShell extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const _TableShell({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111827),
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
        columns:
            columns.map((value) => DataColumn(label: Text(value))).toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row.map((value) => DataCell(Text(value))).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Center(child: Text(message, style: _mutedStyle())),
    );
  }
}

class _MetalCostAnalyserData {
  final int availableUnits;
  final double availableCost;
  final double availableActualFine;
  final double availableValuationFine;
  final int soldUnits;
  final double soldCost;
  final double soldValue;
  final double soldProfit;
  final List<_SoldCostRow> recentSold;
  final List<_AvailableCostRow> availableStock;

  const _MetalCostAnalyserData({
    required this.availableUnits,
    required this.availableCost,
    required this.availableActualFine,
    required this.availableValuationFine,
    required this.soldUnits,
    required this.soldCost,
    required this.soldValue,
    required this.soldProfit,
    required this.recentSold,
    required this.availableStock,
  });
}

class _AvailableCostRow {
  final String batchCode;
  final String itemName;
  final String huid;
  final String unitCode;
  final double netWeight;
  final double actualFine;
  final double valuationFine;
  final double cost;

  const _AvailableCostRow({
    required this.batchCode,
    required this.itemName,
    required this.huid,
    required this.unitCode,
    required this.netWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.cost,
  });

  factory _AvailableCostRow.fromRow(QueryRow row) {
    return _AvailableCostRow(
      batchCode: row.readNullable<String>('batch_code') ?? '',
      itemName: row.read<String>('item_name'),
      huid: row.readNullable<String>('huid') ?? '',
      unitCode: row.read<String>('unit_code'),
      netWeight: row.read<double>('net_weight'),
      actualFine: row.read<double>('actual_fine_weight'),
      valuationFine: row.read<double>('valuation_fine_weight'),
      cost: row.read<double>('unit_cost'),
    );
  }
}

class _SoldCostRow {
  final String billNo;
  final String itemName;
  final String huid;
  final String unitCode;
  final double cost;
  final double sale;
  final double profit;

  const _SoldCostRow({
    required this.billNo,
    required this.itemName,
    required this.huid,
    required this.unitCode,
    required this.cost,
    required this.sale,
    required this.profit,
  });

  factory _SoldCostRow.fromRow(QueryRow row) {
    return _SoldCostRow(
      billNo: row.read<String>('bill_no'),
      itemName: row.read<String>('item_name'),
      huid: row.readNullable<String>('huid') ?? '',
      unitCode: row.readNullable<String>('unit_code') ?? '',
      cost: row.read<double>('cost'),
      sale: row.read<double>('sale'),
      profit: row.read<double>('profit'),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE7DCC8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

TextStyle _titleStyle() {
  return GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: const Color(0xFF111827),
  );
}

TextStyle _valueStyle() {
  return GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: const Color(0xFF111827),
  );
}

TextStyle _mutedStyle() {
  return GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF64748B),
  );
}

String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';
