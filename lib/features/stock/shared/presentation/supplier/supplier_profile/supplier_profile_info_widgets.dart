part of 'supplier_profile_screen.dart';

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? width;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                SupplierProfileStyles.tintedPanel(SupplierProfileColors.info),
            child: Icon(icon, size: 18, color: SupplierProfileColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SupplierProfileStyles.infoLabel),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.infoValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return width == null ? tile : SizedBox(width: width, child: tile);
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(16),
      decoration: SupplierProfileStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: SupplierProfileStyles.tintedPanel(color),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.statValue,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.statLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
