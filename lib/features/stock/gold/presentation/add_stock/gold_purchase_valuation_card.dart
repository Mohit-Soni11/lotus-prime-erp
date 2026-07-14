import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldPurchaseValuationCard extends StatelessWidget {
  final GoldStockController ctrl;

  const GoldPurchaseValuationCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final payment = ctrl.payment;
        final actualFine = ctrl.totalActualFineWeight;
        final valuationFine = ctrl.totalValuationFineWeight;
        final finalAmount = payment.finalBillAmount;

        return _GoldCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: GoldStockIcons.rateChart,
                title: '4. Purchase Valuation',
                subtitle: 'Rate, fine weight, making and final vendor value.',
              ),
              const Divider(height: 1, color: GoldStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 860;
                        final children = [
                          _RateInput(
                            label: '24K Rate / 10g',
                            controller: payment.todayRatePer10gCtrl,
                            icon: GoldStockIcons.rateChart,
                            prefixText: 'Rs ',
                            suffixText: '/10g',
                          ),
                          _ReadOnlyMetric(
                            label: 'Rate / Gram',
                            value: _money(payment.todayRatePerGram),
                            icon: GoldStockIcons.price,
                            tone: GoldStockColors.paymentPrimary,
                          ),
                          _ReadOnlyMetric(
                            label: 'Making Charges',
                            value: _money(payment.totalMakingFromItems),
                            icon: GoldStockIcons.makingCharges,
                            tone: GoldStockColors.textDark,
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
                              for (var i = 0; i < children.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == children.length - 1 ? 0 : 10,
                                  ),
                                  child: children[i],
                                ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            for (var i = 0; i < children.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i == children.length - 1 ? 0 : 12,
                                  ),
                                  child: children[i],
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
                        color: GoldStockColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GoldStockColors.cardBorder),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 620;
                          final cards = [
                            _SummaryTile(
                              label: 'Actual Fine Total',
                              value: '${actualFine.toStringAsFixed(3)} g',
                              icon: GoldStockIcons.fineWeight,
                              tone: GoldStockColors.success,
                            ),
                            _SummaryTile(
                              label: 'Valuation Fine Total',
                              value: '${valuationFine.toStringAsFixed(3)} g',
                              icon: GoldStockIcons.rateChart,
                              tone: GoldStockColors.brandGold,
                            ),
                            _SummaryTile(
                              label: 'Making Total',
                              value: _money(payment.totalMakingFromItems),
                              icon: GoldStockIcons.makingCharges,
                              tone: GoldStockColors.textDark,
                            ),
                            if (ctrl.gstEnabled)
                              _SummaryTile(
                                label: 'GST Total',
                                value: _money(payment.taxAmount),
                                icon: Icons.receipt_long_rounded,
                                tone: GoldStockColors.paymentReturn,
                              ),
                            _SummaryTile(
                              label: 'Final Purchase Amount',
                              value: _money(finalAmount),
                              icon: GoldStockIcons.payable,
                              tone: GoldStockColors.paymentPrimary,
                              emphasized: true,
                            ),
                          ];

                          if (stacked) {
                            return Column(
                              children: [
                                for (var i = 0; i < cards.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == cards.length - 1 ? 0 : 10,
                                    ),
                                    child: cards[i],
                                  ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (var i = 0; i < cards.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i == cards.length - 1 ? 0 : 12,
                                    ),
                                    child: cards[i],
                                  ),
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

class _GoldCardShell extends StatelessWidget {
  final Widget child;

  const _GoldCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GoldStockColors.shadowLight,
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
              color: GoldStockColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: GoldStockColors.brandGoldBorder),
            ),
            child: Icon(icon, size: 16, color: GoldStockColors.brandGold),
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
                    color: GoldStockColors.textDark,
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
                    color: GoldStockColors.textMuted,
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
        _MetricLabel(label),
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: GoldStockColors.textDark,
            ),
            decoration: _inputDecoration(
              icon: icon,
              hint: '0.00',
              prefixText: prefixText,
              suffixText: suffixText,
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
        _MetricLabel(label),
        const SizedBox(height: 7),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: GoldStockColors.inputBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: GoldStockColors.cardBorder),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: GoldStockColors.textDark,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: emphasized ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: GoldStockColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: emphasized ? 18 : 16,
                    fontWeight: FontWeight.w900,
                    color: tone,
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

class _MetricLabel extends StatelessWidget {
  final String text;

  const _MetricLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: GoldStockColors.textMuted,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required IconData icon,
  required String hint,
  String? prefixText,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    suffixText: suffixText,
    prefixIcon: Icon(icon, size: 16, color: GoldStockColors.brandGold),
    filled: true,
    fillColor: GoldStockColors.cardBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: GoldStockColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: GoldStockColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide:
          const BorderSide(color: GoldStockColors.brandGold, width: 1.4),
    ),
  );
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  ).format(value);
}
