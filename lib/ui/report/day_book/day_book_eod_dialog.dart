import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/finance/expense/expense_draft.dart';
import '../../../models/reports/day_book/day_book_closing_mismatch.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_eod_sections.dart';
import 'day_book_form_visuals.dart';
import 'day_book_metal_count_dialog.dart';

class DayBookEodDialog extends StatefulWidget {
  const DayBookEodDialog({super.key, required this.ctrl});
  final DayBookController ctrl;

  @override
  State<DayBookEodDialog> createState() => _DayBookEodDialogState();
}

class _DayBookEodDialogState extends State<DayBookEodDialog> {
  final _bank = TextEditingController();
  bool _cashCountEntered = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _cashCountEntered = widget.ctrl.physicalCashAmount > 0;
    _bank.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _bank.removeListener(_refresh);
    _bank.dispose();
    super.dispose();
  }

  double? get _actualBank {
    final text = _bank.text.trim().replaceAll(',', '');
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    return value != null && value.isFinite ? value : null;
  }

  void _reset() {
    widget.ctrl.resetDenomination();
    _bank.clear();
    setState(() => _cashCountEntered = false);
  }

  void _openExpenseDraft(ExpenseDraft draft) {
    Navigator.of(context).pop(draft);
  }

  Future<void> _openMetalCount() async {
    await showDialog<bool>(
      context: context,
      barrierColor: DayBookColors.overlay,
      builder: (_) => DayBookMetalCountDialog(controller: widget.ctrl),
    );
  }

  Future<void> _closeDay() async {
    final actualBank = _actualBank;
    if (actualBank == null || _closing) return;
    setState(() => _closing = true);
    final closed = await widget.ctrl.closeDay(physicalBank: actualBank);
    if (!mounted) return;
    setState(() => _closing = false);
    if (closed) {
      Navigator.of(context).pop();
      AppFeedback.success(context, message: DayBookStrings.closeSuccess);
    } else {
      AppFeedback.warning(context,
          message:
              widget.ctrl.closeError ?? 'Refresh and recount before closing.');
    }
  }

  @override
  Widget build(BuildContext context) => DayBookFormVisuals.themed(
        child: Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: const Color(0xFFFFFEFC),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DayBookColors.brandGoldBorder),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 690,
              maxHeight: MediaQuery.sizeOf(context).height - 36,
            ),
            child: ListenableBuilder(
              listenable: widget.ctrl,
              builder: (context, _) {
                final flow = widget.ctrl.summary?.moneyFlow;
                final actualBank = _actualBank;
                final countedCash = _cashCountEntered ||
                        (flow != null && flow.closingCash.abs() < 0.01)
                    ? widget.ctrl.physicalCashAmount
                    : null;
                final mismatch = flow == null
                    ? null
                    : DayBookClosingMismatch(
                        expectedCash: flow.closingCash,
                        countedCash: countedCash,
                        expectedBank: flow.closingBank,
                        countedBank: actualBank,
                      );
                final expenseDrafts =
                    mismatch?.expenseDrafts(widget.ctrl.selectedDate) ??
                        const <ExpenseDraft>[];
                final cashMatched =
                    countedCash != null && widget.ctrl.isCashMatched;
                final bankMatched = flow != null &&
                    actualBank != null &&
                    (actualBank - flow.closingBank).abs() < 0.01;
                final expenseTotal = widget.ctrl.summary?.expenseRecords
                        .fold<double>(0, (total, row) => total + row.amount) ??
                    0.0;
                final prerequisites = widget.ctrl.balanceVerification != null &&
                    widget.ctrl.isMetalPositionVerified &&
                    widget.ctrl.isCustodyPositionVerified;
                final ready = cashMatched && bankMatched && prerequisites;
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  _header(context),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (flow == null)
                            const EodNotice(
                                text:
                                    'Day Book balances are unavailable. Refresh before reconciling.')
                          else ...[
                            EodSystemClosing(
                              date: widget.ctrl.selectedDate,
                              flow: flow,
                              expenseTotal: expenseTotal,
                            ),
                            const SizedBox(height: 10),
                            EodCashCount(
                              ctrl: widget.ctrl,
                              onCountChanged: () =>
                                  setState(() => _cashCountEntered = true),
                            ),
                            const SizedBox(height: 10),
                            EodBankCount(
                                controller: _bank, expected: flow.closingBank),
                            const SizedBox(height: 10),
                            EodVerificationSummary(
                              expectedCash: flow.closingCash,
                              countedCash: countedCash,
                              expectedBank: flow.closingBank,
                              countedBank: actualBank,
                              expenseTotal: expenseTotal,
                            ),
                            if (mismatch != null &&
                                countedCash != null &&
                                actualBank != null &&
                                (!cashMatched || !bankMatched)) ...[
                              const SizedBox(height: 10),
                              EodNotice(
                                  text: mismatch.hasOppositeMovements
                                      ? 'Cash and bank differ in opposite directions. Record the transfer or correct the payment mode before closing.'
                                      : expenseDrafts.isNotEmpty
                                          ? 'Record the shortage in Expense Entry, then return to recount and close the day.'
                                          : 'Review any excess or missing receipt before closing the day.'),
                            ],
                            if (!prerequisites) ...[
                              const SizedBox(height: 10),
                              EodNotice(
                                  text: [
                                if (widget.ctrl.balanceVerification == null)
                                  'Verify today’s opening cash and bank.',
                                if (!widget.ctrl.isMetalPositionVerified)
                                  'Owned metal stock is unverified.',
                                if (!widget.ctrl.isCustodyPositionVerified)
                                  'Girvi custody handover dates are incomplete.',
                              ].join(' ')),
                            ],
                            if (!widget.ctrl.isMetalPositionVerified) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _openMetalCount,
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text('Count Owned Metal Stock'),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  _footer(context, ready, expenseDrafts),
                ]);
              },
            ),
          ),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 17, 13, 14),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DayBookColors.brandGoldBorder),
            ),
            child: const Icon(Icons.fact_check_outlined,
                color: DayBookColors.goldMetal, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Closing Reconciliation',
                  style: DayBookStyles.pageTitle
                      .copyWith(fontSize: 22, color: DayBookColors.goldMetal)),
              const SizedBox(height: 2),
              Text(
                'Count cash and verify bank before locking ${DateFormat('d MMM yyyy').format(widget.ctrl.selectedDate)}.',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13),
              ),
            ],
          )),
          IconButton(
            tooltip: 'Close',
            onPressed: _closing ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: DayBookColors.bodySubtle,
              side: const BorderSide(color: DayBookColors.bodyBorder),
            ),
          ),
        ]),
      );

  Widget _footer(
          BuildContext context, bool ready, List<ExpenseDraft> expenseDrafts) =>
      Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DayBookColors.bodyBorder)),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 9,
          runSpacing: 8,
          children: [
            for (final draft in expenseDrafts)
              OutlinedButton.icon(
                onPressed: _closing ? null : () => _openExpenseDraft(draft),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(draft.paymentMode.dbValue == 'CASH'
                    ? 'Cash Shortage → Expense'
                    : 'Bank Shortage → Expense'),
              ),
            OutlinedButton.icon(
              onPressed: _closing ? null : _reset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset count'),
            ),
            OutlinedButton(
              onPressed: _closing ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: ready && !_closing ? _closeDay : null,
              icon: _closing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified_outlined, size: 19),
              label: Text(_closing ? 'Closing day...' : 'Verify & Close Day'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                textStyle: DayBookStyles.button.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      );
}
