part of '../account_profile_screen.dart';

class _PhotoMenuSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoMenuSheet({required this.onGallery, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AccountProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AccountProfileColors.bodyBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AccountProfileColors.bodyBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _SheetTile(
            icon: AccountProfileIcons.gallery,
            label: AccountProfileStrings.photoMenuGallery,
            color: AccountProfileColors.brandGold,
            onTap: onGallery,
          ),
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.5),
              height: 1,
              indent: 20,
              endIndent: 20),
          _SheetTile(
            icon: AccountProfileIcons.deletePhoto,
            label: AccountProfileStrings.photoMenuRemove,
            color: AccountProfileColors.danger,
            onTap: onRemove,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AccountProfileColors.bodyTextMain)),
          ],
        ),
      ),
    );
  }
}
