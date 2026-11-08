import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_eod_sections.dart';
import 'day_book_form_visuals.dart';

class DayBookEodDialog extends StatefulWidget {
  const DayBookEodDialog({super.key, required this.ctrl});
  final DayBookController ctrl;

  @override
  State<DayBookEodDialog> createState() => _DayBookEodDialogState();
}

class _DayBookEodDialogState extends State<DayBookEodDialog> {
  final _bank = TextEditingController();
  bool _countConfirmed = false;
  bool _closing = false;

  List<TextEditingController> get _cashFields => [
        widget.ctrl.denom500Ctrl,
        widget.ctrl.denom200Ctrl,
        widget.ctrl.denom100Ctrl,
        widget.ctrl.denom50Ctrl,
        widget.ctrl.denom20Ctrl,
        widget.ctrl.denom10Ctrl,
        widget.ctrl.denomCoinsCtrl,
      ];

  @override
  void initState() {
    super.initState();
    _bank.addListener(_refresh);
    for (final field in _cashFields) {
      field.addListener(_cashEdited);
    }
  }

  void _refresh() => setState(() {});

  void _cashEdited() {
    if (_countConfirmed) setState(() => _countConfirmed = false);
  }

  @override
  void dispose() {
    _bank.removeListener(_refresh);
    _bank.dispose();
    for (final field in _cashFields) {
      field.removeListener(_cashEdited);
    }
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
    setState(() => _countConfirmed = false);
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
                final cashMatched =
                    _countConfirmed && widget.ctrl.isCashMatched;
                final bankMatched = flow != null &&
                    actualBank != null &&
                    (actualBank - flow.closingBank).abs() < 0.01;
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
                                date: widget.ctrl.selectedDate, flow: flow),
                            const SizedBox(height: 10),
                            EodCashCount(
                              ctrl: widget.ctrl,
                              confirmed: _countConfirmed,
                              onConfirmed: (value) =>
                                  setState(() => _countConfirmed = value),
                            ),
                            const SizedBox(height: 10),
                            EodBankCount(
                                controller: _bank, expected: flow.closingBank),
                            const SizedBox(height: 10),
                            EodVerificationSummary(
                              expectedCash: flow.closingCash,
                              countedCash: _countConfirmed
                                  ? widget.ctrl.physicalCashAmount
                                  : null,
                              expectedBank: flow.closingBank,
                              countedBank: actualBank,
                            ),
                            if (!cashMatched || !bankMatched) ...[
                              const SizedBox(height: 10),
                              const EodNotice(
                                  text:
                                      'Cash and bank must each match the system closing. Review missing entries or transfers before closing the day.'),
                            ],
                            if (!prerequisites) ...[
                              const SizedBox(height: 10),
                              EodNotice(
                                  text: [
                                if (widget.ctrl.balanceVerification == null)
                                  'Opening balance verification is pending.',
                                if (!widget.ctrl.isMetalPositionVerified)
                                  'Owned metal stock is unverified.',
                                if (!widget.ctrl.isCustodyPositionVerified)
                                  'Girvi custody is unverified.',
                              ].join(' ')),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  _footer(context, ready),
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

  Widget _footer(BuildContext context, bool ready) => Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DayBookColors.bodyBorder)),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 9,
          runSpacing: 8,
          children: [
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
