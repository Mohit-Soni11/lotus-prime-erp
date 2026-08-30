part of 'customer_metal_purchase_ledger_actions.dart';

class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SheetActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonSurface(
      icon: icon,
      label: label,
      enabled: enabled,
      onPressed: onPressed,
      minWidth: 180,
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PreviewActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonSurface(
      icon: icon,
      label: label,
      enabled: enabled,
      onPressed: onPressed,
      minWidth: 132,
    );
  }
}

class _ActionButtonSurface extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final double minWidth;

  const _ActionButtonSurface({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size(minWidth, 42),
        backgroundColor: PurchaseEntryColors.purchaseAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        disabledForegroundColor: const Color(0xFF94A3B8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
