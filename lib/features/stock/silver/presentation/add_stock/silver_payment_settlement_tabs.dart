part of 'silver_payment_record_card.dart';

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
