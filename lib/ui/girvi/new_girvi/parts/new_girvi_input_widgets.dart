part of '../new_girvi_screen.dart';

class _SelectCustomerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SelectCustomerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GirviColors.accentCustomer.withValues(alpha: 0.26),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                GirviIcons.search,
                color: GirviColors.textDark,
                size: 18,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  GirviStrings.selectCustomerHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
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

class _ItemCountStepper extends StatelessWidget {
  final int count;
  final void Function(int) onChanged;

  const _ItemCountStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GirviStyles.inputHeight,
      decoration: GirviStyles.inputNormal,
      child: Row(children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: () => onChanged(count - 1),
          enabled: count > 1,
        ),
        Expanded(
          child: Center(
            child: Text('$count',
                style: GirviStyles.fieldInput.copyWith(fontSize: 18)),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: () => onChanged(count + 1),
          enabled: count < 99,
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: GirviStyles.inputHeight,
          alignment: Alignment.center,
          child: Icon(icon,
              color: enabled ? GirviColors.brandGold : GirviColors.textHint,
              size: 20),
        ),
      );
}

class _LoanTermsGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  const _LoanTermsGroupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.brandGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: GirviColors.brandGold.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: GirviColors.brandGold, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GirviStyles.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: GirviColors.textBody,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GirviColors.bodyBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Text(
              trailing!,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LtvSuggestionRow extends StatelessWidget {
  final double totalValue;
  final void Function(double ltv) onSuggestionTap;

  const _LtvSuggestionRow({
    required this.totalValue,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    const ltvs = [50.0, 60.0, 70.0, 75.0, 80.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick LTV Suggestions:',
            style: GirviStyles.caption.copyWith(fontSize: 12.5)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ltvs.map((ltv) {
              final amt = totalValue * (ltv / 100);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSuggestionTap(ltv),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GirviColors.brandGold.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      Text('${ltv.toInt()}% LTV',
                          style: GoogleFonts.inter(
                              color: GirviColors.brandDeep,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      Text(_formatSmartMoney(amt),
                          style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LtvIndicator extends StatelessWidget {
  final double ltv;
  final bool enabled;
  final void Function(double) onChanged;

  const _LtvIndicator({
    required this.ltv,
    required this.enabled,
    required this.onChanged,
  });

  Color get _color {
    if (ltv <= 60) return GirviColors.success;
    if (ltv <= 75) return GirviColors.warning;
    return GirviColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _color : GirviColors.brandGold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loan-to-Value (LTV)', style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: GirviStyles.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.06)
                : GirviColors.inputBgLocked,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.25)
                  : GirviColors.cardBorder,
            ),
          ),
          child: Row(children: [
            Icon(GirviIcons.loanTerms, color: color, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: GirviColors.cardBorder),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  thumbColor: color,
                  inactiveTrackColor: GirviColors.divider,
                  disabledActiveTrackColor: color.withValues(alpha: 0.35),
                  disabledThumbColor: color.withValues(alpha: 0.70),
                  overlayColor: color.withValues(alpha: 0.15),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: ltv.clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: Text(
                _formatSmartPercent(ltv),
                textAlign: TextAlign.right,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
