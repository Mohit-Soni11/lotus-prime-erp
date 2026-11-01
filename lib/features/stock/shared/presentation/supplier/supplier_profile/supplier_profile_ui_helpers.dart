part of 'supplier_profile_screen.dart';

extension _SupplierProfileUiHelpers on _SupplierProfileScreenState {
  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: SupplierProfileStyles.tintedPanel(color),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SupplierProfileStyles.sectionTitle),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SupplierProfileStyles.sectionSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _softChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Text(
        label,
        style: SupplierProfileStyles.chipText.copyWith(color: Colors.black),
      ),
    );
  }
}
