part of 'silver_payment_record_card.dart';

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
