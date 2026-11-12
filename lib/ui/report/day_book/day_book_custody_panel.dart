import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_custody_position.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookCustodyPanel extends StatelessWidget {
  const DayBookCustodyPanel({super.key, required this.position});

  final DayBookCustodyPosition position;

  @override
  Widget build(BuildContext context) => Container(
        decoration: DayBookStyles.panel(),
        child: ExpansionTile(
          initiallyExpanded: true,
          title:
              Text('Girvi Customer Custody', style: DayBookStyles.sectionTitle),
          subtitle: Text(
            'Customer property is separate from owned stock. Release is recorded when the item leaves the shop.',
            style: DayBookStyles.sectionSubtitle,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (!position.closingVerified)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Custody record incomplete: a closed Girvi ticket has no recorded item handover date.',
                  style: DayBookStyles.labelStrong.copyWith(
                    color: DayBookColors.warning,
                  ),
                ),
              ),
            _CustodySection(label: 'Opening', lines: position.opening),
            _CustodySection(label: 'Received', lines: position.received),
            _CustodySection(
                label: 'Released / Recovered', lines: position.released),
            _CustodySection(
              label: position.closingVerified
                  ? 'Closing (recorded custody)'
                  : 'Closing (handover date missing)',
              lines: position.closing,
            ),
          ],
        ),
      );
}

class _CustodySection extends StatelessWidget {
  const _CustodySection({required this.label, required this.lines});

  final String label;
  final List<DayBookCustodyLine> lines;

  @override
  Widget build(BuildContext context) {
    final pieces = lines.fold<int>(0, (sum, line) => sum + line.pieces);
    final gross = lines.fold<double>(0, (sum, line) => sum + line.grossWeight);
    final net = lines.fold<double>(0, (sum, line) => sum + line.netWeight);
    final fineVerified = lines.every((line) => line.fineWeight != null);
    final fine =
        lines.fold<double>(0, (sum, line) => sum + (line.fineWeight ?? 0));
    final number =
        NumberFormat.decimalPatternDigits(locale: 'en_IN', decimalDigits: 3);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('$label · $pieces pieces', style: DayBookStyles.labelStrong),
      subtitle: Text(
        '${number.format(gross)} g gross · ${number.format(net)} g net · ${fineVerified ? '${number.format(fine)} g fine' : 'fine weight unverified'}',
        style: DayBookStyles.label,
      ),
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${line.ticketNo} · ${line.metal} ${line.purity} · ${line.itemName}${line.isLegacy ? ' · legacy' : ''}',
                  style: DayBookStyles.label,
                ),
              ),
              const SizedBox(width: 8),
              Text('${line.pieces} pcs · ${number.format(line.netWeight)} g',
                  style: DayBookStyles.labelStrong),
            ]),
          ),
        if (lines.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('No items', style: DayBookStyles.label),
          ),
      ],
    );
  }
}
