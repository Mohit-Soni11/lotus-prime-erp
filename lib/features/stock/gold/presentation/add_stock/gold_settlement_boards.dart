part of 'gold_settlement_method_card.dart';

class _MetalSettlementBoard extends StatelessWidget {
  final GoldPaymentController payment;

  const _MetalSettlementBoard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final line = payment.metalLines.isEmpty ? null : payment.metalLines.first;
    final hasExcessFine = payment.fineExcess > 0;
    final balanceFine =
        hasExcessFine ? payment.fineExcess : payment.fineShortage;
    final balanceFineValue =
        hasExcessFine ? payment.fineExcessValue : payment.fineShortageValue;
    final balanceTone = hasExcessFine
        ? GoldStockColors.paymentReturn
        : balanceFine > 0
            ? GoldStockColors.danger
            : GoldStockColors.success;

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
              final stacked = constraints.maxWidth < 980;
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
                  label: hasExcessFine ? 'Excess Fine' : 'Short Fine',
                  value: '${balanceFine.toStringAsFixed(3)} g',
                  tone: balanceTone,
                  icon: hasExcessFine
                      ? GoldStockIcons.returnBalance
                      : GoldStockIcons.dueBalance,
                ),
                _ReadOnlyValue(
                  label:
                      hasExcessFine ? 'Excess Fine Value' : 'Short Fine Value',
                  value: _money(balanceFineValue),
                  tone: balanceTone,
                  icon: GoldStockIcons.price,
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
          _MetalBalanceHandling(payment: payment),
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

class _MetalBalanceHandling extends StatelessWidget {
  final GoldPaymentController payment;

  const _MetalBalanceHandling({required this.payment});

  @override
  Widget build(BuildContext context) {
    final hasExcessFine = payment.fineExcess > 0;
    final actions = hasExcessFine
        ? [
            _ChoiceButton(
              label: 'Return Fine',
              active: payment.metalDueReturnType == DueReturnType.metal,
              onTap: () => payment.setMetalDueReturnType(DueReturnType.metal),
            ),
            _ChoiceButton(
              label: 'Return Cash Value',
              active: payment.metalDueReturnType == DueReturnType.cash,
              onTap: () => payment.setMetalDueReturnType(DueReturnType.cash),
            ),
            _ChoiceButton(
              label: 'Keep Supplier Credit',
              active: payment.metalDueReturnType == DueReturnType.credit,
              onTap: () => payment.setMetalDueReturnType(DueReturnType.credit),
            ),
          ]
        : [
            _ChoiceButton(
              label: 'Keep Fine Due',
              active: payment.metalDueReturnType != DueReturnType.cash,
              onTap: () => payment.setMetalDueReturnType(DueReturnType.metal),
            ),
            _ChoiceButton(
              label: 'Convert to Cash Due',
              active: payment.metalDueReturnType == DueReturnType.cash,
              onTap: () => payment.setMetalDueReturnType(DueReturnType.cash),
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              hasExcessFine ? 'Excess Fine Handling' : 'Short Fine Handling',
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
          Flexible(
            flex: 2,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: actions,
            ),
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
