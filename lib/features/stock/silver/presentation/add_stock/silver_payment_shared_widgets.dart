part of 'silver_payment_record_card.dart';

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
