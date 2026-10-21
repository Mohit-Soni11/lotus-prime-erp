part of '../contact_recovery_screen.dart';

class _InlineMessage extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InlineMessage({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.infoBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.info.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(GirviIcons.info, size: 18, color: GirviColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GirviStyles.caption.copyWith(fontSize: 12.5),
              ),
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
