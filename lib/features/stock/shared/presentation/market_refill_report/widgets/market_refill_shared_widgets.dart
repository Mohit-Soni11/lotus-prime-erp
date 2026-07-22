part of '../market_refill_report_screen.dart';

final _refillNumberFormat = NumberFormat.decimalPattern('en_IN');
final _refillWeightFormat = NumberFormat('##,##0.000', 'en_IN');
final _refillDateFormat = DateFormat('dd MMM yyyy, hh:mm a');

class _RefillHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _RefillHeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _RefillIconBox(icon: icon, accent: accent, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: _refillMutedStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _refillStrongStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RefillPrimaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefillActionButton(
      label: label,
      icon: icon,
      enabled: enabled,
      fill: InvColors.brandGold,
      foreground: Colors.white,
      onTap: onTap,
    );
  }
}

class _RefillSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RefillSecondaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefillActionButton(
      label: label,
      icon: icon,
      enabled: enabled,
      fill: const Color(0xFFFFFCF7),
      foreground: InvColors.textDark,
      border: const Color(0xFFE8DDC9),
      onTap: onTap,
    );
  }
}

class _RefillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color fill;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  const _RefillActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.fill,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? fill : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? (border ?? fill) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? foreground : InvColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: enabled ? foreground : InvColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefillShellButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RefillShellButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_RefillShellButton> createState() => _RefillShellButtonState();
}

class _RefillShellButtonState extends State<_RefillShellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? InvColors.shellBg
                : InvColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered ? InvColors.brandGold : InvColors.shellBorder,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? InvColors.brandGold : InvColors.shellTextTitle,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _RefillAppIcon extends StatelessWidget {
  const _RefillAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD76A), InvColors.brandGold],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _RefillIconBox extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;

  const _RefillIconBox({
    required this.icon,
    required this.accent,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size >= 50 ? 16 : 13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: size >= 50 ? 28 : 21),
    );
  }
}

class _RefillBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _RefillBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _RefillEmptyState extends StatelessWidget {
  final String message;

  const _RefillEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _refillMutedStyle(),
      ),
    );
  }
}

class _MarketRefillError extends StatelessWidget {
  final String message;

  const _MarketRefillError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillDivider extends StatelessWidget {
  const _RefillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            InvColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RefillOnlineBadge extends StatelessWidget {
  final AnimationController pulse;

  const _RefillOnlineBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: InvColors.onlineGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RefillPulseWave(animation: pulse, delay: 0),
                _RefillPulseWave(animation: pulse, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: InvColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: GoogleFonts.inter(
              color: InvColors.onlineGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillPulseWave extends StatelessWidget {
  final AnimationController animation;
  final double delay;

  const _RefillPulseWave({
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = (animation.value + delay) % 1;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + value * 1.5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: InvColors.onlineGreen.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE8DDC9)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.055),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

TextStyle _refillStrongStyle({double fontSize = 14}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _refillMutedStyle({double fontSize = 12}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}

TextStyle _tableHeadStyle() {
  return GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w900,
    color: InvColors.textMuted,
  );
}

String _formatQty(int value, String unitLabel) {
  final clean = unitLabel.trim().toLowerCase();
  final unit = clean.isEmpty || clean == 'unit' ? 'unit' : clean;
  return '${_refillNumberFormat.format(value)} $unit';
}

String _weight(double value) => _refillWeightFormat.format(value);

String _date(DateTime? value) {
  if (value == null) return 'Not checked out yet';
  return _refillDateFormat.format(value);
}

String _marketGroupTitle(MarketRefillItemRow row) {
  switch (row.metal.trim().toLowerCase()) {
    case 'gold':
      return row.gradeLabel.trim().isEmpty
          ? 'Gold Grade Not Tagged'
          : row.gradeLabel;
    case 'silver':
      return row.companyLabel;
    default:
      return row.gradeLabel.trim().isEmpty ? row.metal : row.gradeLabel;
  }
}

Color _metalAccent(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return const Color(0xFF64748B);
    case 'diamond':
      return const Color(0xFF0EA5E9);
    case 'platinum':
      return const Color(0xFF475569);
    case 'gold':
      return InvColors.brandGold;
    default:
      return const Color(0xFF64748B);
  }
}

IconData _metalIcon(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return Icons.circle_outlined;
    case 'diamond':
      return Icons.diamond_rounded;
    case 'platinum':
      return Icons.radio_button_checked_rounded;
    case 'gold':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}
