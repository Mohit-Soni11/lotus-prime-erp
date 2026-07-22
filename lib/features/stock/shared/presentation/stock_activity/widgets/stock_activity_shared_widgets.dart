part of '../stock_activity_screen.dart';

class _ActivitySurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ActivitySurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
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
      ),
      child: child,
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5C430A),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF171203),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;

  const _ActivityMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _labelText()),
                const SizedBox(height: 4),
                Text(value, style: _valueText(19)),
                const SizedBox(height: 2),
                Text(subtitle, style: _mutedText()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TimelineMarker({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _MovementBadge extends StatelessWidget {
  final StockActivityRecord record;

  const _MovementBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final accent = _movementAccent(record);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        _movementLabel(record),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: InvColors.brandGold),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: _labelText().copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _valueText(13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SectionIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;

  const _SoftBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.brandGoldLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: InvColors.brandGold.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF8A6507),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(44),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(42),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: InvColors.brandGoldLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: InvColors.brandGold.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, color: InvColors.brandGold, size: 30),
          ),
          const SizedBox(height: 15),
          Text(title, style: _titleText(18)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _mutedText(),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _inputBorder({
  Color color = const Color(0xFFE2D8C8),
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: color, width: width),
  );
}

TextStyle _titleText(double size) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _valueText(double size) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: InvColors.textDark,
  );
}

TextStyle _labelText() {
  return GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: InvColors.textMuted,
    letterSpacing: 0.35,
  );
}

TextStyle _bodyText() {
  return GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: InvColors.textBody,
  );
}

TextStyle _mutedText() {
  return GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: InvColors.textMuted,
  );
}

IconData _movementIcon(StockActivityRecord record) {
  if (record.isPurchase) return Icons.add_business_rounded;
  if (record.isSale) return Icons.point_of_sale_rounded;
  if (record.isRestore) return Icons.restore_rounded;
  return Icons.timeline_rounded;
}

Color _movementAccent(StockActivityRecord record) {
  if (record.isPurchase) return InvColors.success;
  if (record.isSale) return InvColors.danger;
  if (record.isRestore) return const Color(0xFF2563EB);
  return InvColors.brandGold;
}

IconData _metalIcon(String metal) {
  return switch (metal.toLowerCase()) {
    'gold' => Icons.workspace_premium_rounded,
    'silver' => Icons.blur_circular_rounded,
    'diamond' => Icons.diamond_rounded,
    'platinum' => Icons.trip_origin_rounded,
    _ => Icons.category_rounded,
  };
}

Color _metalAccent(String metal) {
  return switch (metal.toLowerCase()) {
    'gold' => InvColors.brandGold,
    'silver' => const Color(0xFF64748B),
    'diamond' => const Color(0xFF0284C7),
    'platinum' => const Color(0xFF475569),
    _ => InvColors.textMuted,
  };
}

Color _metalBackground(String metal) {
  return switch (metal.toLowerCase()) {
    'gold' => const Color(0xFFFFFAE8),
    'silver' => const Color(0xFFF1F5F9),
    'diamond' => const Color(0xFFEFF9FF),
    'platinum' => const Color(0xFFF8FAFC),
    _ => const Color(0xFFF8FAFC),
  };
}

String _movementLabel(StockActivityRecord record) {
  if (record.isPurchase) return 'IN';
  if (record.isSale) return 'SOLD';
  if (record.isRestore) return 'RESTORED';
  return record.movementType.toUpperCase();
}

String _weight(double value) {
  return '${value.toStringAsFixed(3)} g';
}

String _signedWeight(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(3)} g';
}

String _date(DateTime value) {
  return DateFormat('dd MMM yyyy\nhh:mm a').format(value);
}
