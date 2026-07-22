part of 'gold_settlement_method_card.dart';

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
