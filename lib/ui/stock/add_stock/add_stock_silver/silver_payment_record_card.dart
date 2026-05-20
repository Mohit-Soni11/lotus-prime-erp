import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_invoice_summary_logic.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverPaymentRecordCard extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverPaymentRecordCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final summary = ctrl.invoiceSummary;
        final snapshot = summary.paymentSnapshot;

        return Container(
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SilverStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: SilverStockColors.shadowLight,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: SilverStockColors.shadowMedium,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentHeader(snapshot: snapshot, gstEnabled: ctrl.gstEnabled),
                const Divider(height: 1, color: SilverStockColors.cardBorder),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RateAndInvoiceBoard(
                        summary: summary,
                        payment: ctrl.payment,
                      ),
                      const SizedBox(height: 14),
                      _PaymentModePicker(payment: ctrl.payment),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(ctrl.payment.paymentMode),
                          child: ctrl.payment.paymentMode ==
                                  PaymentMode.metalToMetal
                              ? _MetalSettlementPanel(payment: ctrl.payment)
                              : _CashSettlementPanel(payment: ctrl.payment),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FinalSettlementCard(
                        snapshot: snapshot,
                        payment: ctrl.payment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  final SilverPaymentSnapshot snapshot;
  final bool gstEnabled;

  const _PaymentHeader({required this.snapshot, required this.gstEnabled});

  @override
  Widget build(BuildContext context) {
    final accent = gstEnabled
        ? SilverStockColors.success
        : SilverStockColors.paymentPrimary;
    final gstLabel = gstEnabled
        ? '${snapshot.gstPercent.toStringAsFixed(0)}% GST from Batch Overview'
        : 'Normal bill from Batch Overview';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          _IconBox(icon: SilverStockIcons.paymentHub, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SilverStockStrings.paymentRecordTitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  SilverStockStrings.paymentRecordSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: gstLabel, color: accent),
        ],
      ),
    );
  }
}

class _RateAndInvoiceBoard extends StatelessWidget {
  final SilverInvoiceSummaryData summary;
  final SilverPaymentController payment;

  const _RateAndInvoiceBoard({required this.summary, required this.payment});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: SilverStockIcons.rateChart,
            title: 'Rate and Invoice Definition',
            subtitle: 'Silver rate, fine value, making and final payable.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 740;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RateInput(payment: payment),
                    const SizedBox(height: 10),
                    _RateMetrics(summary: summary),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 38, child: _RateInput(payment: payment)),
                  const SizedBox(width: 12),
                  Expanded(flex: 62, child: _RateMetrics(summary: summary)),
                ],
              );
            },
          ),
          if (summary.gstEnabled) ...[
            const SizedBox(height: 14),
            _GstPercentBoard(payment: payment),
          ],
          const SizedBox(height: 14),
          _InvoiceStatement(summary: summary),
        ],
      ),
    );
  }
}

class _RateInput extends StatelessWidget {
  final SilverPaymentController payment;

  const _RateInput({required this.payment});

  @override
  Widget build(BuildContext context) {
    return _PaymentInput(
      label: 'Rate Per Kg',
      hint: '0.00',
      suffixText: '/kg',
      icon: SilverStockIcons.rateChart,
      controller: payment.todayRatePerKgCtrl,
    );
  }
}

class _RateMetrics extends StatelessWidget {
  final SilverInvoiceSummaryData summary;

  const _RateMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final snapshot = summary.paymentSnapshot;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniMetric(
          label: 'Per Gram',
          value: _money(snapshot.ratePerGram),
          tone: SilverStockColors.paymentPrimary,
        ),
        _MiniMetric(
          label: 'Total Fine',
          value: _weight(summary.totalFineWeight),
          tone: SilverStockColors.paymentFine,
        ),
        _MiniMetric(
          label: 'Making',
          value: _money(summary.totalMakingAmount),
          tone: SilverStockColors.accentPricing,
        ),
        _MiniMetric(
          label: 'Final Bill',
          value: _money(snapshot.totalBillAmount),
          tone: summary.gstEnabled
              ? SilverStockColors.success
              : SilverStockColors.paymentPrimary,
        ),
      ],
    );
  }
}

class _InvoiceStatement extends StatelessWidget {
  final SilverInvoiceSummaryData summary;

  const _InvoiceStatement({required this.summary});

  @override
  Widget build(BuildContext context) {
    final snapshot = summary.paymentSnapshot;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SilverStockColors.paymentStatementBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SilverStockColors.paymentStatementBorder),
      ),
      child: Column(
        children: [
          _StatementRow(
            label: 'Total Fine',
            value: _weight(summary.totalFineWeight),
          ),
          _StatementRow(
            label: 'Rate',
            value: '${_money(snapshot.ratePerGram)} /g',
          ),
          _StatementRow(
            label: 'Fine Value',
            value: _money(snapshot.fineValueAmount),
          ),
          _StatementRow(
            label: 'Making',
            value: _money(snapshot.totalMakingAmount),
          ),
          if (snapshot.gstPercent > 0)
            _StatementRow(
              label: 'GST (${snapshot.gstPercent.toStringAsFixed(0)}%)',
              value: _money(snapshot.appliedGstAmount),
              valueColor: SilverStockColors.success,
            ),
          const Divider(height: 18, color: SilverStockColors.cardBorder),
          _StatementRow(
            label: 'Total Bill Amount',
            value: _money(snapshot.totalBillAmount),
            emphasized: true,
            valueColor: summary.gstEnabled
                ? SilverStockColors.success
                : SilverStockColors.paymentPrimary,
          ),
        ],
      ),
    );
  }
}

class _PaymentModePicker extends StatelessWidget {
  final SilverPaymentController payment;

  const _PaymentModePicker({required this.payment});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: SilverStockIcons.paymentStatement,
            title: SilverStockStrings.paymentModesTitle,
            subtitle: 'GST is controlled only from Batch Overview.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 680;
              final tiles = [
                _PaymentModeTile(
                  title: 'Metal to Metal',
                  subtitle:
                      'Fine adjusts against fine; due or extra can stay in fine or value.',
                  icon: SilverStockIcons.metalAdjust,
                  active: payment.paymentMode == PaymentMode.metalToMetal,
                  color: SilverStockColors.paymentFine,
                  onTap: () => payment.setPaymentMode(PaymentMode.metalToMetal),
                ),
                _PaymentModeTile(
                  title: 'Cash / Bank',
                  subtitle:
                      'Full fine value, making and GST settle through payment split.',
                  icon: SilverStockIcons.cashPayment,
                  active: payment.paymentMode == PaymentMode.cash,
                  color: SilverStockColors.accentPricing,
                  onTap: () => payment.setPaymentMode(PaymentMode.cash),
                ),
              ];

              if (stacked) {
                return Column(
                  children: [tiles[0], const SizedBox(height: 10), tiles[1]],
                );
              }

              return Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GstPercentBoard extends StatelessWidget {
  final SilverPaymentController payment;

  const _GstPercentBoard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final metalActive = payment.paymentMode == PaymentMode.metalToMetal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SilverStockColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SilverStockColors.success.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.percent_rounded,
                color: SilverStockColors.success,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metalActive
                      ? 'Metal to metal GST percent yahan set karo.'
                      : 'Cash / bank GST percent yahan set karo.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SilverStockColors.textBody,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 620;
              final metalField = _PaymentInput(
                label: 'Metal GST',
                hint: '5',
                suffixText: '%',
                icon: Icons.percent_rounded,
                controller: payment.metalGstPercentCtrl,
              );
              final cashField = _PaymentInput(
                label: 'Cash / Bank GST',
                hint: '3',
                suffixText: '%',
                icon: Icons.percent_rounded,
                controller: payment.cashGstPercentCtrl,
              );

              if (stacked) {
                return Column(
                  children: [metalField, const SizedBox(height: 10), cashField],
                );
              }

              return Row(
                children: [
                  Expanded(child: metalField),
                  const SizedBox(width: 10),
                  Expanded(child: cashField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetalSettlementPanel extends StatelessWidget {
  final SilverPaymentController payment;

  const _MetalSettlementPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: SilverStockIcons.metalExchange,
            title: 'Metal Settlement Board',
            subtitle:
                'Enter metal received, then decide how shortage or excess is handled.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final gross = _PaymentInput(
                label: 'Metal Given',
                hint: '0.000',
                suffixText: 'g',
                icon: SilverStockIcons.weight,
                controller: payment.metalGrossCtrl,
              );
              final purity = _PaymentInput(
                label: 'Purity',
                hint: '0.00',
                suffixText: '%',
                icon: SilverStockIcons.purity,
                controller: payment.metalPurityCtrl,
              );

              if (stacked) {
                return Column(
                  children: [gross, const SizedBox(height: 10), purity],
                );
              }

              return Row(
                children: [
                  Expanded(child: gross),
                  const SizedBox(width: 10),
                  Expanded(child: purity),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _MetalMathStrip(payment: payment),
          if (payment.fineReceived > 0 &&
              (payment.isDueMetal || payment.isExtraMetal)) ...[
            const SizedBox(height: 12),
            _MetalSettlementChoice(payment: payment),
          ],
          const SizedBox(height: 14),
          _CashTargetNote(payment: payment),
          const SizedBox(height: 12),
          _CashSplitFields(payment: payment),
        ],
      ),
    );
  }
}

class _CashSettlementPanel extends StatelessWidget {
  final SilverPaymentController payment;

  const _CashSettlementPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: SilverStockIcons.cashPayment,
            title: 'Cash / Bank Settlement',
            subtitle: 'Collect the payable through cash, UPI, bank or card.',
          ),
          const SizedBox(height: 12),
          _CashTargetNote(payment: payment),
          const SizedBox(height: 12),
          _CashSplitFields(payment: payment),
        ],
      ),
    );
  }
}

class _MetalMathStrip extends StatelessWidget {
  final SilverPaymentController payment;

  const _MetalMathStrip({required this.payment});

  @override
  Widget build(BuildContext context) {
    final hasInput = payment.fineReceived > 0;
    final diffTone = payment.isExtraMetal
        ? SilverStockColors.paymentReturn
        : payment.isDueMetal
            ? SilverStockColors.paymentDue
            : SilverStockColors.success;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniMetric(
          label: 'Required Fine',
          value: _weight(payment.totalFineFromItems),
          tone: SilverStockColors.paymentFine,
        ),
        _MiniMetric(
          label: 'Fine Received',
          value: _weight(payment.fineReceived),
          tone: hasInput
              ? SilverStockColors.accentMetal
              : SilverStockColors.textHint,
        ),
        _MiniMetric(
          label: payment.isExtraMetal
              ? 'Extra Fine'
              : payment.isDueMetal
                  ? 'Short Fine'
                  : 'Fine Difference',
          value: _weight(payment.fineDifference.abs()),
          caption: _money(payment.differenceInCashValue),
          tone: hasInput ? diffTone : SilverStockColors.paymentNeutral,
        ),
      ],
    );
  }
}

class _MetalSettlementChoice extends StatelessWidget {
  final SilverPaymentController payment;

  const _MetalSettlementChoice({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isReturn = payment.isExtraMetal;
    final tone = isReturn
        ? SilverStockColors.paymentReturn
        : SilverStockColors.paymentDue;
    final title = isReturn ? 'Extra metal handling' : 'Short fine handling';
    final metalLabel = isReturn ? 'Return Fine' : 'Keep Fine Due';
    final cashLabel = isReturn ? 'Return Value' : 'Convert to Cash Due';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: tone,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoicePill(
                  label: metalLabel,
                  icon: SilverStockIcons.fineWeight,
                  active: payment.metalDueReturnType == DueReturnType.metal,
                  color: tone,
                  onTap: () =>
                      payment.setMetalDueReturnType(DueReturnType.metal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoicePill(
                  label: cashLabel,
                  icon: SilverStockIcons.amountReceived,
                  active: payment.metalDueReturnType == DueReturnType.cash,
                  color: tone,
                  onTap: () =>
                      payment.setMetalDueReturnType(DueReturnType.cash),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashTargetNote extends StatelessWidget {
  final SilverPaymentController payment;

  const _CashTargetNote({required this.payment});

  @override
  Widget build(BuildContext context) {
    final title = payment.paymentMode == PaymentMode.metalToMetal
        ? 'Cash side target'
        : 'Payable target';
    final subtitle = payment.paymentMode == PaymentMode.metalToMetal
        ? 'Making, GST and cash-converted short fine are settled here.'
        : 'Full bill amount is settled here.';
    final breakdown = payment.paymentMode == PaymentMode.metalToMetal
        ? [
            if (payment.isDueMetal &&
                payment.metalDueReturnType == DueReturnType.cash)
              _TargetLine(
                label: 'Short fine value',
                value: _money(payment.fineShortageValue),
              ),
            _TargetLine(
              label: 'Making',
              value: _money(payment.totalMakingFromItems),
            ),
            if (payment.taxAmount > 0)
              _TargetLine(
                label: 'GST ${payment.taxPercentage.toStringAsFixed(2)}%',
                value: _money(payment.taxAmount),
              ),
          ]
        : [
            _TargetLine(
              label: 'Fine value',
              value: _money(payment.fineValueAmount),
            ),
            _TargetLine(
              label: 'Making',
              value: _money(payment.totalMakingFromItems),
            ),
            if (payment.taxAmount > 0)
              _TargetLine(
                label: 'GST ${payment.taxPercentage.toStringAsFixed(2)}%',
                value: _money(payment.taxAmount),
              ),
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _IconBox(
                icon: SilverStockIcons.payable,
                color: SilverStockColors.paymentPrimary,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: SilverStockColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SilverStockColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _money(payment.cashTargetAmount),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.paymentPrimary,
                ),
              ),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const Divider(height: 18, color: SilverStockColors.cardBorder),
            ...breakdown,
          ],
          if (payment.cashBankPaidTotal > 0) ...[
            const Divider(height: 18, color: SilverStockColors.cardBorder),
            _TargetLine(
              label: 'Paid',
              value: _money(payment.cashBankPaidTotal),
              valueColor: SilverStockColors.success,
            ),
            _TargetLine(
              label: 'Cash due now',
              value: _money(payment.cashDueBeforePayment),
              valueColor: payment.cashDueBeforePayment > 0
                  ? SilverStockColors.paymentDue
                  : SilverStockColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TargetLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SilverStockColors.textBody,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: valueColor ?? SilverStockColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashSplitFields extends StatelessWidget {
  final SilverPaymentController payment;

  const _CashSplitFields({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fields = [
      _PaymentInput(
        label: SilverStockStrings.cashLabel,
        hint: '0.00',
        icon: SilverStockIcons.cashPayment,
        controller: payment.cashCtrl,
      ),
      _PaymentInput(
        label: SilverStockStrings.upiLabel,
        hint: '0.00',
        icon: SilverStockIcons.upi,
        controller: payment.upiCtrl,
      ),
      _PaymentInput(
        label: SilverStockStrings.bankLabel,
        hint: '0.00',
        icon: SilverStockIcons.bank,
        controller: payment.bankCtrl,
      ),
      _PaymentInput(
        label: SilverStockStrings.cardLabel,
        hint: '0.00',
        icon: SilverStockIcons.cardPayment,
        controller: payment.cardCtrl,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - ((columns - 1) * gap)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: fields
              .map((field) => SizedBox(width: width, child: field))
              .toList(growable: false),
        );
      },
    );
  }
}

class _FinalSettlementCard extends StatelessWidget {
  final SilverPaymentSnapshot snapshot;
  final SilverPaymentController payment;

  const _FinalSettlementCard({required this.snapshot, required this.payment});

  @override
  Widget build(BuildContext context) {
    final hasInvoice = snapshot.totalBillAmount > 0;
    final tone = !hasInvoice
        ? SilverStockColors.paymentNeutral
        : snapshot.hasReturn
            ? SilverStockColors.paymentReturn
            : snapshot.hasDue
                ? SilverStockColors.paymentDue
                : SilverStockColors.success;
    final title = !hasInvoice
        ? 'Awaiting invoice lines'
        : snapshot.hasReturn
            ? snapshot.balanceLabel
            : snapshot.hasDue
                ? snapshot.balanceLabel
                : SilverStockStrings.settlementCompleteLabel;
    final amount = snapshot.hasReturn
        ? snapshot.returnAmount
        : snapshot.hasDue
            ? snapshot.dueAmount
            : 0.0;
    final icon = snapshot.hasReturn
        ? SilverStockIcons.returnBalance
        : snapshot.hasDue
            ? SilverStockIcons.dueBalance
            : SilverStockIcons.available;
    final summaryText = _settlementSummary(snapshot, payment);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.26), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: tone, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: tone,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      summaryText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SilverStockColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                snapshot.isSettled ? 'OK' : _money(amount),
                style: GoogleFonts.manrope(
                  fontSize: snapshot.isSettled ? 22 : 20,
                  fontWeight: FontWeight.w900,
                  color: tone,
                ),
              ),
            ],
          ),
          if (snapshot.hasDue) ...[
            const Divider(height: 24, color: SilverStockColors.cardBorder),
            _PromiseDateRow(payment: payment, tone: tone),
          ],
        ],
      ),
    );
  }
}

class _PromiseDateRow extends StatelessWidget {
  final SilverPaymentController payment;
  final Color tone;

  const _PromiseDateRow({required this.payment, required this.tone});

  @override
  Widget build(BuildContext context) {
    final date = payment.promiseDate;
    final label = date == null
        ? 'Set Promise Date'
        : DateFormat('dd MMM yyyy').format(date);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? now,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                payment.setPromiseDate(picked);
              }
            },
            icon: Icon(Icons.event_available_rounded, size: 16, color: tone),
            label: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: tone,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: tone.withValues(alpha: 0.28)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            ),
          ),
        ),
        if (date != null) ...[
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Clear promise date',
            onPressed: () => payment.setPromiseDate(null),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: SilverStockColors.textMuted,
          ),
        ],
      ],
    );
  }
}

String _settlementSummary(
  SilverPaymentSnapshot snapshot,
  SilverPaymentController payment,
) {
  if (snapshot.paymentMode == PaymentMode.cash) {
    return 'Cash paid ${_money(snapshot.cashBankPaidTotal)} against bill ${_money(snapshot.totalBillAmount)}';
  }

  if (snapshot.hasDue &&
      snapshot.settlementPreference == DueReturnType.metal &&
      snapshot.metalFineShortage > 0) {
    final cashDue = payment.cashDueBeforePayment;
    final cashPart = cashDue > 0 ? ' | cash due ${_money(cashDue)}' : '';
    return 'Fine due ${_weight(snapshot.metalFineShortage)}$cashPart';
  }

  if (snapshot.hasReturn &&
      snapshot.settlementPreference == DueReturnType.metal &&
      snapshot.metalFineExcess > 0) {
    return 'Return fine ${_weight(snapshot.metalFineExcess)} | cash paid ${_money(snapshot.cashBankPaidTotal)}';
  }

  return 'Fine received ${_weight(snapshot.metalFineCalculated)} | cash paid ${_money(snapshot.cashBankPaidTotal)}';
}

class _SectionShell extends StatelessWidget {
  final Widget child;

  const _SectionShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, color: SilverStockColors.paymentPrimary, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _PaymentModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = active ? color : SilverStockColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: active ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tone.withValues(alpha: active ? 0.34 : 0.16),
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, color: tone, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: active ? color : SilverStockColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: SilverStockColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: tone,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = active ? color : SilverStockColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: active ? 0.10 : 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tone.withValues(alpha: active ? 0.34 : 0.16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInput extends StatelessWidget {
  final String label;
  final String hint;
  final String? suffixText;
  final IconData icon;
  final TextEditingController controller;

  const _PaymentInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.suffixText,
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
            letterSpacing: 0.8,
            color: SilverStockColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixText: suffixText == '/kg' ? 'Rs ' : null,
              suffixText: suffixText,
              prefixIcon: Icon(
                icon,
                size: 17,
                color: SilverStockColors.textMuted,
              ),
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: SilverStockColors.textHint,
              ),
              filled: true,
              fillColor: SilverStockColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SilverStockColors.cardBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SilverStockColors.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SilverStockColors.brandSilver,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color tone;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.tone,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 142),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: tone,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: SilverStockColors.textDark,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 3),
            Text(
              caption!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SilverStockColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  const _StatementRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: emphasized ? 13 : 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: SilverStockColors.textBody,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: emphasized ? 18 : 14,
              fontWeight: FontWeight.w900,
              color: valueColor ?? SilverStockColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }
}

String _money(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

String _weight(double value) => '${value.toStringAsFixed(3)} g';
