import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lotus_erp/logic/purchase/metal_inward/metal_inward_ledger_controller.dart';
import 'package:lotus_erp/models/purchase/metal_inward/metal_inward_entry.dart';

class MetalInwardLedgerScreen extends StatelessWidget {
  const MetalInwardLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MetalInwardLedgerController(),
      child: const _MetalInwardLedgerView(),
    );
  }
}

class _MetalInwardLedgerView extends StatelessWidget {
  const _MetalInwardLedgerView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MetalInwardLedgerController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Metal Inward Ledger'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: ctrl.startDate != null && ctrl.endDate != null
                    ? DateTimeRange(start: ctrl.startDate!, end: ctrl.endDate!)
                    : null,
              );
              if (picked != null) {
                ctrl.setDateRange(picked.start, picked.end);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(ctrl),
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.error != null
                    ? Center(child: Text('Error: ${ctrl.error}', style: const TextStyle(color: Colors.red)))
                    : _buildDataTable(ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(MetalInwardLedgerController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryCard(
            title: 'Total Gold (Gross)',
            value: '${ctrl.totalGoldGrossWeight.toStringAsFixed(3)} g',
            color: Colors.amber.shade100,
          ),
          _SummaryCard(
            title: 'Total Gold (Fine)',
            value: '${ctrl.totalGoldFineWeight.toStringAsFixed(3)} g',
            color: Colors.amber.shade200,
          ),
          _SummaryCard(
            title: 'Total Silver (Gross)',
            value: '${ctrl.totalSilverGrossWeight.toStringAsFixed(3)} g',
            color: Colors.grey.shade200,
          ),
          _SummaryCard(
            title: 'Total Silver (Fine)',
            value: '${ctrl.totalSilverFineWeight.toStringAsFixed(3)} g',
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(MetalInwardLedgerController ctrl) {
    if (ctrl.entries.isEmpty) {
      return const Center(child: Text('No metal inward entries found in this period.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Source')),
            DataColumn(label: Text('Reference No')),
            DataColumn(label: Text('Customer Name')),
            DataColumn(label: Text('Metal')),
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Gross Wt', textAlign: TextAlign.right)),
            DataColumn(label: Text('Fine Wt', textAlign: TextAlign.right)),
            DataColumn(label: Text('Amount (₹)', textAlign: TextAlign.right)),
          ],
          rows: ctrl.entries.map((e) => _buildRow(e)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(MetalInwardEntry e) {
    final df = DateFormat('dd MMM yyyy');
    return DataRow(
      cells: [
        DataCell(Text(df.format(e.date))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: e.source.contains('Trade-In') ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(e.source, style: TextStyle(
            color: e.source.contains('Trade-In') ? Colors.blue.shade700 : Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          )),
        )),
        DataCell(Text(e.referenceNo)),
        DataCell(Text(e.customerName)),
        DataCell(Text(e.metalType)),
        DataCell(Text(e.itemDescription)),
        DataCell(Text('${e.grossWeight.toStringAsFixed(3)} g')),
        DataCell(Text('${e.fineWeight.toStringAsFixed(3)} g')),
        DataCell(Text('₹ ${e.amount.toStringAsFixed(2)}')),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
