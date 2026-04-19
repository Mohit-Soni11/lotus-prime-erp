// =============================================================================
// FILE        : interest_calc_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Standalone Interest Calculator — fully reactive.
//               Inputs: Principal, Rate/Month, Duration.
//               Outputs: Monthly interest, Total interest, Total due,
//                        Annual rate, Month-wise breakdown table.
//               Zero DB — pure computation via InterestCalcController.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../logic/girvi/girvi_controllers.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

class InterestCalcScreen extends StatefulWidget {
  const InterestCalcScreen({super.key});

  @override
  State<InterestCalcScreen> createState() => _InterestCalcScreenState();
}

class _InterestCalcScreenState extends State<InterestCalcScreen>
    with TickerProviderStateMixin {

  final _ctrl         = InterestCalcController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl      = TextEditingController(text: '2.0');
  final _monthsCtrl    = TextEditingController(text: '12');

  final _principalFocus = FocusNode();
  final _rateFocus      = FocusNode();
  final _monthsFocus    = FocusNode();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _principalCtrl.addListener(() => _ctrl.onPrincipalChanged(_principalCtrl.text));
    _rateCtrl.addListener(()      => _ctrl.onRateChanged(_rateCtrl.text));
    _monthsCtrl.addListener(()    => _ctrl.onMonthsChanged(_monthsCtrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _monthsCtrl.dispose();
    _principalFocus.dispose();
    _rateFocus.dispose();
    _monthsFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onReset() {
    _principalCtrl.clear();
    _rateCtrl.text  = '2.0';
    _monthsCtrl.text = '12';
    _ctrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle:    GirviStrings.calcTitle,
        screenSubtitle: GirviStrings.calcSub,
        onBack:         () => Navigator.pop(context),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Input Card ─────────────────────────────────────
                      GirviSectionCard(
                        icon:     GirviIcons.calculator,
                        title:    'Loan Parameters',
                        subtitle: 'Enter values to compute interest',
                        accent:   GirviColors.brandGold,
                        child: Column(children: [
                          GirviInputField(
                            label:           'Principal Amount (₹) *',
                            hint:            '0.00',
                            icon:            GirviIcons.loanTerms,
                            controller:      _principalCtrl,
                            focusNode:       _principalFocus,
                            nextFocus:       _rateFocus,
                            keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            prefixText:      '₹ ',
                          ),
                          const SizedBox(height: 14),
                          GirviRowTwo(
                            left: GirviInputField(
                              label:           'Interest Rate (% / month)',
                              hint:            '2.0',
                              icon:            GirviIcons.interestRate,
                              controller:      _rateCtrl,
                              focusNode:       _rateFocus,
                              nextFocus:       _monthsFocus,
                              keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              suffixText:      '%',
                            ),
                            right: GirviInputField(
                              label:           'Duration (months)',
                              hint:            '12',
                              icon:            GirviIcons.dates,
                              controller:      _monthsCtrl,
                              focusNode:       _monthsFocus,
                              keyboardType:    TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              suffixText:      'mo',
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _onReset,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(GirviIcons.refresh,
                                    color: GirviColors.textMuted, size: 14),
                                const SizedBox(width: 6),
                                Text('Reset',
                                    style: GirviStyles.caption.copyWith(
                                        fontSize: 12,
                                        color: GirviColors.textMuted)),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Results Card ────────────────────────────────────
                      if (_ctrl.principal > 0) ...[
                        _buildResultsCard(),
                        const SizedBox(height: 16),
                        _buildBreakdownTable(),
                      ],

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GirviColors.shellBg, GirviColors.shellPanelBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.brandGold.withOpacity(0.25)),
        boxShadow: [BoxShadow(
          color: GirviColors.brandGold.withOpacity(0.08),
          blurRadius: 14, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: GirviColors.shellBorder)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(GirviIcons.interestRate,
                  color: GirviColors.brandGold, size: 16),
              const SizedBox(width: 8),
              Text('Computation Results',
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextTitle,
                    fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GirviColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_ctrl.annualRate.toStringAsFixed(0)}% p.a.',
                    style: GoogleFonts.inter(
                        color: GirviColors.warning,
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          // Main stats grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                _ResultStat(
                  label: 'Monthly Interest',
                  value: '₹ ${_fmt.format(_ctrl.monthlyInterest)}',
                  color: GirviColors.warning,
                  large: false,
                ),
                const SizedBox(width: 12),
                _ResultStat(
                  label: 'Total Interest',
                  value: '₹ ${_fmt.format(_ctrl.totalInterest)}',
                  color: GirviColors.danger,
                  large: false,
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GirviColors.brandGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GirviColors.brandGold.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Text('Total Amount Due at Maturity',
                      style: GoogleFonts.inter(
                          color: GirviColors.shellTextMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('₹ ${_fmt.format(_ctrl.totalDue)}',
                      style: GoogleFonts.manrope(
                          color: GirviColors.brandGold,
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  Text(
                      'Principal: ₹${_fmt.format(_ctrl.principal)} + '
                      'Interest: ₹${_fmt.format(_ctrl.totalInterest)}',
                      style: GirviStyles.caption.copyWith(
                          color: GirviColors.shellTextMuted, fontSize: 11)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTable() {
    final rows = _ctrl.monthTable;

    return GirviSectionCard(
      icon:     GirviIcons.list,
      title:    'Month-wise Breakdown',
      subtitle: 'Interest accrual per month',
      accent:   GirviColors.info,
      child: Column(children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            _TableHeader('Month',    flex: 1),
            _TableHeader('Interest', flex: 2),
            _TableHeader('Balance',  flex: 2),
          ]),
        ),
        const SizedBox(height: 8),
        // Rows (limit to first 24 with scroll)
        SizedBox(
          height: rows.length > 6 ? 280 : null,
          child: rows.length > 6
              ? ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _buildTableRow(rows[i], i),
                )
              : Column(
                  children: rows.map((r) => _buildTableRow(r, rows.indexOf(r))).toList(),
                ),
        ),
      ]),
    );
  }

  Widget _buildTableRow(MonthRow r, int index) {
    final isEven = index % 2 == 0;
    return Container(
      color: isEven ? GirviColors.bodyBg : GirviColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(children: [
        Expanded(
          flex: 1,
          child: Text('Month ${r.month}',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: GirviColors.textMuted)),
        ),
        Expanded(
          flex: 2,
          child: Text('₹ ${_fmt.format(r.interest)}',
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: GirviColors.warning)),
        ),
        Expanded(
          flex: 2,
          child: Text('₹ ${_fmt.format(r.balance)}',
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: GirviColors.textDark)),
        ),
      ]),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   large;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    required this.large,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.manrope(
                  color: color,
                  fontSize: large ? 16 : 13,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int    flex;
  const _TableHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: GirviColors.textMuted, letterSpacing: 0.5)),
  );
}
