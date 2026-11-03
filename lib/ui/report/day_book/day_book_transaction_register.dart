import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/report/day_book/day_book_source_document_service.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookTransactionRegister extends StatefulWidget {
  const DayBookTransactionRegister({super.key, required this.entries});

  final List<DayBookMoneyEntry> entries;

  @override
  State<DayBookTransactionRegister> createState() =>
      _DayBookTransactionRegisterState();
}

class _DayBookTransactionRegisterState
    extends State<DayBookTransactionRegister> {
  String _query = '';
  String _direction = 'ALL';
  String _mode = 'ALL';

  @override
  Widget build(BuildContext context) {
    final modes = <String>{
      'ALL',
      ...widget.entries.map((entry) => entry.paymentMode.toUpperCase())
    };
    if (!modes.contains(_mode)) _mode = 'ALL';
    final filtered = widget.entries.where((entry) {
      if (_direction == 'IN' && !entry.incoming) return false;
      if (_direction == 'OUT' && entry.incoming) return false;
      if (_mode != 'ALL' && entry.paymentMode.toUpperCase() != _mode) {
        return false;
      }
      final searchable = [
        entry.category,
        entry.paymentMode,
        entry.transactionId,
        entry.referenceId ?? '',
        entry.accountName ?? '',
      ].join(' ').toLowerCase();
      return searchable.contains(_query.toLowerCase().trim());
    }).toList(growable: false);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text('Posted Money Register (${widget.entries.length})',
          style: DayBookStyles.sectionTitle),
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search source, reference, account',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          DropdownButton<String>(
            value: _direction,
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All directions')),
              DropdownMenuItem(value: 'IN', child: Text('Money in')),
              DropdownMenuItem(value: 'OUT', child: Text('Money out')),
            ],
            onChanged: (value) => setState(() => _direction = value ?? 'ALL'),
          ),
          DropdownButton<String>(
            value: _mode,
            items: [
              for (final mode in modes)
                DropdownMenuItem(
                    value: mode,
                    child: Text(mode == 'ALL' ? 'All modes' : mode)),
            ],
            onChanged: (value) => setState(() => _mode = value ?? 'ALL'),
          ),
        ]),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${filtered.length} matching records',
              style: DayBookStyles.label),
        ),
        SizedBox(
          height: 360,
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _TransactionRow(entry: filtered[index]),
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.entry});

  final DayBookMoneyEntry entry;

  Future<void> _viewOriginal(BuildContext context) async {
    try {
      final bytes = await DayBookSourceDocumentService(AppDatabase())
          .readOriginalSalePdf(entry);
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Original issued PDF is not archived.')));
        }
        return;
      }
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open original PDF: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ');
    final documentService = DayBookSourceDocumentService(AppDatabase());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(entry.incoming ? DayBookIcons.cashIn : DayBookIcons.cashOut,
            color: entry.incoming
                ? DayBookColors.positive
                : DayBookColors.negative,
            size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_readable(entry.category),
                  style: DayBookStyles.labelStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                '${DateFormat('HH:mm').format(entry.date)} · ${entry.paymentMode}${entry.accountName == null ? '' : ' · ${entry.accountName}'} · ${entry.referenceId ?? entry.transactionId}',
                style: DayBookStyles.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (documentService.supportsOriginalPdf(entry))
          IconButton(
            tooltip: 'Open original issued PDF',
            onPressed: () => _viewOriginal(context),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          ),
        Flexible(
          child: Text(
            '${entry.incoming ? '+' : '−'}${currency.format(entry.amount)}',
            style: DayBookStyles.labelStrong,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

String _readable(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
