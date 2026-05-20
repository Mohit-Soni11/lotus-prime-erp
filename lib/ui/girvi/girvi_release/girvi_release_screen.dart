// =============================================================================
// FILE        : girvi_release_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Girvi Release (Redemption) screen.
//               Shows loan summary, auto-computed principal + interest +
//               penalty breakdown, editable penalty, payment mode selector,
//               and confirmation dialog before final release.
//               - App Bar extracted to girvi_release_app_bar.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'girvi_release_app_bar.dart'; // NAYA IMPORT
import '../shared/girvi_shared_widgets.dart';

class GirviReleaseScreen extends StatefulWidget {
  final GirviLoanModel loan;
  final String customerName;
  final AppDatabase db;
  final VoidCallback? onReleased;

  const GirviReleaseScreen({
    super.key,
    required this.loan,
    required this.customerName,
    required this.db,
    this.onReleased,
  });

  @override
  State<GirviReleaseScreen> createState() => _GirviReleaseScreenState();
}

class _GirviReleaseScreenState extends State<GirviReleaseScreen>
    with TickerProviderStateMixin {
  late final GirviReleaseController _ctrl;
  final _penaltyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');

  static const int _sectionCount = 3;
  late final List<AnimationController> _sectionAnim;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = GirviReleaseController(
      db: widget.db,
      loan: widget.loan,
      customerName: widget.customerName,
    );

    _penaltyCtrl.text =
        _ctrl.penalty > 0 ? _ctrl.penalty.toStringAsFixed(2) : '';

    _penaltyCtrl.addListener(() => _ctrl.onPenaltyChanged(_penaltyCtrl.text));

    _sectionAnim = List.generate(
        _sectionCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 450)));
    _sectionFade = _sectionAnim
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeInOut))
        .toList();
    _sectionSlide = _sectionAnim
        .map((a) => Tween<Offset>(
                begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 100), () {
        if (mounted) _sectionAnim[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _penaltyCtrl.dispose();
    _notesCtrl.dispose();
    for (final a in _sectionAnim) {
      a.dispose();
    }
    super.dispose();
  }

  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onRelease() async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    final ok = await _ctrl.processRelease(
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      releasedBy: 'Staff', // In real app: inject logged-in user name
    );

    if (ok && mounted) {
      _showSuccess(_ctrl.successMessage ?? GirviStrings.successReleased);
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onReleased?.call();
    } else if (mounted && _ctrl.errorMessage != null) {
      _showError(_ctrl.errorMessage!);
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: GirviColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(GirviIcons.release, color: GirviColors.success),
              const SizedBox(width: 10),
              Text('Confirm Release',
                  style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: GirviColors.textDark)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Release Girvi ticket ${widget.loan.ticketNo} for '
                    '${widget.customerName}?',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: GirviColors.textBody)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GirviColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GirviColors.successBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to Collect:',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GirviColors.textDark)),
                      Text('â‚¹ ${_fmt.format(_ctrl.total)}',
                          style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: GirviColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: GirviColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GirviColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Confirm Release',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(GirviIcons.markDone, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: GirviColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: GirviColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _sectionFade[i],
        child: SlideTransition(position: _sectionSlide[i], child: child),
      );

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;

    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      // NAYA APP BAR CALL
      appBar: GirviReleaseAppBar(
        onBack: () => Navigator.pop(context),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // â”€â”€ Loan Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _animated(0, _buildLoanSummaryCard(loan)),
                    const SizedBox(height: 16),

                    // â”€â”€ Settlement Breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _animated(1, _buildSettlementCard()),
                    const SizedBox(height: 16),

                    // â”€â”€ Payment Mode + Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _animated(2, _buildPaymentSection()),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // â”€â”€ LOAN SUMMARY CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLoanSummaryCard(GirviLoanModel loan) {
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.brandGold.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: GirviColors.shellBorder)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GirviColors.brandGoldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(GirviIcons.ticket,
                    color: GirviColors.brandGold, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loan.ticketNo, style: GirviStyles.ticketNumber),
                  Text(widget.customerName,
                      style: GoogleFonts.inter(
                          color: GirviColors.shellTextTitle,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              // Status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: loan.statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: loan.statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(loan.statusLabel,
                    style: GirviStyles.statusBadge
                        .copyWith(color: loan.statusColor)),
              ),
            ]),
          ),
          // Detail grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _DetailRow('Item', loan.itemDescription, null),
              const SizedBox(height: 8),
              _DetailRow(
                  'Metal',
                  '${loan.metalType} ${loan.metalPurity} Â· ${loan.netWeight.toStringAsFixed(2)}g',
                  null),
              const SizedBox(height: 8),
              _DetailRow('Loan Amount', 'â‚¹ ${_fmt.format(loan.loanAmount)}',
                  GirviColors.brandGold),
              const SizedBox(height: 8),
              _DetailRow('Start Date', _dateFmt.format(loan.startDate), null),
              _DetailRow(
                  'Maturity',
                  loan.maturityDate != null
                      ? _dateFmt.format(loan.maturityDate!)
                      : 'N/A',
                  loan.isOverdue ? GirviColors.danger : null),
              const SizedBox(height: 8),
              _DetailRow(
                  'Interest Rate',
                  '${loan.interestRate}% / month (${(loan.interestRate * 12).toStringAsFixed(0)}% p.a.)',
                  null),
              _DetailRow(
                  'Duration',
                  '${loan.daysElapsed} days (${loan.monthsElapsed.toStringAsFixed(1)} months)',
                  null),
            ]),
          ),
        ],
      ),
    );
  }

  // â”€â”€ SETTLEMENT BREAKDOWN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSettlementCard() {
    return GirviSectionCard(
      icon: GirviIcons.loanTerms,
      title: GirviStrings.secRelease,
      subtitle: GirviStrings.descRelease,
      accent: GirviColors.success,
      child: Column(children: [
        // Principal
        _SettlementLine(
          label: 'Principal (Loan Amount)',
          amount: _ctrl.principal,
          color: GirviColors.textDark,
          icon: GirviIcons.loanTerms,
        ),
        const SizedBox(height: 8),
        // Interest
        _SettlementLine(
          label:
              'Accrued Interest (${widget.loan.monthsElapsed.toStringAsFixed(1)} months)',
          amount: _ctrl.interest,
          color: GirviColors.warning,
          icon: GirviIcons.interestRate,
        ),
        const SizedBox(height: 8),

        // Penalty (editable)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(GirviIcons.overdue,
                  color: GirviColors.danger, size: 14),
              const SizedBox(width: 8),
              Text('Penalty / Overdue Charges',
                  style: GirviStyles.fieldLabel
                      .copyWith(color: GirviColors.danger)),
              const Spacer(),
              if (widget.loan.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GirviColors.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('OVERDUE',
                      style: GoogleFonts.inter(
                          color: GirviColors.danger,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 6),
            Container(
              height: 48,
              decoration: GirviStyles.inputNormal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Text('â‚¹ ',
                    style: GirviStyles.fieldInput
                        .copyWith(color: GirviColors.textMuted)),
                Expanded(
                  child: TextFormField(
                    controller: _penaltyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    style: GirviStyles.fieldInput
                        .copyWith(color: GirviColors.danger),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: GirviStyles.fieldHint,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Container(height: 1, color: GirviColors.divider),
        const SizedBox(height: 16),

        // TOTAL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GirviColors.success.withValues(alpha: 0.08),
                GirviColors.success.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GirviColors.successBorder),
          ),
          child: Row(children: [
            const Icon(GirviIcons.cash, color: GirviColors.success, size: 20),
            const SizedBox(width: 12),
            Text('Total Release Amount',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GirviColors.textDark)),
            const Spacer(),
            Text('â‚¹ ${_fmt.format(_ctrl.total)}',
                style: GirviStyles.amountLarge
                    .copyWith(color: GirviColors.success)),
          ]),
        ),
      ]),
    );
  }

  // â”€â”€ PAYMENT + NOTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPaymentSection() {
    return GirviSectionCard(
      icon: GirviIcons.cash,
      title: 'Payment Mode',
      subtitle: 'How will customer pay?',
      accent: GirviColors.accentInterest,
      child: Column(children: [
        _PaymentModeSelector(
          selected: _ctrl.paymentMode,
          onChanged: _ctrl.setPaymentMode,
        ),
        const SizedBox(height: 16),
        GirviInputField(
          label: 'Release Notes (Optional)',
          hint: 'e.g. Customer paid in full, no disputes...',
          icon: GirviIcons.notes,
          controller: _notesCtrl,
          maxLines: 2,
        ),
      ]),
    );
  }

  // â”€â”€ BOTTOM BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        border: const Border(top: BorderSide(color: GirviColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.shellBg.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (_, __) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            // Total summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total to Collect',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GirviColors.textMuted)),
                Text('â‚¹ ${_fmt.format(_ctrl.total)}',
                    style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: GirviColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            // Release button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _ctrl.isProcessing ? null : _onRelease,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GirviColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _ctrl.isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(GirviIcons.release, size: 18),
                            const SizedBox(width: 8),
                            Text(
                                'Release Girvi & Collect â‚¹${_fmt.format(_ctrl.total)}',
                                style: GirviStyles.saveButtonText
                                    .copyWith(color: Colors.white)),
                          ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// â”€â”€ Helper widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GirviStyles.readOnlyLabel),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? GirviColors.shellTextTitle)),
          ),
        ],
      );
}

class _SettlementLine extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SettlementLine({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GirviStyles.fieldLabel)),
      Text('â‚¹ ${fmt.format(amount)}',
          style: GoogleFonts.manrope(
              fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

// Reuse payment mode selector widget from new_girvi_screen
class _PaymentModeSelector extends StatelessWidget {
  final GirviPaymentMode selected;
  final void Function(GirviPaymentMode) onChanged;

  const _PaymentModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: GirviPaymentMode.values.map((mode) {
          final isSelected = mode == selected;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? GirviColors.brandGold.withValues(alpha: 0.12)
                    : GirviColors.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? GirviColors.brandGold
                      : GirviColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isSelected)
                  const Icon(GirviIcons.markDone,
                      color: GirviColors.brandGold, size: 14)
                else
                  const Icon(GirviIcons.cash,
                      color: GirviColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Text(mode.displayName,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? GirviColors.brandGold
                          : GirviColors.textBody,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
              ]),
            ),
          );
        }).toList(),
      );
}
