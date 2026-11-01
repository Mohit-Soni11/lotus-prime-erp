part of 'due_collection_entry_screen.dart';

class _PremiumNoticeToast extends StatelessWidget {
  final String message;
  final _PremiumNoticeType type;
  final VoidCallback onClose;

  const _PremiumNoticeToast({
    required this.message,
    required this.type,
    required this.onClose,
  });

  Color get _accent {
    return switch (type) {
      _PremiumNoticeType.success => DueCollectionEntryColors.brandGold,
      _PremiumNoticeType.warning => DueCollectionEntryColors.warning,
      _PremiumNoticeType.error => DueCollectionEntryColors.danger,
    };
  }

  Color get _surface {
    return switch (type) {
      _PremiumNoticeType.success => const Color(0xFFFFFCF2),
      _PremiumNoticeType.warning => DueCollectionEntryColors.warningBg,
      _PremiumNoticeType.error => DueCollectionEntryColors.dangerBg,
    };
  }

  IconData get _icon {
    return switch (type) {
      _PremiumNoticeType.success => DueCollectionEntryIcons.verified,
      _PremiumNoticeType.warning => DueCollectionEntryIcons.warning,
      _PremiumNoticeType.error => DueCollectionEntryIcons.warning,
    };
  }

  String get _title {
    return switch (type) {
      _PremiumNoticeType.success => 'Receipt Saved',
      _PremiumNoticeType.warning => 'Print Notice',
      _PremiumNoticeType.error => 'Action Needed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Positioned(
      top: 86,
      right: 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(28 * (1 - value), -8 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 410,
            constraints: const BoxConstraints(maxWidth: 410),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DueCollectionEntryColors.bodyPanel,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.22)),
                        ),
                        child: Icon(_icon, color: accent, size: 19),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title,
                              style: DueCollectionEntryStyles.rowTitle.copyWith(
                                color: DueCollectionEntryColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: DueCollectionEntryStyles.rowSub.copyWith(
                                color: DueCollectionEntryColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            DueCollectionEntryIcons.clear,
                            size: 16,
                            color: DueCollectionEntryColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 3,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 0),
                      duration: const Duration(milliseconds: 3300),
                      curve: Curves.linear,
                      builder: (context, value, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0, 1),
                            child: Container(
                              color: accent.withValues(alpha: 0.86),
                            ),
                          ),
                        );
                      },
                    ),
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
