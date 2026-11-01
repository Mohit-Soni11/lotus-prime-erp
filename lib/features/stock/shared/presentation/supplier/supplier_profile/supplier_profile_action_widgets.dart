part of 'supplier_profile_screen.dart';

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: SupplierProfileStyles.actionButtonHeight,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.border,
                width: widget.filled ? 0 : 1.4,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.border.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.fg, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.chipText.copyWith(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _typeColor(SupplierType type) {
  switch (type) {
    case SupplierType.manufacturer:
      return SupplierProfileColors.brandGold;
    case SupplierType.wholesaler:
      return SupplierProfileColors.info;
    case SupplierType.retailer:
      return SupplierProfileColors.success;
    case SupplierType.individual:
      return SupplierProfileColors.violet;
  }
}

String _valueOrNa(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? SupplierProfileStrings.lblNa : trimmed;
}

String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';

String _weight(double value) => value.toStringAsFixed(3);

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index == -1 ? normalized : normalized.substring(index + 1);
}
