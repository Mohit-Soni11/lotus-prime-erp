import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/finance/expense/expense_draft.dart';
import '../../../models/reports/day_book/day_book_closing_mismatch.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_eod_sections.dart';
import 'day_book_closing_reconciliation_card.dart';
import 'day_book_form_visuals.dart';
import 'day_book_form_frame.dart';
import 'day_book_recorded_metal_closing_card.dart';
import 'day_book_closing_footer.dart';

class DayBookEodDialog extends StatefulWidget {
  const DayBookEodDialog(
      {super.key, required this.ctrl, this.fullScreen = false});
  final DayBookController ctrl;
  final bool fullScreen;

  @override
  State<DayBookEodDialog> createState() => _DayBookEodDialogState();
}

class _DayBookEodDialogState extends State<DayBookEodDialog> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.closingBankCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.closingBankCtrl.removeListener(_refresh);
    super.dispose();
  }

  double? get _actualBank {
    final text = widget.ctrl.closingBankCtrl.text.trim().replaceAll(',', '');
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    return value != null && value.isFinite ? value : null;
  }

  void _openExpenseDraft(ExpenseDraft draft) {
    Navigator.of(context).pop(draft);
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
        child: DayBookFormFrame(
          fullScreen: widget.fullScreen,
          title:
              'Day Closing · ${DateFormat('d MMM yyyy').format(widget.ctrl.selectedDate)}',
          dialogWidth: 690,
          onBack: _closing ? null : () => Navigator.of(context).pop(),
          child: SizedBox(
            child: ListenableBuilder(
              listenable: widget.ctrl,
              builder: (context, _) {
                final flow = widget.ctrl.summary?.moneyFlow;
                final actualBank = _actualBank;
                final countedCash = widget.ctrl.closingCashCountEntered ||
                        widget.ctrl.closingZeroCashConfirmed
                    ? widget.ctrl.physicalCashAmount
                    : null;
                final needsZeroCashConfirmation = flow != null &&
                    flow.closingCash.abs() < 0.01 &&
                    widget.ctrl.physicalCashAmount.abs() < 0.01;
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
                final prerequisites =
                    widget.ctrl.isRecordedMetalPositionConsistent &&
                        widget.ctrl.isCustodyPositionVerified;
                final ready = cashMatched &&
                    bankMatched &&
                    prerequisites &&
                    (!needsZeroCashConfirmation ||
                        widget.ctrl.closingZeroCashConfirmed);
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!widget.fullScreen) _header(context),
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
                            EodRecordedClosingBalances(
                              date: widget.ctrl.selectedDate,
                              flow: flow,
                              expenseTotal: expenseTotal,
                            ),
                            const SizedBox(height: 10),
                            EodPhysicalCashCount(
                              ctrl: widget.ctrl,
                              onCountChanged: () {
                                widget.ctrl.markClosingCashCountEntered();
                                setState(() {});
                              },
                            ),
                            if (needsZeroCashConfirmation) ...[
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                value: widget.ctrl.closingZeroCashConfirmed,
                                onChanged: _closing
                                    ? null
                                    : (value) => widget.ctrl
                                        .setClosingZeroCashConfirmed(
                                            value ?? false),
                                title: const Text(
                                    'I counted the cash drawer and confirm a zero cash balance.'),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                            const SizedBox(height: 10),
                            EodActualBankBalanceEntry(
                                controller: widget.ctrl.closingBankCtrl,
                                expected: flow.closingBank),
                            const SizedBox(height: 10),
                            DayBookRecordedMetalClosingCard(
                              position: widget.ctrl.summary?.ownedStockPosition,
                            ),
                            const SizedBox(height: 10),
                            EodClosingReconciliation(
                              expectedCash: flow.closingCash,
                              countedCash: countedCash,
                              expectedBank: flow.closingBank,
                              countedBank: actualBank,
                            ),
                            if (mismatch != null &&
                                mismatch.hasMismatch &&
                                (mismatch.hasOppositeMovements ||
                                    expenseDrafts.isEmpty)) ...[
                              const SizedBox(height: 10),
                              EodNotice(
                                  text: mismatch.hasOppositeMovements
                                      ? 'Cash and bank differ in opposite directions. Record the transfer or correct the payment mode before closing.'
                                      : 'Review any excess or missing receipt before closing the day.'),
                            ],
                            if (!prerequisites) ...[
                              const SizedBox(height: 10),
                              EodNotice(
                                  text: [
                                if (!widget
                                    .ctrl.isRecordedMetalPositionConsistent)
                                  'Recorded gold or silver closing needs review.',
                                if (!widget.ctrl.isCustodyPositionVerified)
                                  'Girvi custody handover dates are incomplete.',
                              ].join(' ')),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  DayBookClosingFooter(
                    ready: ready,
                    closing: _closing,
                    expenseDrafts: expenseDrafts,
                    onExpenseDraft: _openExpenseDraft,
                    onReset: widget.ctrl.resetClosingDraft,
                    onVerify: _closeDay,
                  ),
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
              Text('Day Closing',
                  style: DayBookStyles.pageTitle
                      .copyWith(fontSize: 22, color: DayBookColors.goldMetal)),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMM yyyy').format(widget.ctrl.selectedDate),
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
}
