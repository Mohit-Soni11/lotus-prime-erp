import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

const _kSilverAccent = Color(0xFF72889A);
const _kFineTone = Color(0xFF4E6F80);
const _kDueTone = Color(0xFFD65A3F);
const _kReturnTone = Color(0xFF15967D);
const _kNeutralTone = Color(0xFF64748B);

final _moneyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 2,
);

class SilverPaymentRecordCard extends StatelessWidget {
  final SilverStockController ctrl;
  final SilverPaymentController payment;

  const SilverPaymentRecordCard({
    super.key,
    required this.ctrl,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([payment, ctrl]),
      builder: (context, _) {
        final snapshot = payment.buildSnapshot(
          totalFineGrams: ctrl.totalFineWeight,
          makingAmount: ctrl.totalMakingAmount,
          gstEnabled: ctrl.gstEnabled,
        );
        final hasBase = ctrl.totalFineWeight > 0 && payment.hasRate;
        final status = _statusForSnapshot(snapshot: snapshot, hasBase: hasBase);

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AddStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AddStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AddStockColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: AddStockColors.shadowMedium,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(status: status, gstEnabled: ctrl.gstEnabled),
              _divider(),
              _BillDefinitionCard(
                ctrl: ctrl,
                payment: payment,
                snapshot: snapshot,
              ),
              if (!hasBase) ...[
                const SizedBox(height: 14),
                const _InfoNote(
                  tone: _kSilverAccent,
                  text:
                      'Pehle rate aur invoice fine ready karo. Uske baad payment collection aur final settlement neeche clearly show ho jayega.',
                ),
              ] else ...[
                const SizedBox(height: 14),
                _ModeSelectorCard(payment: payment),
                const SizedBox(height: 14),
                if (payment.hasAnyModeEnabled)
                  _CollectionCard(
                    payment: payment,
                    snapshot: snapshot,
                  )
                else
                  const _InfoNote(
                    tone: _kNeutralTone,
                    text:
                        'Payment collect karne ke liye upar se ek ya zyada mode select karo.',
                  ),
                const SizedBox(height: 14),
                _SettlementCard(
                  payment: payment,
                  snapshot: snapshot,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        height: 1,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 16),
        color: AddStockColors.cardBorder,
      );
}

class _CardHeader extends StatelessWidget {
  final _StatusMeta status;
  final bool gstEnabled;

  const _CardHeader({
    required this.status,
    required this.gstEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMENT RECORD',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AddStockColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gstEnabled
                    ? 'Defined GST bill and clean settlement view'
                    : 'Defined normal bill and clean settlement view',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AddStockColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(
              label: gstEnabled ? 'GST BILL' : 'NORMAL BILL',
              color: gstEnabled ? AddStockColors.success : _kSilverAccent,
            ),
            _StatusPill(label: status.label, color: status.color),
          ],
        ),
      ],
    );
  }
}

class _BillDefinitionCard extends StatelessWidget {
  final SilverStockController ctrl;
  final SilverPaymentController payment;
  final SilverPaymentSnapshot snapshot;

  const _BillDefinitionCard({
    required this.ctrl,
    required this.payment,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final snapshotDate = ctrl.silverRateDate == null
        ? 'Market snapshot unavailable'
        : 'Market snapshot ${DateFormat('dd MMM yyyy').format(ctrl.silverRateDate!)}';

    return _SectionCard(
      title: 'Bill Definition',
      subtitle: 'Rate, GST aur final bill yahan clearly define hota hai.',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final rateField = _NumberInputField(
                controller: payment.ratePerKgCtrl,
                label: 'Today Silver Rate',
                hint: ctrl.hasSilverRateSnapshot
                    ? (ctrl.silverRatePerGram * 1000).toStringAsFixed(0)
                    : '90000',
                prefixIcon: Icons.currency_rupee_rounded,
                suffix: '/ kg',
              );

              final rateStats = Column(
                children: [
                  _CompactStatTile(
                    label: 'Per Gram',
                    value: payment.ratePerGramDisplay,
                    tone: _kSilverAccent,
                  ),
                  const SizedBox(height: 10),
                  _CompactStatTile(
                    label: 'Market Ref',
                    value: ctrl.hasSilverRateSnapshot
                        ? '${_money(ctrl.silverRatePerGram)} / g'
                        : '--',
                    tone: AddStockColors.accentCompliance,
                    caption: snapshotDate,
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  children: [
                    rateField,
                    const SizedBox(height: 12),
                    rateStats,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: rateField),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: rateStats),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920
                  ? 4
                  : constraints.maxWidth >= 520
                      ? 2
                      : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - ((columns - 1) * gap)) / columns;

              final tiles = [
                _CompactStatTile(
                  label: 'Total Fine',
                  value: '${snapshot.totalFineGrams.toStringAsFixed(3)} g',
                  tone: _kFineTone,
                ),
                _CompactStatTile(
                  label: 'Fine Value',
                  value: _money(snapshot.fineAmount),
                  tone: _kSilverAccent,
                ),
                _CompactStatTile(
                  label: 'Making',
                  value: _money(snapshot.makingAmount),
                  tone: AddStockColors.accentPricing,
                ),
                _CompactStatTile(
                  label: 'Bill Type',
                  value: ctrl.gstEnabled ? 'GST Applied' : 'Without GST',
                  tone: ctrl.gstEnabled
                      ? AddStockColors.success
                      : AddStockColors.textBody,
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tiles
                    .map((tile) => SizedBox(width: width, child: tile))
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 14),
          if (ctrl.gstEnabled) ...[
            const _SectionDivider(label: 'GST Setup'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Auto GST',
                    caption: 'Metal 5% + cash 3%',
                    icon: Icons.auto_mode_rounded,
                    selected: !payment.useManualGst,
                    tone: AddStockColors.success,
                    onTap: () => payment.setUseManualGst(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Manual GST',
                    caption: 'GST amount khud likho',
                    icon: Icons.edit_note_rounded,
                    selected: payment.useManualGst,
                    tone: AddStockColors.success,
                    onTap: () => payment.setUseManualGst(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (payment.useManualGst)
              _NumberInputField(
                controller: payment.manualGstAmountCtrl,
                label: 'Manual GST Amount',
                hint: snapshot.autoGstAmount.toStringAsFixed(2),
                prefixIcon: Icons.receipt_long_rounded,
                suffix: 'Rs',
              )
            else
              _InfoNote(
                tone: AddStockColors.success,
                text:
                    'Auto GST abhi ${_money(snapshot.autoGstAmount)} hai. Ye total bill me add ho raha hai.',
              ),
            const SizedBox(height: 14),
          ] else ...[
            const _InfoNote(
              tone: _kNeutralTone,
              text:
                  'Normal bill mode me GST add nahi hoga. Final amount sirf fine value + making se banega.',
            ),
            const SizedBox(height: 14),
          ],
          const _SectionDivider(label: 'Bill Summary'),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Fine',
            value: '${snapshot.totalFineGrams.toStringAsFixed(3)} g',
          ),
          _SummaryRow(
            label: 'Rate Per Gram',
            value: payment.ratePerGramDisplay,
          ),
          _SummaryRow(
            label: 'Fine Amount',
            value: _money(snapshot.fineAmount),
          ),
          _SummaryRow(
            label: 'Making Amount',
            value: _money(snapshot.makingAmount),
          ),
          _SummaryRow(
            label: 'GST Amount',
            value: _money(snapshot.appliedGstAmount),
            caption: ctrl.gstEnabled
                ? payment.useManualGst
                    ? 'Manual GST added in bill'
                    : 'Auto GST added in bill'
                : 'No GST in normal bill',
          ),
          _SummaryRow(
            label: 'Final Bill Amount',
            value: _money(snapshot.totalBillAmount),
            highlight: true,
            valueColor: AddStockColors.success,
          ),
        ],
      ),
    );
  }
}

class _ModeSelectorCard extends StatelessWidget {
  final SilverPaymentController payment;

  const _ModeSelectorCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment Modes',
      subtitle: 'Jo payment liya hai uska mode select karo.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: SilverPaymentMode.values
            .map(
              (mode) => _ModeChip(
                mode: mode,
                selected: payment.isModeEnabled(mode),
                onTap: () => payment.toggleMode(mode),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final SilverPaymentController payment;
  final SilverPaymentSnapshot snapshot;

  const _CollectionCard({
    required this.payment,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final cashModes = SilverPaymentMode.values
        .where((mode) => mode != SilverPaymentMode.metalToMetal)
        .where(payment.isModeEnabled)
        .toList(growable: false);
    final metalSelected = payment.isModeEnabled(SilverPaymentMode.metalToMetal);

    return _SectionCard(
      title: 'Payment Collection',
      subtitle: 'Metal aur cash side ki collection yahan clearly enter karo.',
      child: Column(
        children: [
          if (metalSelected) ...[
            const _SubSectionHeading(
              title: 'Metal Adjustment',
              subtitle:
                  'Supplier ne jo metal diya hai uska fine yahan niklega.',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 700;
                final grossField = _NumberInputField(
                  controller: payment.metalGrossWeightCtrl,
                  label: 'Metal Given',
                  hint: '0.000',
                  prefixIcon: Icons.balance_rounded,
                  suffix: 'gram',
                );
                final purityField = _NumberInputField(
                  controller: payment.metalPurityCtrl,
                  label: 'Purity',
                  hint: '92.5',
                  prefixIcon: Icons.percent_rounded,
                  suffix: '%',
                );

                if (stacked) {
                  return Column(
                    children: [
                      grossField,
                      const SizedBox(height: 10),
                      purityField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: grossField),
                    const SizedBox(width: 10),
                    Expanded(child: purityField),
                  ],
                );
              },
            ),
            if (payment.hasMetalCalculation) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 920
                      ? 4
                      : constraints.maxWidth >= 520
                          ? 2
                          : 1;
                  const gap = 10.0;
                  final width =
                      (constraints.maxWidth - ((columns - 1) * gap)) / columns;
                  final balanceLabel = snapshot.extraFineGrams > 0
                      ? 'Extra Fine'
                      : snapshot.shortFineGrams > 0
                          ? 'Short Fine'
                          : 'Fine Match';
                  final balanceValue = snapshot.extraFineGrams > 0
                      ? '+${snapshot.extraFineGrams.toStringAsFixed(3)} g'
                      : snapshot.shortFineGrams > 0
                          ? '-${snapshot.shortFineGrams.toStringAsFixed(3)} g'
                          : '0.000 g';
                  final balanceTone = snapshot.extraFineGrams > 0
                      ? _kReturnTone
                      : snapshot.shortFineGrams > 0
                          ? _kDueTone
                          : AddStockColors.success;

                  final tiles = [
                    _CompactStatTile(
                      label: 'Invoice Fine',
                      value: '${snapshot.totalFineGrams.toStringAsFixed(3)} g',
                      tone: _kFineTone,
                    ),
                    _CompactStatTile(
                      label: 'Metal Fine',
                      value:
                          '${snapshot.metalFineCalculated.toStringAsFixed(3)} g',
                      tone: _kSilverAccent,
                    ),
                    _CompactStatTile(
                      label: 'Metal Value',
                      value: _money(snapshot.metalFineEquivalentCash),
                      tone: AddStockColors.accentPricing,
                    ),
                    _CompactStatTile(
                      label: balanceLabel,
                      value: balanceValue,
                      tone: balanceTone,
                    ),
                  ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: tiles
                        .map((tile) => SizedBox(width: width, child: tile))
                        .toList(growable: false),
                  );
                },
              ),
            ],
            if (cashModes.isNotEmpty) const SizedBox(height: 14),
          ],
          if (cashModes.isNotEmpty) ...[
            const _SubSectionHeading(
              title: 'Cash Collection',
              subtitle: 'Residual amount ko cash, UPI, bank ya card me bharo.',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920
                    ? 4
                    : constraints.maxWidth >= 520
                        ? 2
                        : 1;
                const gap = 10.0;
                final width =
                    (constraints.maxWidth - ((columns - 1) * gap)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: cashModes
                      .map(
                        (mode) => SizedBox(
                          width: width,
                          child: _NumberInputField(
                            controller: _controllerForMode(mode),
                            label: mode.label,
                            hint: '0.00',
                            prefixIcon: mode.icon,
                            suffix: 'Rs',
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  TextEditingController _controllerForMode(SilverPaymentMode mode) {
    return switch (mode) {
      SilverPaymentMode.cash => payment.cashCtrl,
      SilverPaymentMode.upi => payment.upiCtrl,
      SilverPaymentMode.banking => payment.bankingCtrl,
      SilverPaymentMode.card => payment.cardCtrl,
      SilverPaymentMode.metalToMetal => payment.cashCtrl,
    };
  }
}

class _SettlementCard extends StatelessWidget {
  final SilverPaymentController payment;
  final SilverPaymentSnapshot snapshot;

  const _SettlementCard({
    required this.payment,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final resultTone = snapshot.hasReturn
        ? _kReturnTone
        : snapshot.hasDue
            ? _kDueTone
            : AddStockColors.success;
    final resultLabel = snapshot.hasReturn
        ? 'Return Pending'
        : snapshot.hasDue
            ? 'Due Pending'
            : 'Settlement Complete';
    final resultValue = snapshot.hasReturn
        ? snapshot.returnDisplay
        : snapshot.hasDue
            ? snapshot.dueDisplay
            : 'Settled';

    return _SectionCard(
      title: 'Final Settlement',
      subtitle: 'Ab bill aur received amount ka clean final result dekho.',
      child: Column(
        children: [
          _SummaryRow(
              label: 'Final Bill Amount', value: snapshot.totalBillDisplay),
          _SummaryRow(
            label: 'Metal Value Received',
            value: _money(snapshot.metalFineEquivalentCash),
          ),
          _SummaryRow(
            label: 'Cash Value Received',
            value: _money(snapshot.totalCashPaid),
          ),
          _SummaryRow(
            label: 'Total Received',
            value: snapshot.totalPaidDisplay,
            highlight: true,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: resultTone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: resultTone.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    color: resultTone,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resultValue,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: resultTone,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.hasReturn
                      ? 'Supplier se return lena baaki hai.'
                      : snapshot.hasDue
                          ? 'Supplier par abhi balance due baaki hai.'
                          : 'Bill aur received amount dono balance ho chuke hain.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: resultTone.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          if (snapshot.hasDue) ...[
            const SizedBox(height: 12),
            const _SubSectionHeading(
              title: 'Due Handling',
              subtitle:
                  'Due ko fine me rakhna hai ya cash me, yahan choose karo.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Fine Due',
                    caption: 'Grams equivalent',
                    icon: Icons.balance_rounded,
                    selected: payment.dueSettleMode == DueSettleMode.asFine,
                    tone: _kDueTone,
                    onTap: () => payment.setDueSettleMode(DueSettleMode.asFine),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Cash Due',
                    caption: 'Rupee due amount',
                    icon: Icons.currency_rupee_rounded,
                    selected: payment.dueSettleMode == DueSettleMode.asCash,
                    tone: _kDueTone,
                    onTap: () => payment.setDueSettleMode(DueSettleMode.asCash),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ResultNote(
              tone: _kDueTone,
              title: payment.dueSettleMode == DueSettleMode.asFine
                  ? 'Due in Fine'
                  : 'Due in Cash',
              value: payment.dueSettleMode == DueSettleMode.asFine
                  ? '${snapshot.dueAmountAsFine.toStringAsFixed(3)} g'
                  : snapshot.dueDisplay,
              caption: payment.dueSettleMode == DueSettleMode.asFine
                  ? 'Equivalent cash ${snapshot.dueDisplay}'
                  : 'Equivalent fine ${snapshot.dueAmountAsFine.toStringAsFixed(3)} g',
            ),
          ],
          if (snapshot.hasReturn) ...[
            const SizedBox(height: 12),
            const _SubSectionHeading(
              title: 'Return Handling',
              subtitle:
                  'Extra settlement ko metal return rakhna hai ya value return, yahan choose karo.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Return Metal',
                    caption: 'Metal wapas lo',
                    icon: Icons.reply_all_rounded,
                    selected: payment.excessSettleMode ==
                        ExcessSettleMode.returnMetal,
                    tone: _kReturnTone,
                    onTap: () => payment.setExcessSettleMode(
                      ExcessSettleMode.returnMetal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Return Value',
                    caption: 'Cash value lo',
                    icon: Icons.currency_exchange_rounded,
                    selected: payment.excessSettleMode ==
                        ExcessSettleMode.returnCashValue,
                    tone: _kReturnTone,
                    onTap: () => payment.setExcessSettleMode(
                      ExcessSettleMode.returnCashValue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ResultNote(
              tone: _kReturnTone,
              title: payment.excessSettleMode == ExcessSettleMode.returnMetal
                  ? 'Return in Metal'
                  : 'Return in Cash',
              value: payment.excessSettleMode == ExcessSettleMode.returnMetal
                  ? '${snapshot.returnAmountAsFine.toStringAsFixed(3)} g'
                  : snapshot.returnDisplay,
              caption: payment.excessSettleMode == ExcessSettleMode.returnMetal
                  ? 'Equivalent cash ${snapshot.returnDisplay}'
                  : 'Equivalent fine ${snapshot.returnAmountAsFine.toStringAsFixed(3)} g',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AddStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AddStockColors.textBody,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SubSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SubSectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AddStockColors.textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AddStockColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AddStockColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AddStockColors.textMuted,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AddStockColors.cardBorder)),
      ],
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final String? caption;

  const _CompactStatTile({
    required this.label,
    required this.value,
    required this.tone,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: tone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AddStockColors.textDark,
              height: 1,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AddStockColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final bool highlight;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.caption,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        highlight ? _kSilverAccent.withValues(alpha: 0.07) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textBody,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AddStockColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AddStockColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final SilverPaymentMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? _kSilverAccent.withValues(alpha: 0.09)
        : AddStockColors.cardBg;
    final border = selected
        ? _kSilverAccent.withValues(alpha: 0.28)
        : AddStockColors.cardBorder;
    final color = selected ? _kSilverAccent : AddStockColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(
              mode.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? tone.withValues(alpha: 0.09) : Colors.white;
    final border =
        selected ? tone.withValues(alpha: 0.28) : AddStockColors.cardBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 17, color: selected ? tone : AddStockColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? tone : AddStockColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AddStockColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultNote extends StatelessWidget {
  final Color tone;
  final String title;
  final String value;
  final String caption;

  const _ResultNote({
    required this.tone,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: tone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: tone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final Color tone;
  final String text;

  const _InfoNote({
    required this.tone,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: tone,
        ),
      ),
    );
  }
}

class _NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String suffix;

  const _NumberInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
            color: AddStockColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
          ],
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AddStockColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AddStockColors.textHint,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _kSilverAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(prefixIcon, size: 15, color: _kSilverAccent),
              ),
            ),
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AddStockColors.textMuted,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AddStockColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AddStockColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kSilverAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;

  const _StatusMeta(this.label, this.color);
}

_StatusMeta _statusForSnapshot({
  required SilverPaymentSnapshot snapshot,
  required bool hasBase,
}) {
  if (!hasBase) {
    return const _StatusMeta('PENDING', _kNeutralTone);
  }
  if (snapshot.hasReturn) {
    return const _StatusMeta('RETURN', _kReturnTone);
  }
  if (snapshot.hasDue && snapshot.totalPaidValue > 0) {
    return const _StatusMeta('PARTIAL', _kDueTone);
  }
  if (snapshot.hasDue) {
    return const _StatusMeta('READY', _kSilverAccent);
  }
  if (snapshot.totalPaidValue > 0) {
    return const _StatusMeta('SETTLED', AddStockColors.success);
  }
  return const _StatusMeta('READY', _kSilverAccent);
}

String _money(double amount) => _moneyFormatter.format(amount);
