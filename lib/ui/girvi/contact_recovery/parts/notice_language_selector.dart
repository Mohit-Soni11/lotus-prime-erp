part of '../contact_recovery_screen.dart';

class _NoticeLanguageSelectorDialog extends StatelessWidget {
  const _NoticeLanguageSelectorDialog({
    required this.noticeType,
    required this.availableLanguages,
  });

  final GirviNoticeType noticeType;
  final Set<GirviNoticeLanguage> availableLanguages;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: GirviColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Choose Notice Language',
          style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
        ),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${noticeType.label} PDF',
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final language in GirviNoticeLanguage.values) ...[
                _NoticeLanguageChoice(
                  language: language,
                  available: availableLanguages.contains(language),
                  onTap: () => Navigator.of(context).pop(language),
                ),
                if (language != GirviNoticeLanguage.values.last)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
}

class _NoticeLanguageChoice extends StatelessWidget {
  const _NoticeLanguageChoice({
    required this.language,
    required this.available,
    required this.onTap,
  });

  final GirviNoticeLanguage language;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: available ? 1 : 0.52,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: available
                      ? GirviColors.info.withValues(alpha: 0.32)
                      : GirviColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    available
                        ? Icons.picture_as_pdf_rounded
                        : Icons.lock_outline_rounded,
                    color: available ? GirviColors.info : GirviColors.textMuted,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.label,
                          style: GirviStyles.caption.copyWith(
                            color: GirviColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          available
                              ? 'Open approved ${language.label} PDF'
                              : 'Not saved for this legacy notice',
                          style: GirviStyles.caption.copyWith(
                            color: GirviColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (available)
                    const Icon(Icons.chevron_right_rounded,
                        color: GirviColors.info),
                ],
              ),
            ),
          ),
        ),
      );
}
