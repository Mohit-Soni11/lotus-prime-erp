part of 'gold_settlement_method_card.dart';

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
