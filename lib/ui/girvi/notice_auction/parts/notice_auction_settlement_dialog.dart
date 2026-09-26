part of '../notice_auction_screen.dart';

class _DisposalSettlementResult {
  final double pledgedValuation;
  final double recoveredAmount;
  final double penaltyAmount;
  final String note;

  const _DisposalSettlementResult({
    required this.pledgedValuation,
    required this.recoveredAmount,
    required this.penaltyAmount,
    required this.note,
  });
}

class _DisposalSettlementDialog extends StatefulWidget {
  final NoticeAuctionCase item;

  const _DisposalSettlementDialog({required this.item});

  @override
  State<_DisposalSettlementDialog> createState() =>
      _DisposalSettlementDialogState();
}

class _DisposalSettlementDialogState extends State<_DisposalSettlementDialog> {
  late final TextEditingController _valuationController;
  late final TextEditingController _recoveredController;
  late final TextEditingController _penaltyController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _valuationController = TextEditingController(
      text: widget.item.loan.totalValue.toStringAsFixed(0),
    );
    _recoveredController = TextEditingController(text: '0');
    _penaltyController = TextEditingController(text: '0');
    _noteController = TextEditingController(
      text:
          'Final recovery settlement after three notices. Recovery proceeds adjusted against outstanding dues subject to applicable law and business policy.',
    );
  }

  @override
  void dispose() {
    _valuationController.dispose();
    _recoveredController.dispose();
    _penaltyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payable = widget.item.account.totalPayable;
    final penalty = _number(_penaltyController.text);
    final recovered = _number(_recoveredController.text);
    final settlementTotal = payable + penalty;
    final balanceDue =
        recovered >= settlementTotal ? 0.0 : settlementTotal - recovered;
    final surplus =
        recovered > settlementTotal ? recovered - settlementTotal : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GirviColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GirviColors.shadowMedium,
                blurRadius: 26,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final casePanel = _caseSnapshot(payable);
                        final recoveryPanel = _recoveryPanel(
                          payable: payable,
                          penalty: penalty,
                          recovered: recovered,
                          settlementTotal: settlementTotal,
                          balanceDue: balanceDue,
                          surplus: surplus,
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              casePanel,
                              const SizedBox(height: 14),
                              recoveryPanel,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 284, child: casePanel),
                            const SizedBox(width: 16),
                            Expanded(child: recoveryPanel),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _actionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: const BoxDecoration(
        color: GirviColors.shellBg,
        border: Border(
          bottom: BorderSide(color: GirviColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GirviColors.danger.withValues(alpha: 0.34),
              ),
            ),
            child: const Icon(
              GirviIcons.release,
              color: GirviColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Close Recovery Settlement',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Final recovery closure after all three notices are prepared.',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.8,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              widget.item.loan.ticketNo,
              style: GirviStyles.ticketNumber.copyWith(fontSize: 12.8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _caseSnapshot(double payable) {
    final account = widget.item.account;
    final loan = widget.item.loan;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Case Snapshot', GirviIcons.ticket),
          const SizedBox(height: 12),
          Text(
            account.customerName,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: GirviColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _snapshotChip('Notices ${widget.item.noticesSentLabel}'),
              _snapshotChip(widget.item.stageLabel),
            ],
          ),
          const SizedBox(height: 12),
          _snapshotLine('Mobile', account.customerMobile),
          _snapshotLine('Maturity', _date(loan.maturityDate)),
          _snapshotLine('Overdue Age', widget.item.overdueAgeMonthsDaysLabel),
          _snapshotLine('Pledged Value', _money(loan.totalValue)),
          _snapshotLine(
            'Total Payable',
            _money(payable),
            valueColor: GirviColors.danger,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pledged Item',
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: GirviColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _itemSummary(),
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recoveryPanel({
    required double payable,
    required double penalty,
    required double recovered,
    required double settlementTotal,
    required double balanceDue,
    required double surplus,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Recovery Details', GirviIcons.calculator),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _settlementField(
                controller: _valuationController,
                label: 'Pledged Valuation',
                helper: 'Current article value',
              ),
              _settlementField(
                controller: _recoveredController,
                label: 'Recovered Amount',
                helper: 'Cash or sale proceeds',
              ),
              _settlementField(
                controller: _penaltyController,
                label: 'Penalty / Handling',
                helper: 'Lawful extra charges',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settlementOutcome(
            payable: payable,
            penalty: penalty,
            recovered: recovered,
            settlementTotal: settlementTotal,
            balanceDue: balanceDue,
            surplus: surplus,
          ),
          const SizedBox(height: 14),
          _legalNotice(),
          const SizedBox(height: 14),
          Text(
            'Settlement Note',
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            style: GirviStyles.caption.copyWith(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Write the final recovery note for audit.',
              hintStyle: GirviStyles.caption.copyWith(
                color: GirviColors.textHint,
                fontSize: 12.5,
              ),
              filled: true,
              fillColor: GirviColors.bodyBg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: GirviColors.brandGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementOutcome({
    required double payable,
    required double penalty,
    required double recovered,
    required double settlementTotal,
    required double balanceDue,
    required double surplus,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Settlement Outcome', GirviIcons.valuation),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _settlementMetric('Total Payable', _money(payable)),
              _settlementMetric('Penalty', _money(penalty)),
              _settlementMetric(
                'Settlement Total',
                _money(settlementTotal),
                accent: GirviColors.brandGold,
              ),
              _settlementMetric('Recovered', _money(recovered)),
              _settlementMetric(
                'Balance Due',
                _money(balanceDue),
                accent:
                    balanceDue > 0 ? GirviColors.danger : GirviColors.success,
              ),
              _settlementMetric(
                'Surplus',
                _money(surplus),
                accent:
                    surplus > 0 ? GirviColors.success : GirviColors.textDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legalNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            GirviIcons.warning,
            color: GirviColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Close only after three notices are complete, supporting records are verified, and final recovery approval is available.',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: GirviColors.cardBg,
        border: Border(top: BorderSide(color: GirviColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'This action closes the overdue notice workflow for this ticket.',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textHint,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 14),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: GirviColors.textDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _closeSettlement,
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: Text(
              'Close Settlement',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GirviColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.brandGoldLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.warningBorder),
          ),
          child: Icon(icon, size: 17, color: GirviColors.brandDeep),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GirviStyles.sectionTitle.copyWith(fontSize: 15.5),
          ),
        ),
      ],
    );
  }

  Widget _snapshotChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Text(
        label,
        style: GirviStyles.statusBadge.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _snapshotLine(
    String label,
    String value, {
    Color valueColor = GirviColors.textDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: GirviColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeSettlement() {
    Navigator.of(context).pop(
      _DisposalSettlementResult(
        pledgedValuation: _number(_valuationController.text),
        recoveredAmount: _number(_recoveredController.text),
        penaltyAmount: _number(_penaltyController.text),
        note: _noteController.text.trim(),
      ),
    );
  }

  Widget _settlementField({
    required TextEditingController controller,
    required String label,
    required String helper,
  }) {
    return SizedBox(
      width: 142,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: GirviColors.textDark,
            ),
            decoration: InputDecoration(
              prefixText: 'Rs ',
              prefixStyle: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: GirviColors.textHint,
              ),
              filled: true,
              fillColor: GirviColors.bodyBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: GirviColors.brandGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              color: GirviColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementMetric(
    String label,
    String value, {
    Color accent = GirviColors.textDark,
  }) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.caption.copyWith(fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  String _date(DateTime? value) =>
      value == null ? 'Not set' : DateFormat('dd MMM yyyy').format(value);

  String _itemSummary() {
    final loan = widget.item.loan;
    final value = loan.itemDescription.trim().isEmpty
        ? loan.itemSummary
        : loan.itemDescription;
    return value
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => 'Serial Number ${match.group(1)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: GirviColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                GirviIcons.released,
                color: GirviColors.success,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GirviStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GirviStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
