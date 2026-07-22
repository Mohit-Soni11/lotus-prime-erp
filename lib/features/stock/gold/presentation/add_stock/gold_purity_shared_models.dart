part of 'gold_purity_step.dart';

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _StockGroup {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final double fineWeight;

  const _StockGroup({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.fineWeight = 0.0,
  });

  _StockGroup copyWith({double? fineWeight}) {
    return _StockGroup(
      label: label,
      description: description,
      icon: icon,
      color: color,
      fineWeight: fineWeight ?? this.fineWeight,
    );
  }
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: GoldStockColors.textDark,
  );
}

TextStyle _bodyStyle(double size) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: GoldStockColors.textDark,
  );
}
