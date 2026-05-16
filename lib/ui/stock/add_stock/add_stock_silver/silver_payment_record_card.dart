import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

const _kSilverAccent = Color(0xFF71889A);
const _kFineTone = Color(0xFF476C7D);
const _kReturnTone = Color(0xFF0F9D8A);
const _kDueTone = Color(0xFFE05D44);
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
        final totalFine = ctrl.totalFineWeight;
        final making = ctrl.totalMakingAmount;
        final gstEnabled = ctrl.gstEnabled;
        final totalBill = payment.totalBillAmount(
          totalFineGrams: totalFine,
          makingAmount: making,
          gstEnabled: gstEnabled,
        );
        final due = payment.dueAmount(
          totalFineGrams: totalFine,
          makingAmount: making,
          gstEnabled: gstEnabled,
        );
        final refund = payment.returnAmount(
          totalFineGrams: totalFine,
          makingAmount: making,
          gstEnabled: gstEnabled,
        );
        final hasSettlementBase = totalFine > 0 && payment.hasRate;
        final status = _statusFor(
          hasSettlementBase: hasSettlementBase,
          totalPaid: payment.totalPaidValue,
          due: due,
          refund: refund,
        );

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
              _CardHeader(status: status, gstEnabled: gstEnabled),
              _divider(),
              _TodayRateSection(ctrl: ctrl, payment: payment),
              if (!hasSettlementBase) ...[
                const SizedBox(height: 16),
                _SetupPrompt(hasFine: totalFine > 0, hasRate: payment.hasRate),
              ] else ...[
                const SizedBox(height: 16),
                _InvoiceBreakdownSection(
                  payment: payment,
                  totalFine: totalFine,
                  making: making,
                  gstEnabled: gstEnabled,
                ),
                const SizedBox(height: 16),
                _PaymentModeSection(payment: payment),
                const SizedBox(height: 14),
                _SettlementInputSection(payment: payment, totalFine: totalFine),
                const SizedBox(height: 14),
                _GstBreakdownSection(
                  payment: payment,
                  totalFine: totalFine,
                  making: making,
                  gstEnabled: gstEnabled,
                ),
                const SizedBox(height: 14),
                _SettlementSummarySection(
                  payment: payment,
                  totalFine: totalFine,
                  making: making,
                  gstEnabled: gstEnabled,
                  totalBill: totalBill,
                  due: due,
                  refund: refund,
                ),
                if (refund > 0) ...[
                  const SizedBox(height: 14),
                  _ReturnDecisionSection(
                    payment: payment,
                    totalFine: totalFine,
                    making: making,
                    gstEnabled: gstEnabled,
                  ),
                ] else if (due > 0) ...[
                  const SizedBox(height: 14),
                  _DueDecisionSection(
                    payment: payment,
                    totalFine: totalFine,
                    making: making,
                    gstEnabled: gstEnabled,
                  ),
                ],
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

  const _CardHeader({required this.status, required this.gstEnabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _accentLine(22, _kSilverAccent, 1.0),
                  const SizedBox(height: 3),
                  _accentLine(14, _kSilverAccent, 0.42),
                  const SizedBox(height: 3),
                  _accentLine(8, _kSilverAccent, 0.18),
                ],
              ),
              const SizedBox(width: 12),
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
                          ? 'GST settlement with metal 5% and cash 3% logic'
                          : 'Non-GST settlement with metal and cash balancing',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AddStockColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _BadgePill(
              label: gstEnabled ? 'GST MODE' : 'WITHOUT GST',
              color: gstEnabled ? AddStockColors.success : _kSilverAccent,
            ),
            _BadgePill(label: status.label, color: status.color),
          ],
        ),
      ],
    );
  }

  Widget _accentLine(double width, Color color, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _TodayRateSection extends StatelessWidget {
  final SilverStockController ctrl;
  final SilverPaymentController payment;

  const _TodayRateSection({required this.ctrl, required this.payment});

  @override
  Widget build(BuildContext context) {
    final marketDate = ctrl.silverRateDate == null
        ? 'Snapshot unavailable'
        : 'Snapshot ${DateFormat('dd MMM yyyy').format(ctrl.silverRateDate!)}';
    final snapshotRate = ctrl.hasSilverRateSnapshot
        ? 'Market ref ${_money(ctrl.silverRatePerGram)} / g'
        : 'Enter today\'s silver rate manually';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'TODAY\'S SILVER RATE',
          subtitle: '$marketDate  -  $snapshotRate',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 700;
            final rateField = _NumberInputField(
              controller: payment.ratePerKgCtrl,
              label: 'PER KG',
              hint: ctrl.hasSilverRateSnapshot
                  ? (ctrl.silverRatePerGram * 1000).toStringAsFixed(0)
                  : '90000',
              prefixIcon: Icons.currency_rupee_rounded,
              suffix: '/ kg',
            );

            final perGram = _MetricTile(
              label: 'PER GRAM',
              value: payment.ratePerGramDisplay,
              caption: 'Auto-calculated',
              tone: _kSilverAccent,
              icon: Icons.scale_rounded,
            );

            final market = _MetricTile(
              label: 'MARKET SNAPSHOT',
              value: ctrl.hasSilverRateSnapshot
                  ? '${_money(ctrl.silverRatePerGram)} / g'
                  : '--',
              caption: ctrl.hasSilverRateSnapshot
                  ? 'Loaded from daily rate table'
                  : 'No stored market rate',
              tone: AddStockColors.accentCompliance,
              icon: Icons.track_changes_rounded,
            );

            if (stacked) {
              return Column(
                children: [
                  rateField,
                  const SizedBox(height: 10),
                  perGram,
                  const SizedBox(height: 10),
                  market,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 4, child: rateField),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: perGram),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: market),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  final bool hasFine;
  final bool hasRate;

  const _SetupPrompt({required this.hasFine, required this.hasRate});

  @override
  Widget build(BuildContext context) {
    String text;
    if (!hasFine && !hasRate) {
      text = 'Invoice items fill karte hi total fine aayega. Uske baad per kg '
          'rate ready rahega aur yahi card full payment settlement dikhaega.';
    } else if (!hasFine) {
      text = 'Rate ready hai. Ab invoice items add karte hi total fine, making '
          'aur total bill yahan calculate ho jayega.';
    } else {
      text = 'Total fine ready hai. Final settlement dekhne ke liye per kg '
          'rate confirm karo.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kSilverAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 18,
              color: _kSilverAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: AddStockColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceBreakdownSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;
  final double making;
  final bool gstEnabled;

  const _InvoiceBreakdownSection({
    required this.payment,
    required this.totalFine,
    required this.making,
    required this.gstEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final fineAmount = payment.fineAmount(totalFine);
    final totalBill = payment.totalBillAmount(
      totalFineGrams: totalFine,
      makingAmount: making,
      gstEnabled: gstEnabled,
    );
    final gstAmount = payment.metalGstAmount(
          gstEnabled: gstEnabled,
          totalFineGrams: totalFine,
        ) +
        payment.cashGstAmount(
          gstEnabled: gstEnabled,
          totalFineGrams: totalFine,
          makingAmount: making,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'INVOICE SETTLEMENT PREVIEW',
          subtitle:
              'Total fine, rate, making aur final bill amount ek jagah par',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 5
                : constraints.maxWidth >= 680
                    ? 3
                    : 1;
            final spacing = 10.0;
            final width =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            final tiles = [
              _MetricTile(
                label: 'TOTAL FINE',
                value: '${totalFine.toStringAsFixed(3)} g',
                caption: 'Combined from invoice items',
                tone: _kFineTone,
                icon: Icons.balance_rounded,
              ),
              _MetricTile(
                label: 'FINE VALUE',
                value: _money(fineAmount),
                caption:
                    '${totalFine.toStringAsFixed(3)} g x ${payment.ratePerGramDisplay}',
                tone: _kSilverAccent,
                icon: Icons.currency_rupee_rounded,
              ),
              _MetricTile(
                label: 'RATE / G',
                value: payment.ratePerGramDisplay,
                caption: payment.ratePerKgDisplay,
                tone: AddStockColors.accentCompliance,
                icon: Icons.sell_rounded,
              ),
              _MetricTile(
                label: 'MAKING',
                value: _money(making),
                caption: 'Invoice making total',
                tone: AddStockColors.accentPricing,
                icon: Icons.build_circle_rounded,
              ),
              _MetricTile(
                label: gstEnabled ? 'TOTAL BILL' : 'TOTAL BILL',
                value: _money(totalBill),
                caption: gstEnabled
                    ? 'Incl. GST ${_money(gstAmount)}'
                    : 'Without GST adjustment',
                tone: AddStockColors.success,
                icon: Icons.receipt_long_rounded,
                highlighted: true,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tiles
                  .map((tile) => SizedBox(width: width, child: tile))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentModeSection extends StatelessWidget {
  final SilverPaymentController payment;

  const _PaymentModeSection({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'SETTLEMENT MODES',
          subtitle:
              'Metal adjustment aur cash/UPI/bank/card split ko select karo',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: SilverPaymentMode.values
              .map(
                (mode) => _ModeToggleChip(
                  mode: mode,
                  isEnabled: payment.isModeEnabled(mode),
                  onTap: () => payment.toggleMode(mode),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SettlementInputSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _SettlementInputSection({
    required this.payment,
    required this.totalFine,
  });

  @override
  Widget build(BuildContext context) {
    final enabledCashModes = SilverPaymentMode.values
        .where((mode) => mode != SilverPaymentMode.metalToMetal)
        .where(payment.isModeEnabled)
        .toList(growable: false);
    final metalEnabled = payment.isModeEnabled(SilverPaymentMode.metalToMetal);

    if (!metalEnabled && enabledCashModes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AddStockColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AddStockColors.cardBorder),
        ),
        child: Text(
          'Upar se ek ya zyada settlement mode select karo. Metal to Metal se '
          'fine adjust hoga aur cash modes se residual payment record hoga.',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: AddStockColors.textBody,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (metalEnabled) ...[
          _MetalAdjustmentSection(payment: payment, totalFine: totalFine),
          if (enabledCashModes.isNotEmpty) const SizedBox(height: 12),
        ],
        if (enabledCashModes.isNotEmpty)
          _CashSettlementSection(
            payment: payment,
            enabledModes: enabledCashModes,
          ),
      ],
    );
  }
}

class _MetalAdjustmentSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _MetalAdjustmentSection({
    required this.payment,
    required this.totalFine,
  });

  @override
  Widget build(BuildContext context) {
    final extraFine = payment.extraFineGrams(totalFine);
    final shortFine = payment.shortFineGrams(totalFine);
    final matchedFine = payment.matchedMetalFineGrams(totalFine);
    final matchedValue = payment.matchedMetalValue(totalFine);
    final statusColor = extraFine > 0
        ? _kReturnTone
        : shortFine > 0
            ? _kDueTone
            : AddStockColors.success;
    final statusText = extraFine > 0
        ? 'EXTRA FINE'
        : shortFine > 0
            ? 'SHORT FINE'
            : 'FINE MATCHED';
    final statusCaption = extraFine > 0
        ? '${extraFine.toStringAsFixed(3)} g above target'
        : shortFine > 0
            ? '${shortFine.toStringAsFixed(3)} g still pending'
            : 'Metal fine matched the invoice target';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSilverAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSilverAccent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'METAL TO METAL ADJUSTMENT',
            subtitle:
                'Yahan woh metal dalo jo supplier payment me diya ja raha hai',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final grossField = _NumberInputField(
                controller: payment.metalGrossWeightCtrl,
                label: 'METAL GIVEN',
                hint: '0.000',
                prefixIcon: Icons.balance_rounded,
                suffix: 'gram',
              );
              final purityField = _NumberInputField(
                controller: payment.metalPurityCtrl,
                label: 'PURITY',
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
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 860 ? 4 : 2;
                final spacing = 10.0;
                final width =
                    (constraints.maxWidth - ((columns - 1) * spacing)) /
                        columns;

                final tiles = [
                  _MetricTile(
                    label: 'FINE REQUIRED',
                    value: '${totalFine.toStringAsFixed(3)} g',
                    caption: 'Invoice target',
                    tone: _kFineTone,
                    icon: Icons.flag_rounded,
                  ),
                  _MetricTile(
                    label: 'FINE GIVEN',
                    value:
                        '${payment.metalFineCalculated.toStringAsFixed(3)} g',
                    caption:
                        '${payment.metalGrossWeight.toStringAsFixed(3)} g x ${payment.metalPurity.toStringAsFixed(2)}%',
                    tone: _kSilverAccent,
                    icon: Icons.auto_graph_rounded,
                  ),
                  _MetricTile(
                    label: 'METAL VALUE',
                    value: _money(payment.metalFineEquivalentCash),
                    caption:
                        'Matched ${matchedFine.toStringAsFixed(3)} g = ${_money(matchedValue)}',
                    tone: AddStockColors.accentPricing,
                    icon: Icons.payments_rounded,
                  ),
                  _MetricTile(
                    label: statusText,
                    value: extraFine > 0
                        ? '+${extraFine.toStringAsFixed(3)} g'
                        : shortFine > 0
                            ? '-${shortFine.toStringAsFixed(3)} g'
                            : '0.000 g',
                    caption: statusCaption,
                    tone: statusColor,
                    icon: extraFine > 0
                        ? Icons.trending_up_rounded
                        : shortFine > 0
                            ? Icons.trending_down_rounded
                            : Icons.check_circle_rounded,
                    highlighted: true,
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: tiles
                      .map((tile) => SizedBox(width: width, child: tile))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.18)),
              ),
              child: Text(
                extraFine > 0
                    ? 'Metal payment fine bill se zyada gaya hai. Extra fine '
                        '${extraFine.toStringAsFixed(3)} g '
                        '(${_money(payment.extraFineValue(totalFine))}) show ho raha hai.'
                    : shortFine > 0
                        ? 'Metal payment se abhi bhi ${shortFine.toStringAsFixed(3)} g '
                            '(${_money(payment.shortFineValue(totalFine))}) fine equivalent '
                            'short hai.'
                        : 'Fine side perfectly adjust ho gaya hai. Ab making, GST aur cash side '
                            'summary neeche dekho.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CashSettlementSection extends StatelessWidget {
  final SilverPaymentController payment;
  final List<SilverPaymentMode> enabledModes;

  const _CashSettlementSection({
    required this.payment,
    required this.enabledModes,
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
          _SectionTitle(
            title: 'CASH SIDE SETTLEMENT',
            subtitle:
                'Residual amount ko cash, UPI, bank ya card me split karo',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 860
                  ? 4
                  : constraints.maxWidth >= 520
                      ? 2
                      : 1;
              final spacing = 10.0;
              final width =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: enabledModes
                    .map(
                      (mode) => SizedBox(
                        width: width,
                        child: _NumberInputField(
                          controller: _controllerFor(mode),
                          label: mode.shortLabel,
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
          const SizedBox(height: 12),
          _MetricTile(
            label: 'TOTAL CASH PAID',
            value: _money(payment.totalCashPaid),
            caption: 'Cash + UPI + Bank + Card',
            tone: AddStockColors.accentPricing,
            icon: Icons.account_balance_wallet_rounded,
            highlighted: true,
          ),
        ],
      ),
    );
  }

  TextEditingController _controllerFor(SilverPaymentMode mode) {
    return switch (mode) {
      SilverPaymentMode.cash => payment.cashCtrl,
      SilverPaymentMode.upi => payment.upiCtrl,
      SilverPaymentMode.banking => payment.bankingCtrl,
      SilverPaymentMode.card => payment.cardCtrl,
      SilverPaymentMode.metalToMetal => payment.cashCtrl,
    };
  }
}

class _GstBreakdownSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;
  final double making;
  final bool gstEnabled;

  const _GstBreakdownSection({
    required this.payment,
    required this.totalFine,
    required this.making,
    required this.gstEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!gstEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AddStockColors.inputBgLocked,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AddStockColors.cardBorder),
        ),
        child: Text(
          'WITHOUT GST: is settlement me GST add nahi ho raha. Fine bill + making hi final base hai.',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AddStockColors.textMuted,
          ),
        ),
      );
    }

    final metalBase = payment.matchedMetalValue(totalFine);
    final cashBase = payment.cashTaxableBase(
      totalFineGrams: totalFine,
      makingAmount: making,
    );
    final metalGst = payment.metalGstAmount(
      gstEnabled: true,
      totalFineGrams: totalFine,
    );
    final cashGst = payment.cashGstAmount(
      gstEnabled: true,
      totalFineGrams: totalFine,
      makingAmount: making,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddStockColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'GST BREAKUP',
            subtitle:
                'Metal side 5% aur cash side 3% according to your silver flow',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              final spacing = 10.0;
              final width =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              final tiles = [
                _MetricTile(
                  label: 'METAL GST 5%',
                  value: _money(metalGst),
                  caption: '${_money(metalBase)} matched metal value',
                  tone: AddStockColors.success,
                  icon: Icons.precision_manufacturing_rounded,
                ),
                _MetricTile(
                  label: 'CASH GST 3%',
                  value: _money(cashGst),
                  caption: '${_money(cashBase)} residual cash base',
                  tone: AddStockColors.accentCompliance,
                  icon: Icons.currency_exchange_rounded,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tiles
                    .map((tile) => SizedBox(width: width, child: tile))
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettlementSummarySection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;
  final double making;
  final bool gstEnabled;
  final double totalBill;
  final double due;
  final double refund;

  const _SettlementSummarySection({
    required this.payment,
    required this.totalFine,
    required this.making,
    required this.gstEnabled,
    required this.totalBill,
    required this.due,
    required this.refund,
  });

  @override
  Widget build(BuildContext context) {
    final balanceLabel = refund > 0
        ? 'SUPPLIER RETURN'
        : due > 0
            ? 'AMOUNT DUE'
            : 'BALANCED';
    final balanceValue = refund > 0
        ? _money(refund)
        : due > 0
            ? _money(due)
            : 'Settled';
    final balanceTone = refund > 0
        ? _kReturnTone
        : due > 0
            ? _kDueTone
            : AddStockColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'FINAL SETTLEMENT SUMMARY',
          subtitle:
              'Metal value fine side ko adjust karta hai, cash side baaki total ko settle karta hai',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 680
                    ? 2
                    : 1;
            final spacing = 10.0;
            final width =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            final tiles = [
              _MetricTile(
                label: 'TOTAL BILL',
                value: _money(totalBill),
                caption: gstEnabled ? 'Fine + making + GST' : 'Fine + making',
                tone: _kSilverAccent,
                icon: Icons.receipt_rounded,
              ),
              _MetricTile(
                label: 'METAL VALUE PAID',
                value: _money(payment.metalFineEquivalentCash),
                caption: payment.hasMetalCalculation
                    ? '${payment.metalFineCalculated.toStringAsFixed(3)} g fine paid'
                    : 'No metal adjustment',
                tone: _kFineTone,
                icon: Icons.balance_rounded,
              ),
              _MetricTile(
                label: 'CASH PAID',
                value: _money(payment.totalCashPaid),
                caption: 'Cash + UPI + bank + card',
                tone: AddStockColors.accentPricing,
                icon: Icons.payments_rounded,
              ),
              _MetricTile(
                label: balanceLabel,
                value: balanceValue,
                caption: refund > 0
                    ? 'Supplier should return this balance'
                    : due > 0
                        ? 'This amount is still pending'
                        : 'No due and no return pending',
                tone: balanceTone,
                icon: refund > 0
                    ? Icons.reply_rounded
                    : due > 0
                        ? Icons.pending_actions_rounded
                        : Icons.verified_rounded,
                highlighted: true,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tiles
                  .map((tile) => SizedBox(width: width, child: tile))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _DueDecisionSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;
  final double making;
  final bool gstEnabled;

  const _DueDecisionSection({
    required this.payment,
    required this.totalFine,
    required this.making,
    required this.gstEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final due = payment.dueAmount(
      totalFineGrams: totalFine,
      makingAmount: making,
      gstEnabled: gstEnabled,
    );
    final dueAsFine = payment.dueAmountAsFine(
      totalFineGrams: totalFine,
      makingAmount: making,
      gstEnabled: gstEnabled,
    );
    final shortFine = payment.shortFineGrams(totalFine);
    final fineMode = payment.dueSettleMode == DueSettleMode.asFine;

    return _DecisionCard(
      title: 'DUE DECISION',
      subtitle:
          'Bacha hua balance fine due rakhna hai ya cash due, yahan decide karo',
      tone: _kDueTone,
      children: [
        Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                label: 'Fine Due',
                caption: 'Equivalent fine record',
                icon: Icons.balance_rounded,
                selected: fineMode,
                tone: _kDueTone,
                onTap: () => payment.setDueSettleMode(DueSettleMode.asFine),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceButton(
                label: 'Cash Due',
                caption: 'Rupee receivable',
                icon: Icons.currency_rupee_rounded,
                selected: !fineMode,
                tone: _kDueTone,
                onTap: () => payment.setDueSettleMode(DueSettleMode.asCash),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DecisionResultBand(
          tone: _kDueTone,
          title: fineMode ? 'SUPPLIER DUE IN FINE' : 'SUPPLIER DUE IN CASH',
          value: fineMode ? '${dueAsFine.toStringAsFixed(3)} g' : _money(due),
          caption: fineMode
              ? 'Equivalent value ${_money(due)} at today\'s rate'
              : 'Equivalent fine ${dueAsFine.toStringAsFixed(3)} g at today\'s rate',
        ),
        if (shortFine > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Metal side par abhi bhi ${shortFine.toStringAsFixed(3)} g fine short hai. '
            'Final due amount above making aur GST ko bhi include karta hai.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: _kDueTone,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReturnDecisionSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;
  final double making;
  final bool gstEnabled;

  const _ReturnDecisionSection({
    required this.payment,
    required this.totalFine,
    required this.making,
    required this.gstEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final refund = payment.returnAmount(
      totalFineGrams: totalFine,
      makingAmount: making,
      gstEnabled: gstEnabled,
    );
    final refundAsFine = payment.returnAmountAsFine(
      totalFineGrams: totalFine,
      makingAmount: making,
      gstEnabled: gstEnabled,
    );
    final extraFine = payment.extraFineGrams(totalFine);
    final allowMetalReturn = extraFine > 0 && payment.hasRate;
    final returnMetal =
        payment.excessSettleMode == ExcessSettleMode.returnMetal;

    return _DecisionCard(
      title: 'RETURN DECISION',
      subtitle:
          'Extra settlement aaya hai. Return metal karna hai ya uska value settle karna hai?',
      tone: _kReturnTone,
      children: [
        if (allowMetalReturn) ...[
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  label: 'Return Metal',
                  caption: 'Metal wapas lena hai',
                  icon: Icons.reply_all_rounded,
                  selected: returnMetal,
                  tone: _kReturnTone,
                  onTap: () =>
                      payment.setExcessSettleMode(ExcessSettleMode.returnMetal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceButton(
                  label: 'Return Value',
                  caption: 'Cash value lena hai',
                  icon: Icons.currency_exchange_rounded,
                  selected: !returnMetal,
                  tone: _kReturnTone,
                  onTap: () => payment.setExcessSettleMode(
                    ExcessSettleMode.returnCashValue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _DecisionResultBand(
          tone: _kReturnTone,
          title: allowMetalReturn && returnMetal
              ? 'SUPPLIER SHOULD RETURN METAL'
              : 'SUPPLIER SHOULD RETURN VALUE',
          value: allowMetalReturn && returnMetal
              ? '${refundAsFine.toStringAsFixed(3)} g'
              : _money(refund),
          caption: allowMetalReturn && returnMetal
              ? 'Equivalent value ${_money(refund)}'
              : 'Equivalent metal ${refundAsFine.toStringAsFixed(3)} g',
        ),
        if (extraFine > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Fine comparison par extra ${extraFine.toStringAsFixed(3)} g show ho raha hai. '
            'Final refundable balance above making aur GST absorb hone ke baad ka net amount hai.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: _kReturnTone,
            ),
          ),
        ],
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tone;
  final List<Widget> children;

  const _DecisionCard({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DecisionResultBand extends StatelessWidget {
  final Color tone;
  final String title;
  final String value;
  final String caption;

  const _DecisionResultBand({
    required this.tone,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: tone.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tone,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
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
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color tone;
  final IconData icon;
  final bool highlighted;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.tone,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            highlighted ? tone.withValues(alpha: 0.08) : AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? tone.withValues(alpha: 0.24)
              : AddStockColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: highlighted ? tone : AddStockColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            caption,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AddStockColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final SilverPaymentMode mode;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ModeToggleChip({
    required this.mode,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isEnabled
        ? _kSilverAccent.withValues(alpha: 0.10)
        : AddStockColors.inputBg;
    final borderColor = isEnabled
        ? _kSilverAccent.withValues(alpha: 0.30)
        : AddStockColors.cardBorder;
    final textColor = isEnabled ? _kSilverAccent : AddStockColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 15, color: textColor),
            const SizedBox(width: 8),
            Text(
              mode.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kSilverAccent,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
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
    final borderColor =
        selected ? tone.withValues(alpha: 0.32) : AddStockColors.cardBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              selected ? tone.withValues(alpha: 0.09) : AddStockColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? tone : AddStockColors.textMuted,
            ),
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
                      color: selected
                          ? tone.withValues(alpha: 0.8)
                          : AddStockColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
                child: const Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
          ],
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
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
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
            fillColor: AddStockColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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

_StatusMeta _statusFor({
  required bool hasSettlementBase,
  required double totalPaid,
  required double due,
  required double refund,
}) {
  if (!hasSettlementBase) {
    return const _StatusMeta('PENDING', _kNeutralTone);
  }
  if (refund > 0) {
    return const _StatusMeta('RETURN', _kReturnTone);
  }
  if (due > 0 && totalPaid > 0) {
    return const _StatusMeta('PARTIAL', _kDueTone);
  }
  if (due > 0) {
    return const _StatusMeta('READY', _kSilverAccent);
  }
  if (totalPaid > 0) {
    return const _StatusMeta('SETTLED', AddStockColors.success);
  }
  return const _StatusMeta('READY', _kSilverAccent);
}

String _money(double amount) => _moneyFormatter.format(amount);
