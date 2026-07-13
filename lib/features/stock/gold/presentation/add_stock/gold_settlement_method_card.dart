import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_payment_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldSettlementMethodCard extends StatefulWidget {
  final GoldStockController ctrl;

  const GoldSettlementMethodCard({super.key, required this.ctrl});

  @override
  State<GoldSettlementMethodCard> createState() =>
      _GoldSettlementMethodCardState();
}

class _GoldSettlementMethodCardState extends State<GoldSettlementMethodCard> {
  bool _metalLineScheduled = false;

  GoldPaymentController get payment => widget.ctrl.payment;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.ctrl, payment]),
      builder: (context, _) {
        _ensureMetalLineWhenNeeded();

        return _GoldCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: GoldStockIcons.metalExchange,
                title: '5. Settlement Method',
                subtitle: 'Choose metal, cash or mixed supplier settlement.',
              ),
              const Divider(height: 1, color: GoldStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettlementModeTabs(payment: payment),
                    const SizedBox(height: 14),
                    _SettlementDiscountPanel(payment: payment),
                    const SizedBox(height: 14),
                    if (payment.paymentMode == PaymentMode.metalToMetal)
                      _MetalSettlementBoard(payment: payment)
                    else
                      _CashSettlementBoard(payment: payment),
                    const SizedBox(height: 14),
                    _CashSplitGrid(payment: payment),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureMetalLineWhenNeeded() {
    if (payment.paymentMode != PaymentMode.metalToMetal ||
        payment.metalLines.isNotEmpty ||
        _metalLineScheduled) {
      return;
    }

    _metalLineScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      payment.addMetalLine();
      _metalLineScheduled = false;
    });
  }
}

class _SettlementDiscountPanel extends StatelessWidget {
  final GoldPaymentController payment;

  const _SettlementDiscountPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fineMode = payment.discountMode == GoldDiscountMode.fine;
    final appliedValue = fineMode
        ? '${payment.fineDiscountWeight.toStringAsFixed(3)} g'
        : _money(payment.cashDiscountAmount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GoldStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 820;
          const title = _SettlementDiscountTitle();
          final modeSelector = _DiscountTypeSelector(
            fineMode: fineMode,
            onFineTap: () => payment.setDiscountMode(GoldDiscountMode.fine),
            onCashTap: () => payment.setDiscountMode(GoldDiscountMode.cash),
          );
          final input = _SettlementInput(
            label: fineMode ? 'Discount Fine' : 'Discount Amount',
            controller: payment.discountCtrl,
            prefixText: fineMode ? null : 'Rs ',
            suffixText: fineMode ? 'g' : null,
            icon: Icons.discount_rounded,
          );
          final summary = _AppliedDiscountTile(value: appliedValue);

          if (stacked) {
            return Column(
              children: [
                title,
                const SizedBox(height: 10),
                modeSelector,
                const SizedBox(height: 10),
                input,
                const SizedBox(height: 10),
                summary,
              ],
            );
          }

          return Row(
            children: [
              const SizedBox(width: 230, child: _SettlementDiscountTitle()),
              const SizedBox(width: 12),
              Expanded(flex: 11, child: modeSelector),
              const SizedBox(width: 12),
              Expanded(flex: 8, child: input),
              const SizedBox(width: 12),
              Expanded(flex: 7, child: summary),
            ],
          );
        },
      ),
    );
  }
}

class _SettlementDiscountTitle extends StatelessWidget {
  const _SettlementDiscountTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: GoldStockColors.brandGoldLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GoldStockColors.brandGoldBorder),
          ),
          child: const Icon(
            Icons.discount_rounded,
            size: 16,
            color: GoldStockColors.brandGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vendor Discount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: GoldStockColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fine or cash settlement adjustment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: GoldStockColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscountTypeSelector extends StatelessWidget {
  final bool fineMode;
  final VoidCallback onFineTap;
  final VoidCallback onCashTap;

  const _DiscountTypeSelector({
    required this.fineMode,
    required this.onFineTap,
    required this.onCashTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Discount Type'),
        const SizedBox(height: 7),
        Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: GoldStockColors.cardBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: GoldStockColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DiscountModeButton(
                  label: 'Fine Discount',
                  active: fineMode,
                  onTap: onFineTap,
                ),
              ),
              Expanded(
                child: _DiscountModeButton(
                  label: 'Cash Discount',
                  active: !fineMode,
                  onTap: onCashTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscountModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DiscountModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? GoldStockColors.brandGold : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : GoldStockColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppliedDiscountTile extends StatelessWidget {
  final String value;

  const _AppliedDiscountTile({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Applied Discount'),
        const SizedBox(height: 7),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: GoldStockColors.cardBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: GoldStockColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: GoldStockColors.brandGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
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

class _SettlementModeTabs extends StatelessWidget {
  final GoldPaymentController payment;

  const _SettlementModeTabs({required this.payment});

  @override
  Widget build(BuildContext context) {
    final mixedActive = payment.paymentMode == PaymentMode.metalToMetal &&
        payment.cashBankPaidTotal > 0;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GoldStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Metal to Metal',
              icon: GoldStockIcons.metalExchange,
              active: payment.paymentMode == PaymentMode.metalToMetal &&
                  !mixedActive,
              onTap: () => payment.setPaymentMode(PaymentMode.metalToMetal),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Cash / Bank',
              icon: GoldStockIcons.cashPayment,
              active: payment.paymentMode == PaymentMode.cash,
              onTap: () => payment.setPaymentMode(PaymentMode.cash),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Mixed Settlement',
              icon: Icons.compare_arrows_rounded,
              active: mixedActive,
              onTap: () => payment.setPaymentMode(PaymentMode.metalToMetal),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? GoldStockColors.brandGold : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : GoldStockColors.textMuted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : GoldStockColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetalSettlementBoard extends StatelessWidget {
  final GoldPaymentController payment;

  const _MetalSettlementBoard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final line = payment.metalLines.isEmpty ? null : payment.metalLines.first;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GoldStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 820;
              final fields = [
                line == null
                    ? _AddMetalLineButton(payment: payment)
                    : _SettlementInput(
                        label: 'Metal Given',
                        controller: line.grossCtrl,
                        suffixText: 'g',
                        icon: GoldStockIcons.weight,
                      ),
                line == null
                    ? const SizedBox.shrink()
                    : _SettlementInput(
                        label: 'Purity',
                        controller: line.purityCtrl,
                        suffixText: '%',
                        icon: GoldStockIcons.purity,
                      ),
                _ReadOnlyValue(
                  label: 'Fine Received',
                  value: '${payment.fineReceived.toStringAsFixed(3)} g',
                  tone: GoldStockColors.success,
                  icon: GoldStockIcons.fineWeight,
                ),
                _ReadOnlyValue(
                  label: 'Short Fine',
                  value: '${payment.fineShortage.toStringAsFixed(3)} g',
                  tone: payment.fineShortage > 0
                      ? GoldStockColors.danger
                      : GoldStockColors.success,
                  icon: GoldStockIcons.dueBalance,
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++)
                      if (fields[i] is! SizedBox)
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
                    if (fields[i] is! SizedBox)
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
          const SizedBox(height: 12),
          _ShortFineHandling(payment: payment),
        ],
      ),
    );
  }
}

class _CashSettlementBoard extends StatelessWidget {
  final GoldPaymentController payment;

  const _CashSettlementBoard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _ReadOnlyValue(
              label: 'Final Bill Amount',
              value: _money(payment.finalBillAmount),
              tone: GoldStockColors.paymentPrimary,
              icon: GoldStockIcons.payable,
            ),
            _ReadOnlyValue(
              label: 'Total Received',
              value: _money(payment.cashBankPaidTotal),
              tone: GoldStockColors.success,
              icon: GoldStockIcons.amountReceived,
            ),
            _ReadOnlyValue(
              label: payment.balanceLabel,
              value: payment.hasReturn
                  ? _money(payment.returnAmount)
                  : _money(payment.dueAmount),
              tone: payment.hasDue
                  ? GoldStockColors.danger
                  : GoldStockColors.success,
              icon: payment.hasReturn
                  ? GoldStockIcons.returnBalance
                  : GoldStockIcons.dueBalance,
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
    );
  }
}

class _ShortFineHandling extends StatelessWidget {
  final GoldPaymentController payment;

  const _ShortFineHandling({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Short Fine Handling',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: GoldStockColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ChoiceButton(
            label: 'Keep Fine Due',
            active: payment.metalDueReturnType == DueReturnType.metal,
            onTap: () => payment.setMetalDueReturnType(DueReturnType.metal),
          ),
          const SizedBox(width: 8),
          _ChoiceButton(
            label: 'Convert to Cash Due',
            active: payment.metalDueReturnType == DueReturnType.cash,
            onTap: () => payment.setMetalDueReturnType(DueReturnType.cash),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : GoldStockColors.paymentPrimary,
        backgroundColor:
            active ? GoldStockColors.paymentPrimary : GoldStockColors.cardBg,
        side: BorderSide(
          color: GoldStockColors.paymentPrimary.withValues(alpha: 0.36),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CashSplitGrid extends StatelessWidget {
  final GoldPaymentController payment;

  const _CashSplitGrid({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fields = [
      _SettlementInput(
        label: 'Cash',
        controller: payment.cashCtrl,
        prefixText: 'Rs ',
        icon: GoldStockIcons.cashPayment,
      ),
      _SettlementInput(
        label: 'UPI',
        controller: payment.upiCtrl,
        prefixText: 'Rs ',
        icon: GoldStockIcons.upi,
      ),
      _SettlementInput(
        label: 'Bank Transfer',
        controller: payment.bankCtrl,
        prefixText: 'Rs ',
        icon: GoldStockIcons.bank,
      ),
      _SettlementInput(
        label: 'Card',
        controller: payment.cardCtrl,
        prefixText: 'Rs ',
        icon: GoldStockIcons.cardPayment,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
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

class _SettlementInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final String? suffixText;
  final IconData icon;

  const _SettlementInput({
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
              color: GoldStockColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: prefixText,
              suffixText: suffixText,
              prefixIcon:
                  Icon(icon, size: 16, color: GoldStockColors.textMuted),
              filled: true,
              fillColor: GoldStockColors.cardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                borderSide: const BorderSide(
                  color: GoldStockColors.brandGold,
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

class _ReadOnlyValue extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final IconData icon;

  const _ReadOnlyValue({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
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
            color: tone.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: tone.withValues(alpha: 0.18)),
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
                    color: tone,
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

class _AddMetalLineButton extends StatelessWidget {
  final GoldPaymentController payment;

  const _AddMetalLineButton({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Metal Given'),
        const SizedBox(height: 7),
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: payment.addMetalLine,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add Metal Line'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GoldStockColors.paymentPrimary,
              side: BorderSide(
                color: GoldStockColors.paymentPrimary.withValues(alpha: 0.32),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
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
        color: GoldStockColors.textMuted,
      ),
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

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  ).format(value);
}
