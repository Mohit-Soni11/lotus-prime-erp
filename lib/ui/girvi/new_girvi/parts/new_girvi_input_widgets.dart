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

  const _LoanTermsGroupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
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
      ],
    );
  }
}
