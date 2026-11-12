import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/reports/day_book/day_book_activity_event.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_document_explorer.dart';
import '../../../models/reports/day_book/day_book_document_item.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_document_destination.dart';
import 'day_book_metal_sales_panel.dart';
import 'day_book_smart_format.dart';

class DayBookDocumentExplorerCard extends StatelessWidget {
  const DayBookDocumentExplorerCard({
    super.key,
    required this.entry,
    required this.summary,
  });

  final DayBookExplorerEntry entry;
  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final target = _destination();
    return Material(
      color: const Color(0xFFFFFEFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: target == null ? null : () => GoRouter.of(context).push(target),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DayBookColors.brandGoldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.description_outlined,
                    size: 15, color: DayBookColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DayBookStyles.labelStrong.copyWith(
                        fontSize: 13,
                        color: DayBookColors.information,
                        decoration: TextDecoration.underline,
                      )),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 19, color: DayBookColors.goldMetal),
              ]),
              const SizedBox(height: 5),
              if (entry.document case final document?)
                _documentBody(document)
              else if (entry.event case final event?) ...[
                _labelValue('Activity', _activityLabel(event.kind)),
                if (event.partyName?.isNotEmpty == true)
                  Text(event.partyName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DayBookStyles.labelStrong.copyWith(
                          color: DayBookColors.information, fontSize: 13)),
                if (event.mobile?.isNotEmpty == true)
                  Text(event.mobile!, style: DayBookStyles.label),
                for (final item in event.items.take(2)) _itemLine(item),
                const Divider(height: 15),
                _labelValue('Amount', dayBookSmartMoney(event.amount)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentBody(DayBookDocument document) {
    final party = document.partyName;
    final mobile = document.mobile;
    final isInvoice = document.kind == DayBookDocumentKind.regularInvoice ||
        document.kind == DayBookDocumentKind.gstInvoice;
    if (isInvoice) return _invoiceBody(document);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (party?.isNotEmpty == true)
        Row(children: [
          const Icon(Icons.person_outline_rounded,
              size: 13, color: DayBookColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(party!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DayBookStyles.labelStrong.copyWith(
                  fontSize: 13,
                  color: DayBookColors.information,
                )),
          ),
        ]),
      if (mobile?.isNotEmpty == true)
        Row(children: [
          const Icon(Icons.phone_outlined,
              size: 12, color: DayBookColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(mobile!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DayBookStyles.label.copyWith(fontSize: 13)),
          ),
        ]),
      if (party == null && mobile == null)
        Text(document.kind.label,
            style: DayBookStyles.label.copyWith(fontSize: 13)),
      if (document.items.isNotEmpty) ...[
        const Divider(height: 14),
        for (final item in document.items.take(2)) _itemLine(item),
        if (document.items.length > 2)
          Text('+${document.items.length - 2} more items',
              style: DayBookStyles.label.copyWith(fontSize: 13)),
      ],
      const Divider(height: 14),
      _labelValue(isInvoice ? 'Invoice Value' : 'Value',
          dayBookSmartMoney(document.amount)),
      if (document.savedPaid != null || document.collection != null)
        _labelValue('Saved Paid',
            dayBookSmartMoney(document.savedPaid ?? document.collection!),
            valueColor: DayBookColors.positive),
      if (document.savedDue != null || document.outstanding != null)
        _labelValue(
          document.kind == DayBookDocumentKind.returnVoucher ||
                  document.kind ==
                      DayBookDocumentKind.advanceCancellationVoucher
              ? 'Refund Due'
              : 'Current Due',
          dayBookSmartMoney(document.savedDue ?? document.outstanding!),
          valueColor: (document.savedDue ?? document.outstanding ?? 0) > 0
              ? DayBookColors.negative
              : DayBookColors.textSecondary,
        ),
      if (document.tax != null && document.tax! > 0)
        _labelValue('GST', dayBookSmartMoney(document.tax!)),
    ]);
  }

  Widget _invoiceBody(DayBookDocument document) {
    final item = document.items.isEmpty ? null : document.items.first;
    final paid = document.savedPaid ?? document.collection;
    final due = document.savedDue ?? document.outstanding;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _personLine(
          Icons.person_outline_rounded,
          document.partyName?.isNotEmpty == true
              ? document.partyName!
              : 'Customer unavailable',
          linkStyle: true),
      _personLine(Icons.phone_outlined,
          document.mobile?.isNotEmpty == true ? document.mobile! : '—'),
      const SizedBox(height: 5),
      const Divider(height: 1, color: DayBookColors.bodyBorder),
      const SizedBox(height: 5),
      _invoiceFact('Metal', item == null ? '—' : _metalName(item.metal)),
      _invoiceFact('Item', item?.name ?? '—'),
      _invoiceFact('Weight',
          item == null ? '—' : dayBookMetalWeight(item.netWeightGrams)),
      if (document.items.length > 1)
        Text('+${document.items.length - 1} more items',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DayBookStyles.label.copyWith(fontSize: 13)),
      const SizedBox(height: 5),
      const Divider(height: 1, color: DayBookColors.bodyBorder),
      const SizedBox(height: 5),
      Row(children: [
        Expanded(
            child: _amountCell('Total', dayBookSmartMoney(document.amount),
                DayBookColors.textPrimary)),
        Expanded(
            child: _amountCell(
                'Paid',
                paid == null ? '—' : dayBookSmartMoney(paid),
                DayBookColors.positive)),
        Expanded(
            child: _amountCell(
                'Due',
                due == null ? '—' : dayBookSmartMoney(due),
                (due ?? 0) > 0
                    ? DayBookColors.negative
                    : DayBookColors.textSecondary)),
      ]),
      if (document.kind == DayBookDocumentKind.gstInvoice &&
          document.tax != null) ...[
        const SizedBox(height: 4),
        Text('GST ${dayBookSmartMoney(document.tax!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DayBookStyles.label.copyWith(fontSize: 13)),
      ],
      if (!document.issueSnapshotAvailable) ...[
        const SizedBox(height: 5),
        Text('Original issue values unverified',
            style: DayBookStyles.labelStrong
                .copyWith(fontSize: 13, color: DayBookColors.negative)),
      ],
    ]);
  }

  Widget _personLine(IconData icon, String value, {bool linkStyle = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(icon, size: 13, color: DayBookColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(
                      fontSize: 13,
                      color: linkStyle
                          ? DayBookColors.information
                          : DayBookColors.textPrimary,
                      decoration:
                          linkStyle ? TextDecoration.underline : null))),
        ]),
      );

  Widget _invoiceFact(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: Row(children: [
          SizedBox(
              width: 58,
              child: Text(label,
                  style: DayBookStyles.label.copyWith(fontSize: 13))),
          Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
        ]),
      );

  Widget _amountCell(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DayBookStyles.label.copyWith(fontSize: 13)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.labelStrong.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      );

  String _metalName(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return '—';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  Widget _itemLine(DayBookDocumentItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Expanded(
            child: Text('${item.metal} · ${item.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DayBookStyles.label.copyWith(fontSize: 13)),
          ),
          const SizedBox(width: 5),
          Text(dayBookMetalWeight(item.netWeightGrams),
              style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        ]),
      );

  Widget _labelValue(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DayBookStyles.label.copyWith(fontSize: 13)),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: DayBookStyles.labelStrong
                    .copyWith(fontSize: 13, color: valueColor)),
          ),
        ]),
      );

  String? _destination() {
    if (entry.document case final document?) {
      return dayBookDocumentDestination(document);
    }
    if (entry.event case final event?) {
      return dayBookActivityDestination(event);
    }
    return null;
  }

  String _activityLabel(DayBookActivityKind kind) => switch (kind) {
        DayBookActivityKind.girviRelease => 'Girvi Release',
        DayBookActivityKind.girviInterest => 'Girvi Interest',
        DayBookActivityKind.girviMelted => 'Girvi Melted',
        DayBookActivityKind.dueCollection => 'Due Collection',
      };
}
