import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../database/db/app_database.dart';
import '../../../logic/report/day_book/day_book_source_document_service.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_timeline.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_document_destination.dart';
import 'day_book_smart_format.dart';

class DayBookTimelinePanel extends StatefulWidget {
  const DayBookTimelinePanel({super.key, required this.summary});

  final DayBookSummary summary;

  @override
  State<DayBookTimelinePanel> createState() => _DayBookTimelinePanelState();
}

class _DayBookTimelinePanelState extends State<DayBookTimelinePanel> {
  String _query = '';
  DayBookTimelineKind? _kind;
  String? _mode;

  @override
  Widget build(BuildContext context) {
    final records = DayBookTimeline.fromSummary(widget.summary);
    final modes = records
        .map((record) => record.paymentMode)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final filtered = records.where((record) {
      if (_kind != null && record.kind != _kind) return false;
      if (_mode != null && record.paymentMode != _mode) return false;
      final search =
          '${record.reference} ${record.title} ${record.detail}'.toLowerCase();
      return search.contains(_query.trim().toLowerCase());
    }).toList(growable: false);
    return Container(
      decoration: DayBookStyles.panel(),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading:
            const Icon(Icons.history_rounded, color: DayBookColors.goldMetal),
        title: Text('Transaction Timeline', style: DayBookStyles.sectionTitle),
        subtitle: Text('${records.length} source events · chronological',
            style: DayBookStyles.label),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search reference or source',
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            DropdownButton<DayBookTimelineKind?>(
              value: _kind,
              items: [
                const DropdownMenuItem(value: null, child: Text('All events')),
                for (final kind in DayBookTimelineKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: (value) => setState(() => _kind = value),
            ),
            DropdownButton<String?>(
              value: modes.contains(_mode) ? _mode : null,
              items: [
                const DropdownMenuItem(value: null, child: Text('All modes')),
                for (final mode in modes)
                  DropdownMenuItem(value: mode, child: Text(mode)),
              ],
              onChanged: (value) => setState(() => _mode = value),
            ),
          ]),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No matching source events for this day.',
                  style: DayBookStyles.labelStrong),
            )
          else
            SizedBox(
              height: 400,
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => _TimelineRow(
                  record: filtered[index],
                  summary: widget.summary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.record, required this.summary});

  final DayBookTimelineRecord record;
  final DayBookSummary summary;

  String? get _destination {
    if (record.document case final document?) {
      return dayBookDocumentDestination(document);
    }
    if (record.activity case final activity?) {
      return dayBookActivityDestination(activity);
    }
    if (record.money case final money?) {
      return dayBookReceiptDestination(
          money, summary.documents, summary.activityEvents);
    }
    if (record.expense case final expense?) {
      return dayBookExpenseDestination(expense, summary.date);
    }
    if (record.stock case final movement?) {
      if (movement.sourceType.toUpperCase() == 'PURCHASE') {
        final voucherId = int.tryParse(movement.sourceId);
        for (final batch in summary.stockAddedBatches) {
          if (batch.voucherId == voucherId && batch.canOpenInventory) {
            return Uri(path: RoutePaths.stockInventory, queryParameters: {
              'metal': batch.metal,
              'batch': batch.batchCode,
            }).toString();
          }
        }
      }
      for (final document in summary.documents) {
        if (document.sourceId == movement.sourceId &&
            ((movement.sourceType.toUpperCase() == 'SALE' &&
                    {
                      DayBookDocumentKind.regularInvoice,
                      DayBookDocumentKind.gstInvoice
                    }.contains(document.kind)) ||
                (movement.sourceType.toUpperCase() == 'RETURN' &&
                    document.kind == DayBookDocumentKind.returnVoucher))) {
          return dayBookDocumentDestination(document);
        }
      }
    }
    return null;
  }

  Future<void> _openOriginal(BuildContext context) async {
    final entry = record.money;
    if (entry == null) return;
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
    final destination = _destination;
    final money = record.money;
    final hasPdf = money != null &&
        DayBookSourceDocumentService(AppDatabase()).supportsOriginalPdf(money);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: destination == null ? null : () => context.push(destination),
      leading: Icon(_icon(record.kind), color: DayBookColors.goldMetal),
      title: Text('${record.reference} · ${record.title}',
          style: DayBookStyles.labelStrong,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${DateFormat('HH:mm').format(record.at)} · ${record.detail}',
        style: DayBookStyles.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (record.amount case final amount?)
          Text(
            '${money == null ? '' : (money.incoming ? '+' : '−')}'
            '${dayBookSmartMoney(amount)}',
            style: DayBookStyles.labelStrong.copyWith(
              color: money == null
                  ? DayBookColors.textPrimary
                  : money.incoming
                      ? DayBookColors.positive
                      : DayBookColors.negative,
            ),
          ),
        if (hasPdf)
          IconButton(
            tooltip: 'Open original issued PDF',
            onPressed: () => _openOriginal(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        if (destination != null)
          const Icon(Icons.chevron_right_rounded,
              color: DayBookColors.goldMetal),
      ]),
    );
  }
}

IconData _icon(DayBookTimelineKind kind) => switch (kind) {
      DayBookTimelineKind.document => Icons.description_outlined,
      DayBookTimelineKind.payment => Icons.account_balance_wallet_outlined,
      DayBookTimelineKind.metal => Icons.scale_outlined,
      DayBookTimelineKind.activity => Icons.event_note_outlined,
      DayBookTimelineKind.expense => Icons.receipt_long_outlined,
    };
