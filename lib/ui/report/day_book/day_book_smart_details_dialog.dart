import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_routes.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../models/reports/day_book/day_book_smart_summary.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_card_presentation.dart';
import 'day_book_document_destination.dart';
import 'day_book_smart_format.dart';

class DayBookSmartDetailsDialog extends StatelessWidget {
  const DayBookSmartDetailsDialog({
    super.key,
    required this.card,
    this.isDemo = false,
  });

  final DayBookSmartCard card;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final display = DayBookCardPresentation.fromCard(card);
    return Dialog(
      backgroundColor: DayBookColors.bodyPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 630),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
            child: Row(children: [
              Icon(display.icon, color: display.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(display.label, style: DayBookStyles.sectionTitle),
                    Text('${display.value} · ${display.caption}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DayBookStyles.label
                            .copyWith(color: DayBookColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          if (isDemo)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('DEMO PREVIEW · Sample records for layout review',
                    style: DayBookStyles.labelStrong.copyWith(
                        color: DayBookColors.warning, fontSize: 11.5)),
              ),
            ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(14),
              itemCount: card.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _DetailGroup(
                  cardType: card.type,
                  group: card.groups[index],
                  isDemo: isDemo),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({
    required this.cardType,
    required this.group,
    required this.isDemo,
  });

  final DayBookCardType cardType;
  final DayBookSmartGroup group;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final isInvoice =
        group.label == 'Regular invoices' || group.label == 'GST invoices';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(group.label,
                style: DayBookStyles.labelStrong
                    .copyWith(color: DayBookColors.textPrimary, fontSize: 14)),
          ),
          Text('${group.count} records',
              style: DayBookStyles.label
                  .copyWith(color: DayBookColors.textSecondary)),
        ]),
        if (group.count == 0) ...[
          const SizedBox(height: 6),
          Text('No activity for this date', style: DayBookStyles.label),
        ] else ...[
          const SizedBox(height: 6),
          Text('References: ${group.numberRange}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.label
                  .copyWith(color: DayBookColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _Metric(label: _valueLabel(), value: group.amount),
            if (isInvoice) ...[
              _Metric(label: 'Collected', value: group.collection),
              _Metric(label: 'New due', value: group.due),
              if (group.label == 'GST invoices')
                _Metric(label: 'GST charged', value: group.tax),
            ],
            if (cardType == DayBookCardType.customerMetalPurchase)
              _Metric(label: 'Paid', value: group.collection),
            if (cardType == DayBookCardType.dues)
              _Metric(label: 'Due', value: group.due),
          ]),
          const Divider(height: 18),
          for (final document in group.documents)
            _DocumentRow(
                document: document,
                showDue: cardType == DayBookCardType.dues,
                isDemo: isDemo),
          for (final entry in group.moneyEntries)
            _ReceiptRow(entry: entry, group: group, isDemo: isDemo),
          for (final expense in group.expenses)
            _DetailRow(
              reference: expense.reference,
              detail: [
                expense.category,
                expense.paymentMode,
                if (expense.partyName?.isNotEmpty == true) expense.partyName!,
                if (expense.description?.isNotEmpty == true)
                  expense.description!,
              ].join(' · '),
              amount: expense.amount,
              onTap: isDemo
                  ? null
                  : () => _open(context, RoutePaths.financeExpense),
            ),
        ],
      ]),
    );
  }

  String _valueLabel() => switch (cardType) {
        DayBookCardType.sales => 'Invoice value',
        DayBookCardType.girviGiven => 'Principal given',
        DayBookCardType.advanceReceived => 'Advance collected',
        DayBookCardType.returnAndCancellation => 'Reversed value',
        DayBookCardType.customerMetalPurchase => 'Purchase value',
        DayBookCardType.dues => 'Invoice value',
        DayBookCardType.receipts => 'Money received',
        DayBookCardType.expenses => 'Expense paid',
      };
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(
      {required this.entry, required this.group, required this.isDemo});

  final DayBookMoneyEntry entry;
  final DayBookSmartGroup group;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final target = isDemo
        ? null
        : dayBookReceiptDestination(
            entry, group.sourceDocuments, group.sourceEvents);
    return _DetailRow(
      reference: entry.referenceId?.split('#').first ?? entry.transactionId,
      detail:
          '${_category(entry.category)} · ${entry.paymentMode}${entry.accountName == null ? '' : ' · ${entry.accountName}'}',
      amount: entry.amount,
      onTap: target == null ? null : () => _open(context, target),
    );
  }

  String _category(String value) => switch (value.toUpperCase()) {
        'SALE' || 'SALE_PAYMENT' => 'Sales collection',
        'DUE_COLLECTION' => 'Old due collection',
        'ADVANCE' || 'ADVANCE_RECEIVED' => 'Customer advance',
        'GIRVI_RETURN' => 'Girvi principal',
        'INTEREST_RECEIVED' => 'Girvi interest',
        _ => value.replaceAll('_', ' '),
      };
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Text(
        '$label ${dayBookSmartMoney(value)}',
        style: DayBookStyles.labelStrong
            .copyWith(color: DayBookColors.textPrimary, fontSize: 11.5),
      );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow(
      {required this.document, required this.showDue, required this.isDemo});

  final DayBookDocument document;
  final bool showDue;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final target = isDemo ? null : dayBookDocumentDestination(document);
    return _DetailRow(
      reference: document.number,
      amount: showDue
          ? (document.outstanding ??
              (document.amount - (document.collection ?? 0)))
          : document.amount,
      detail: switch (document.kind) {
        DayBookDocumentKind.regularInvoice ||
        DayBookDocumentKind.gstInvoice =>
          'Collected ${dayBookSmartMoney(document.collection ?? 0)}',
        DayBookDocumentKind.purchaseVoucher =>
          'Paid ${dayBookSmartMoney(document.collection ?? 0)}',
        DayBookDocumentKind.returnVoucher ||
        DayBookDocumentKind.advanceCancellationVoucher =>
          'Refund pending ${dayBookSmartMoney(document.outstanding ?? 0)}',
        _ => null,
      },
      onTap: target == null ? null : () => _open(context, target),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.reference,
    required this.amount,
    this.detail,
    this.onTap,
  });

  final String reference;
  final double amount;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reference,
                        style: DayBookStyles.labelStrong.copyWith(
                            color: onTap == null
                                ? DayBookColors.textPrimary
                                : DayBookColors.information,
                            decoration: onTap == null
                                ? null
                                : TextDecoration.underline)),
                    if (detail != null)
                      Text(detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DayBookStyles.label.copyWith(
                              fontSize: 11,
                              color: DayBookColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(dayBookSmartMoney(amount),
              style: DayBookStyles.labelStrong
                  .copyWith(color: DayBookColors.textPrimary)),
        ]),
      );
}

void _open(BuildContext context, String target) {
  final router = GoRouter.of(context);
  Navigator.of(context).pop();
  router.push(target);
}
