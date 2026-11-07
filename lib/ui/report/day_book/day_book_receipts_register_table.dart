import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_expense_record.dart';
import '../../../models/reports/day_book/day_book_receipts_register.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_document_destination.dart';
import 'day_book_smart_format.dart';

class DayBookReceiptsRegisterTable extends StatelessWidget {
  const DayBookReceiptsRegisterTable({
    super.key,
    required this.register,
    required this.summary,
    required this.tab,
    required this.isDemo,
    required this.visibleCount,
  });

  final DayBookReceiptsRegister register;
  final DayBookSummary summary;
  final DayBookRegisterTab tab;
  final bool isDemo;
  final int visibleCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 1160.0;
          final table = SizedBox(
            width: constraints.maxWidth >= minWidth
                ? constraints.maxWidth
                : minWidth,
            child: Column(children: [
              _header(),
              ...switch (tab) {
                DayBookRegisterTab.due => register.dues
                    .take(visibleCount)
                    .map((row) => _dueRow(context, row)),
                DayBookRegisterTab.received => register.received
                    .take(visibleCount)
                    .map((row) => _receivedRow(context, row)),
                DayBookRegisterTab.expense => register.expenses
                    .take(visibleCount)
                    .map((row) => _expenseRow(context, row)),
              },
            ]),
          );
          return constraints.maxWidth >= minWidth
              ? table
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: table,
                );
        },
      );

  Widget _header() => _cells(
        switch (tab) {
          DayBookRegisterTab.due => const [
              _Cell('Invoice No.'),
              _Cell('Customer Name'),
              _Cell('Phone'),
              _Cell('Type'),
              _Cell('Total Value'),
              _Cell('Amount Paid'),
              _Cell('Due Amount'),
              _Cell(''),
            ],
          DayBookRegisterTab.received => const [
              _Cell('Source No.'),
              _Cell('Customer Name'),
              _Cell('Phone'),
              _Cell('Type'),
              _Cell('Total Value'),
              _Cell('Received'),
              _Cell('Mode'),
              _Cell(''),
            ],
          DayBookRegisterTab.expense => const [
              _Cell('Entry No.'),
              _Cell('Party'),
              _Cell('Description'),
              _Cell('Category'),
              _Cell('Amount'),
              _Cell('Payment Mode'),
              _Cell(''),
            ],
        },
        header: true,
        expense: tab == DayBookRegisterTab.expense,
      );

  Widget _dueRow(BuildContext context, DayBookDueRow row) {
    final due = row.dueAmount;
    final target = isDemo
        ? null
        : row.document != null
            ? dayBookDocumentDestination(row.document!)
            : row.event != null
                ? dayBookActivityDestination(row.event!)
                : null;
    return _clickable(
        context,
        target,
        _cells([
          _Cell(row.reference, color: DayBookColors.textPrimary, bold: true),
          _Cell(row.customerName ?? '—'),
          _Cell(row.phone ?? '—'),
          _Cell(row.type, badge: true),
          _Cell(_money(row.totalValue), bold: true),
          _Cell(_money(row.amountPaid),
              bold: true, color: DayBookColors.positive),
          _Cell(_money(due),
              bold: true,
              color: due != null && due > 0
                  ? DayBookColors.negative
                  : DayBookColors.textPrimary),
          const _Cell('›', color: DayBookColors.goldMetal),
        ]));
  }

  Widget _receivedRow(BuildContext context, DayBookReceivedRow row) {
    final target = isDemo || row.entry == null
        ? null
        : dayBookReceiptDestination(
            row.entry!, summary.documents, summary.activityEvents);
    return _clickable(
        context,
        target,
        _cells([
          _Cell(row.reference, bold: true),
          _Cell(row.customerName ?? '—'),
          _Cell(row.phone ?? '—'),
          _Cell(row.type, badge: true),
          _Cell(_money(row.totalValue)),
          _Cell(dayBookSmartMoney(row.amount),
              bold: true, color: DayBookColors.positive),
          _Cell(row.mode),
          const _Cell('›', color: DayBookColors.goldMetal),
        ]));
  }

  Widget _expenseRow(BuildContext context, DayBookExpenseRecord row) {
    final target = isDemo ? null : dayBookExpenseDestination(row, summary.date);
    return _clickable(
        context,
        target,
        _cells([
          _Cell(row.reference, bold: true),
          _Cell(row.partyName ?? '—'),
          _Cell(row.description ?? '—'),
          _Cell(row.category, badge: true),
          _Cell(dayBookSmartMoney(row.amount),
              bold: true, color: DayBookColors.negative),
          _Cell(row.paymentMode),
          const _Cell('›', color: DayBookColors.goldMetal),
        ], expense: true));
  }

  Widget _clickable(BuildContext context, String? target, Widget child) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              target == null ? null : () => GoRouter.of(context).push(target),
          hoverColor: DayBookColors.cardHover,
          child: child,
        ),
      );

  Widget _cells(List<_Cell> cells,
      {bool header = false, bool expense = false}) {
    final flexes = expense
        ? const [14, 14, 21, 15, 13, 14, 3]
        : const [14, 16, 14, 10, 14, 14, 13, 3];
    return Container(
      height: header ? 43 : 46,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DayBookColors.bodyBorder)),
      ),
      child: Row(children: [
        for (var index = 0; index < cells.length; index++)
          Expanded(
            flex: flexes[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _cell(cells[index],
                  header: header, numeric: _isAmountColumn(index)),
            ),
          ),
      ]),
    );
  }

  bool _isAmountColumn(int index) => switch (tab) {
        DayBookRegisterTab.due => index >= 4 && index <= 6,
        DayBookRegisterTab.received => index == 4 || index == 5,
        DayBookRegisterTab.expense => index == 4,
      };

  Widget _cell(_Cell cell, {required bool header, required bool numeric}) {
    final style = DayBookStyles.labelStrong.copyWith(
      fontSize: 13,
      fontWeight: header || cell.bold ? FontWeight.w800 : FontWeight.w600,
      color: cell.color ?? DayBookColors.textPrimary,
    );
    if (cell.badge && !header) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: DayBookColors.brandGoldSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(cell.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(color: DayBookColors.warning)),
        ),
      );
    }
    return Align(
      alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(cell.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: numeric ? TextAlign.right : TextAlign.left,
          style: style),
    );
  }

  String _money(double? value) =>
      value == null ? '—' : dayBookSmartMoney(value);
}

class _Cell {
  const _Cell(
    this.text, {
    this.bold = false,
    this.badge = false,
    this.color,
  });
  final String text;
  final bool bold;
  final bool badge;
  final Color? color;
}
