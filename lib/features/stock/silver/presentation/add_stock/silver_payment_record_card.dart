import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_payment_controller.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverPaymentRecordCard extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverPaymentRecordCard({super.key, required this.ctrl});

  @override
  State<SilverPaymentRecordCard> createState() =>
      _SilverPaymentRecordCardState();
}

class _SilverPaymentRecordCardState extends State<SilverPaymentRecordCard> {
  bool _metalLineScheduled = false;

  SilverPaymentController get payment => widget.ctrl.payment;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.ctrl, payment]),
      builder: (context, _) {
        _ensureMetalLineWhenNeeded();

        return _SilverCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: SilverStockIcons.metalExchange,
                title: '5. Settlement Method',
                subtitle:
                    'Settle supplier using silver metal, cash or mixed payment.',
              ),
              const Divider(height: 1, color: SilverStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettlementModeTabs(payment: payment),
                    const SizedBox(height: 14),
                    _SettlementDiscountPanel(payment: payment),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: payment.usesMetalSettlement
                          ? _MetalSettlementBoard(
                              key: const ValueKey('metal-settlement'),
                              payment: payment,
                            )
                          : _CashSettlementBoard(
                              key: const ValueKey('cash-settlement'),
                              payment: payment,
                            ),
                    ),
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
    if (!payment.usesMetalSettlement ||
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

class _SettlementModeTabs extends StatelessWidget {
  final SilverPaymentController payment;

  const _SettlementModeTabs({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SettlementModeButton(
              label: 'Silver to Silver',
              icon: SilverStockIcons.metalExchange,
              selected: payment.paymentMode == PaymentMode.metalToMetal,
              onTap: () => payment.setPaymentMode(PaymentMode.metalToMetal),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SettlementModeButton(
              label: 'Cash / Bank',
              icon: SilverStockIcons.cashPayment,
              selected: payment.paymentMode == PaymentMode.cash,
              onTap: () => payment.setPaymentMode(PaymentMode.cash),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SettlementModeButton(
              label: 'Mixed Settlement',
              icon: Icons.call_split_rounded,
              selected: payment.paymentMode == PaymentMode.mixed,
              onTap: () => payment.setPaymentMode(PaymentMode.mixed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SettlementModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? SilverStockColors.paymentPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: SilverStockColors.shadowLight,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : SilverStockColors.textBody,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : SilverStockColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementDiscountPanel extends StatelessWidget {
  final SilverPaymentController payment;

  const _SettlementDiscountPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fineMode = payment.discountMode == SilverDiscountMode.fine;
    final appliedValue = fineMode
        ? '${_weight(payment.fineDiscountWeight)} g'
        : _money(payment.cashDiscountAmount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 820;
          const title = _SettlementDiscountTitle();
          final modeSelector = _DiscountTypeSelector(
            fineMode: fineMode,
            onFineTap: () => payment.setDiscountMode(SilverDiscountMode.fine),
            onCashTap: () => payment.setDiscountMode(SilverDiscountMode.cash),
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
        const _IconBox(icon: Icons.discount_rounded),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fine or cash settlement adjustment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
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
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Fine Discount',
              selected: fineMode,
              onTap: onFineTap,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Cash Discount',
              selected: !fineMode,
              onTap: onCashTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? SilverStockColors.paymentPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : SilverStockColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalSettlementBoard extends StatelessWidget {
  final SilverPaymentController payment;

  const _MetalSettlementBoard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final hasShortFine = payment.fineShortage > 0;
    final hasExcessFine = payment.fineExcess > 0;
    final differenceLabel = hasExcessFine ? 'Excess Fine' : 'Short Fine';
    final differenceValue = hasExcessFine
        ? '${_weight(payment.fineExcess)} g'
        : '${_weight(payment.fineShortage)} g';
    final differenceAmount =
        hasExcessFine ? payment.fineExcessValue : payment.fineShortageValue;

    return _PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Silver Metal Settlement',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
                ),
              ),
              _SmallActionButton(
                label: 'Add Metal Line',
                icon: Icons.add_rounded,
                onTap: () => payment.addMetalLine(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...payment.metalLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MetalLineEditor(
                line: line,
                canRemove: payment.metalLines.length > 1,
                onRemove: () => payment.removeMetalLine(line.id),
              ),
            ),
          ),
          const SizedBox(height: 2),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final children = [
                _ReadOnlyValue(
                  label: 'Fine Received',
                  value: '${_weight(payment.fineReceived)} g',
                  icon: SilverStockIcons.fineWeight,
                  tone: _MetricTone.success,
                ),
                _ReadOnlyValue(
                  label: differenceLabel,
                  value: differenceValue,
                  icon: hasExcessFine
                      ? SilverStockIcons.returnBalance
                      : SilverStockIcons.dueBalance,
                  tone:
                      hasExcessFine ? _MetricTone.success : _MetricTone.danger,
                ),
                _ReadOnlyValue(
                  label: '$differenceLabel Value',
                  value: _money(differenceAmount),
                  icon: SilverStockIcons.cashPayment,
                  tone:
                      hasExcessFine ? _MetricTone.success : _MetricTone.danger,
                ),
              ];

              if (compact) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 10),
                  Expanded(child: children[1]),
                  const SizedBox(width: 10),
                  Expanded(child: children[2]),
                ],
              );
            },
          ),
          if (hasShortFine || hasExcessFine) ...[
            const SizedBox(height: 12),
            _MetalDifferenceActions(payment: payment, excess: hasExcessFine),
          ],
        ],
      ),
    );
  }
}

class _MetalLineEditor extends StatelessWidget {
  final SilverMetalSettlementLine line;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MetalLineEditor({
    required this.line,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: line,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final gross = _SettlementInput(
              label: 'Silver Given',
              controller: line.grossCtrl,
              suffixText: 'g',
              icon: SilverStockIcons.weight,
            );
            final purity = _SettlementInput(
              label: 'Purity',
              controller: line.purityCtrl,
              suffixText: '%',
              icon: SilverStockIcons.purity,
            );
            final fine = _ReadOnlyValue(
              label: 'Fine Received',
              value: '${_weight(line.fineWeight)} g',
              icon: SilverStockIcons.fineWeight,
              tone: _MetricTone.neutral,
            );
            final removeButton = SizedBox(
              width: 42,
              child: IconButton(
                tooltip: 'Remove line',
                onPressed: canRemove ? onRemove : null,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: canRemove
                      ? SilverStockColors.danger
                      : SilverStockColors.textHint,
                ),
              ),
            );

            if (compact) {
              return Column(
                children: [
                  gross,
                  const SizedBox(height: 10),
                  purity,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: fine),
                      removeButton,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: gross),
                const SizedBox(width: 10),
                Expanded(child: purity),
                const SizedBox(width: 10),
                Expanded(child: fine),
                removeButton,
              ],
            );
          },
        );
      },
    );
  }
}

class _MetalDifferenceActions extends StatelessWidget {
  final SilverPaymentController payment;
  final bool excess;

  const _MetalDifferenceActions({
    required this.payment,
    required this.excess,
  });

  @override
  Widget build(BuildContext context) {
    final metalLabel = excess ? 'Return Fine' : 'Keep Fine Due';
    final cashLabel = excess ? 'Return Cash Value' : 'Convert to Cash Due';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              excess ? 'Excess Fine Handling' : 'Short Fine Handling',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: SilverStockColors.textDark,
              ),
            ),
          ),
          _ChoiceChipButton(
            label: metalLabel,
            selected: payment.metalDueReturnType == DueReturnType.metal,
            onTap: () => payment.setMetalDueReturnType(DueReturnType.metal),
          ),
          const SizedBox(width: 8),
          _ChoiceChipButton(
            label: cashLabel,
            selected: payment.metalDueReturnType == DueReturnType.cash,
            onTap: () => payment.setMetalDueReturnType(DueReturnType.cash),
          ),
        ],
      ),
    );
  }
}

class _CashSettlementBoard extends StatelessWidget {
  final SilverPaymentController payment;

  const _CashSettlementBoard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final balanceTone = payment.hasReturn
        ? _MetricTone.success
        : payment.hasDue
            ? _MetricTone.danger
            : _MetricTone.success;

    return _PanelBox(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final tiles = [
            _ReadOnlyValue(
              label: 'Payable Amount',
              value: _money(payment.cashTargetAmount),
              icon: SilverStockIcons.payable,
              tone: _MetricTone.neutral,
            ),
            _ReadOnlyValue(
              label: 'Cash / Bank Paid',
              value: _money(payment.cashBankPaidTotal),
              icon: SilverStockIcons.amountReceived,
              tone: _MetricTone.success,
            ),
            _ReadOnlyValue(
              label: payment.balanceLabel,
              value: _money(
                  payment.hasReturn ? payment.returnAmount : payment.dueAmount),
              icon: payment.hasReturn
                  ? SilverStockIcons.returnBalance
                  : SilverStockIcons.dueBalance,
              tone: balanceTone,
            ),
          ];

          if (compact) {
            return Column(
              children: tiles
                  .map(
                    (tile) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: tile,
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 10),
              Expanded(child: tiles[1]),
              const SizedBox(width: 10),
              Expanded(child: tiles[2]),
            ],
          );
        },
      ),
    );
  }
}

class _CashSplitGrid extends StatelessWidget {
  final SilverPaymentController payment;

  const _CashSplitGrid({required this.payment});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth < 860;
        final fields = [
          _SettlementInput(
            label: 'Cash',
            controller: payment.cashCtrl,
            prefixText: 'Rs ',
            icon: SilverStockIcons.cashPayment,
          ),
          _SettlementInput(
            label: 'UPI',
            controller: payment.upiCtrl,
            prefixText: 'Rs ',
            icon: SilverStockIcons.upi,
          ),
          _SettlementInput(
            label: 'Bank Transfer',
            controller: payment.bankCtrl,
            prefixText: 'Rs ',
            icon: SilverStockIcons.bank,
          ),
          _SettlementInput(
            label: 'Card',
            controller: payment.cardCtrl,
            prefixText: 'Rs ',
            icon: SilverStockIcons.cardPayment,
          ),
        ];

        if (twoColumn) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: fields
                .map(
                  (field) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: field,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 10),
            Expanded(child: fields[1]),
            const SizedBox(width: 10),
            Expanded(child: fields[2]),
            const SizedBox(width: 10),
            Expanded(child: fields[3]),
          ],
        );
      },
    );
  }
}

class _SettlementInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? prefixText;
  final String? suffixText;

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
        const SizedBox(height: 5),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.textDark,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: SilverStockColors.inputBg,
              prefixIcon: Icon(
                icon,
                size: 16,
                color: SilverStockColors.textMuted,
              ),
              prefixText: prefixText,
              suffixText: suffixText,
              prefixStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SilverStockColors.textMuted,
              ),
              suffixStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SilverStockColors.textMuted,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SilverStockColors.paymentPrimary,
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
  final IconData icon;
  final _MetricTone tone;

  const _ReadOnlyValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MetricToneStyle.from(tone);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colors.foreground),
          const SizedBox(width: 9),
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
                    fontWeight: FontWeight.w800,
                    color: SilverStockColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.foreground,
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

class _AppliedDiscountTile extends StatelessWidget {
  final String value;

  const _AppliedDiscountTile({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Applied Discount'),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SilverStockColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: SilverStockColors.paymentPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
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

class _ChoiceChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? SilverStockColors.paymentPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? SilverStockColors.paymentPrimary
                  : SilverStockColors.brandSilverBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : SilverStockColors.paymentPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SilverStockColors.brandSilverLight,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: SilverStockColors.brandSilverBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: SilverStockColors.paymentPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.paymentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
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

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilverLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.brandSilverBorder),
      ),
      child: Icon(icon, size: 16, color: SilverStockColors.paymentPrimary),
    );
  }
}

class _SilverCardShell extends StatelessWidget {
  final Widget child;

  const _SilverCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
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
        child: child,
      ),
    );
  }
}

class _PanelBox extends StatelessWidget {
  final Widget child;

  const _PanelBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: child,
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
        letterSpacing: 0.15,
        color: SilverStockColors.textMuted,
      ),
    );
  }
}

enum _MetricTone { neutral, success, danger }

class _MetricToneStyle {
  final Color background;
  final Color border;
  final Color foreground;

  const _MetricToneStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  factory _MetricToneStyle.from(_MetricTone tone) {
    return switch (tone) {
      _MetricTone.neutral => const _MetricToneStyle(
          background: SilverStockColors.cardBg,
          border: SilverStockColors.cardBorder,
          foreground: SilverStockColors.textDark,
        ),
      _MetricTone.success => const _MetricToneStyle(
          background: SilverStockColors.successBg,
          border: SilverStockColors.successBorder,
          foreground: SilverStockColors.success,
        ),
      _MetricTone.danger => const _MetricToneStyle(
          background: SilverStockColors.dangerBg,
          border: Color(0x33EF4444),
          foreground: SilverStockColors.danger,
        ),
    };
  }
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);
}

String _weight(double value) => value.toStringAsFixed(3);
