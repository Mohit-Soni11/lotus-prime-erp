import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverPurchaseValuationCard extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverPurchaseValuationCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final payment = ctrl.payment;
        final actualFine = ctrl.totalActualFineWeight;
        final valuationFine = ctrl.totalValuationFineWeight;

        return _SilverCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: SilverStockIcons.rateChart,
                title: '4. Purchase Valuation',
                subtitle:
                    'Silver rate, valuation fine, making and supplier bill value.',
              ),
              const Divider(height: 1, color: SilverStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 860;
                        final fields = [
                          _RateInput(
                            label: 'Invoice Silver Rate / Kg',
                            controller: payment.todayRatePerKgCtrl,
                            icon: SilverStockIcons.rateChart,
                            prefixText: 'Rs ',
                            suffixText: '/kg',
                          ),
                          _ReadOnlyMetric(
                            label: 'Rate / Gram',
                            value: _money(payment.todayRatePerGram),
                            icon: SilverStockIcons.amountReceived,
                            tone: SilverStockColors.paymentPrimary,
                          ),
                          _ReadOnlyMetric(
                            label: 'Making Charges',
                            value: _money(payment.totalMakingFromItems),
                            icon: SilverStockIcons.makingCharges,
                            tone: SilverStockColors.textDark,
                          ),
                          if (ctrl.gstEnabled)
                            _RateInput(
                              label: 'Metal GST Rate',
                              controller: payment.metalGstPercentCtrl,
                              icon: Icons.percent_rounded,
                              suffixText: '%',
                            ),
                          if (ctrl.gstEnabled)
                            _RateInput(
                              label: 'Cash GST Rate',
                              controller: payment.cashGstPercentCtrl,
                              icon: Icons.percent_rounded,
                              suffixText: '%',
                            ),
                        ];

                        if (stacked) {
                          return Column(
                            children: [
                              for (var i = 0; i < fields.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == fields.length - 1 ? 0 : 10,
                                  ),
                                  child: fields[i],
                                ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            for (var i = 0; i < fields.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i == fields.length - 1 ? 0 : 12,
                                  ),
                                  child: fields[i],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SilverStockColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SilverStockColors.cardBorder),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _SummaryTile(
                              label: 'Actual Fine Total',
                              value: '${actualFine.toStringAsFixed(3)} g',
                              icon: SilverStockIcons.fineWeight,
                              tone: SilverStockColors.success,
                            ),
                            _SummaryTile(
                              label: 'Valuation Fine Total',
                              value: '${valuationFine.toStringAsFixed(3)} g',
                              icon: SilverStockIcons.rateChart,
                              tone: SilverStockColors.brandSilver,
                            ),
                            _SummaryTile(
                              label: 'Silver Value',
                              value: _money(payment.fineValueAmount),
                              icon: SilverStockIcons.amountReceived,
                              tone: SilverStockColors.paymentPrimary,
                            ),
                            _SummaryTile(
                              label: 'Making Total',
                              value: _money(payment.totalMakingFromItems),
                              icon: SilverStockIcons.makingCharges,
                              tone: SilverStockColors.textDark,
                            ),
                            if (ctrl.gstEnabled)
                              _SummaryTile(
                                label: 'GST Total',
                                value: _money(payment.taxAmount),
                                icon: Icons.receipt_long_rounded,
                                tone: SilverStockColors.paymentReturn,
                              ),
                            _SummaryTile(
                              label: 'Final Supplier Bill',
                              value: _money(payment.finalBillAmount),
                              icon: SilverStockIcons.payable,
                              tone: SilverStockColors.paymentPrimary,
                              emphasized: true,
                            ),
                          ];

                          final cardWidth = _summaryCardWidth(
                            constraints.maxWidth,
                          );

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final card in cards)
                                SizedBox(
                                  width: cardWidth,
                                  child: card,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

double _summaryCardWidth(double maxWidth) {
  if (maxWidth >= 720) {
    return (maxWidth - 24) / 3;
  }
  if (maxWidth >= 460) {
    return (maxWidth - 12) / 2;
  }
  return maxWidth;
}

class _SilverCardShell extends StatelessWidget {
  final Widget child;

  const _SilverCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SilverStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: SilverStockColors.brandSilverLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: SilverStockColors.brandSilverBorder),
            ),
            child: Icon(icon, size: 16, color: SilverStockColors.brandSilver),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? prefixText;
  final String? suffixText;

  const _RateInput({
    required this.label,
    required this.controller,
    required this.icon,
    this.prefixText,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: SilverStockColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: prefixText,
              suffixText: suffixText,
              prefixIcon:
                  Icon(icon, size: 16, color: SilverStockColors.textMuted),
              filled: true,
              fillColor: SilverStockColors.cardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: SilverStockColors.brandSilver,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  const _ReadOnlyMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: tone.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final bool emphasized;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: emphasized ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Tooltip(
                  message: value,
                  waitDuration: const Duration(milliseconds: 350),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: GoogleFonts.manrope(
                        fontSize: emphasized ? 15 : 14,
                        fontWeight: FontWeight.w900,
                        color: emphasized ? tone : SilverStockColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: SilverStockColors.textMuted,
      ),
    );
  }
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  ).format(value);
}
