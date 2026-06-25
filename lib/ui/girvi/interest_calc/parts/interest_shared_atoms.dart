part of '../interest_calc_screen.dart';

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool dark;

  const _IconBox({
    required this.icon,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dark ? 42 : 38,
      height: dark ? 42 : 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: dark ? 22 : 20),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OverviewActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;

  const _OverviewActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GirviColors.shellBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: GirviColors.shellBorder),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GirviColors.brandGold,
                ),
              )
            else
              Icon(icon, color: GirviColors.brandGold, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String value;

  const _CountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        value,
        style: GoogleFonts.manrope(
          color: GirviColors.brandDeep,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyTag({
    required this.label,
    this.color = GirviColors.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          color: color == GirviColors.brandGold
              ? GirviColors.brandDeep
              : GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            color: GirviColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: valueColor ?? GirviColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;

  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GirviColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(
            GirviIcons.markDone,
            color: GirviColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool large;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(large ? 42 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: large ? 72 : 54,
              height: large ? 72 : 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GirviColors.brandGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: GirviColors.brandGold,
                size: large ? 32 : 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: large ? 18 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: large ? 14 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
