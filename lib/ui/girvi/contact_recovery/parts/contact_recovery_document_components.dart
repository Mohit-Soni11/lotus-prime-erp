part of '../contact_recovery_screen.dart';

class _NoticeDocumentStrip extends StatelessWidget {
  final ContactRecoveryCase item;
  final ValueChanged<GirviNoticeAction> onViewNotice;
  final ValueChanged<GirviNoticeAction> onDownloadNotice;
  final ValueChanged<GirviNoticeAction> onPrintNotice;

  const _NoticeDocumentStrip({
    required this.item,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
  });

  @override
  Widget build(BuildContext context) {
    final actions = item.preparedNoticeActions;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notice Documents',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _NoticeCountBadge(label: item.noticesSentLabel),
            ],
          ),
          const SizedBox(height: 9),
          if (actions.isEmpty)
            const _NoNoticeDocuments()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map(
                (action) {
                  final stage = _noticeStageFromAction(action) ?? 1;
                  return _NoticeDocumentCard(
                    action: action,
                    latestProof: item.latestDeliveryProofForStage(stage),
                    onView: () => onViewNotice(action),
                    onDownload: () => onDownloadNotice(action),
                    onPrint: () => onPrintNotice(action),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _NoticeCountBadge extends StatelessWidget {
  final String label;

  const _NoticeCountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GirviStyles.caption.copyWith(
          color: GirviColors.brandGold,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoNoticeDocuments extends StatelessWidget {
  const _NoNoticeDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Text(
        'No notice document has been prepared yet.',
        style: GirviStyles.caption.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoticeDocumentCard extends StatelessWidget {
  final GirviNoticeAction action;
  final GirviNoticeAction? latestProof;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  const _NoticeDocumentCard({
    required this.action,
    required this.latestProof,
    required this.onView,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final noticeType = _noticeTypeFromAction(action);
    final timestamp =
        DateFormat('dd MMM yyyy, hh:mm a').format(action.actionAt);
    final proof = latestProof;
    final proofTimestamp = proof == null
        ? null
        : DateFormat('dd MMM yyyy, hh:mm a')
            .format(proof.deliveredAt ?? proof.actionAt);
    final color = _noticeStageColor(noticeType);

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 206,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Text(
                    '0${noticeType.stage}',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    noticeType.label,
                    style: GirviStyles.caption.copyWith(
                      color: GirviColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prepared $timestamp',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: proof == null
                    ? GirviColors.warningBg.withValues(alpha: 0.45)
                    : GirviColors.successBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: proof == null
                      ? GirviColors.warning.withValues(alpha: 0.24)
                      : GirviColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                proof == null
                    ? 'Proof pending'
                    : '${proof.deliveryProofLabel} - $proofTimestamp',
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    onTap: onView,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Save',
                    icon: Icons.download_rounded,
                    onTap: onDownload,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Print',
                    icon: Icons.print_rounded,
                    onTap: onPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _noticeStageColor(GirviNoticeType noticeType) {
    switch (noticeType) {
      case GirviNoticeType.first:
        return GirviColors.warning;
      case GirviNoticeType.second:
        return GirviColors.danger;
      case GirviNoticeType.finalNotice:
        return GirviColors.info;
    }
  }
}

class _MiniNoticeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniNoticeAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == 'Save' ? 'Download PDF' : '$label notice',
      waitDuration: const Duration(milliseconds: 450),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: GirviColors.textDark),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeDocumentPreview extends StatelessWidget {
  final String noticeText;
  final GirviNoticeLanguage language;
  final GirviNoticeType noticeType;

  const _NoticeDocumentPreview({
    super.key,
    required this.noticeText,
    required this.language,
    required this.noticeType,
  });

  @override
  Widget build(BuildContext context) {
    final document = _NoticePreviewData.parse(noticeText);
    final accent = _stageColor(noticeType);
    return Container(
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoticePreviewHeader(
              document: document,
              accent: accent,
              language: language,
            ),
            const SizedBox(height: 16),
            for (final section in document.sections) ...[
              _NoticePreviewSection(
                section: section,
                language: language,
                accent: accent,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Color _stageColor(GirviNoticeType type) {
    switch (type) {
      case GirviNoticeType.first:
        return GirviColors.warning;
      case GirviNoticeType.second:
        return GirviColors.danger;
      case GirviNoticeType.finalNotice:
        return GirviColors.info;
    }
  }
}

class _NoticePreviewHeader extends StatelessWidget {
  final _NoticePreviewData document;
  final Color accent;
  final GirviNoticeLanguage language;

  const _NoticePreviewHeader({
    required this.document,
    required this.accent,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          document.title,
          style: GoogleFonts.inter(
            color: GirviColors.shellBg,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: document.metadata
              .map((entry) => _NoticeMetadataPill(entry: entry, accent: accent))
              .toList(),
        ),
        if (document.subject != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.4),
              ),
            ),
            child: _NoticeLabelValue(
              label: language == GirviNoticeLanguage.hindi ? 'विषय' : 'Subject',
              value: document.subject!,
              valueColor: GirviColors.textDark,
              valueFontSize: 13.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _NoticeMetadataPill extends StatelessWidget {
  final MapEntry<String, String> entry;
  final Color accent;

  const _NoticeMetadataPill({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 235),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: '${entry.key}: ',
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
            TextSpan(text: entry.value),
          ],
        ),
      ),
    );
  }
}

class _NoticePreviewSection extends StatelessWidget {
  final _NoticePreviewSectionData section;
  final GirviNoticeLanguage language;
  final Color accent;

  const _NoticePreviewSection({
    required this.section,
    required this.language,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final financialSection = _isFinancialSection(section.title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: accent.withValues(alpha: 0.26)),
            ),
            child: Text(
              section.title,
              style: GoogleFonts.inter(
                color: GirviColors.shellBg,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 9),
        ],
        for (final line in section.lines) ...[
          if (line.isParagraph)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line.value,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 13.2,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: _lineBackground(line.label, financialSection),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _lineBorder(line.label, financialSection),
                ),
              ),
              child: _NoticeLabelValue(
                label: line.label,
                value: line.value,
                valueColor: _valueColor(line.label, financialSection),
                valueFontSize: _isKeyFinancialValue(line.label) ? 14.4 : 13.1,
              ),
            ),
        ],
      ],
    );
  }

  bool _isFinancialSection(String value) =>
      value.contains('Interest') ||
      value.contains('Outstanding') ||
      value.contains('भुगतान') ||
      value.contains('ब्याज') ||
      value.contains('बकाया');

  bool _isKeyFinancialValue(String label) =>
      label.contains('Final Total Payable') ||
      label.contains('Total Payable') ||
      label.contains('अंतिम कुल देय राशि');

  bool _isAlertValue(String label) =>
      label.contains('Outstanding') || label.contains('बकाया');

  Color _valueColor(String label, bool financialSection) {
    if (_isKeyFinancialValue(label)) return GirviColors.danger;
    if (_isAlertValue(label)) return GirviColors.danger;
    if (label.contains('Chargeable') || label.contains('चार्जेबल')) {
      return GirviColors.info;
    }
    return financialSection ? GirviColors.shellBg : GirviColors.textDark;
  }

  Color _lineBackground(String label, bool financialSection) {
    if (_isKeyFinancialValue(label)) {
      return GirviColors.dangerBg.withValues(alpha: 0.62);
    }
    if (_isAlertValue(label)) {
      return GirviColors.dangerBg.withValues(alpha: 0.34);
    }
    if (financialSection) return GirviColors.infoBg.withValues(alpha: 0.38);
    return GirviColors.bodyBg;
  }

  Color _lineBorder(String label, bool financialSection) {
    if (_isKeyFinancialValue(label) || _isAlertValue(label)) {
      return GirviColors.danger.withValues(alpha: 0.28);
    }
    return financialSection
        ? GirviColors.info.withValues(alpha: 0.22)
        : GirviColors.cardBorder;
  }
}

class _NoticeLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double valueFontSize;

  const _NoticeLabelValue({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: GirviColors.textDark,
          fontSize: 12.8,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticePreviewData {
  const _NoticePreviewData({
    required this.title,
    required this.metadata,
    required this.subject,
    required this.sections,
  });

  final String title;
  final List<MapEntry<String, String>> metadata;
  final String? subject;
  final List<_NoticePreviewSectionData> sections;

  factory _NoticePreviewData.parse(String source) {
    final lines = source
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const _NoticePreviewData(
        title: '',
        metadata: [],
        subject: null,
        sections: [],
      );
    }

    final metadata = <MapEntry<String, String>>[];
    String? subject;
    final sections = <_NoticePreviewSectionData>[];
    var current = _NoticePreviewSectionData(title: '', lines: []);

    for (final line in lines.skip(1)) {
      final entry = _NoticePreviewLine.parse(line);
      if (_isMetadata(entry.label)) {
        metadata.add(MapEntry(entry.label, entry.value));
      } else if (_isSubject(entry.label)) {
        subject = entry.value;
      } else if (entry.isSectionHeading) {
        if (current.lines.isNotEmpty || current.title.isNotEmpty) {
          sections.add(current);
        }
        current = _NoticePreviewSectionData(title: line, lines: []);
      } else {
        current.lines.add(entry);
      }
    }
    if (current.lines.isNotEmpty || current.title.isNotEmpty) {
      sections.add(current);
    }
    return _NoticePreviewData(
      title: lines.first,
      metadata: metadata,
      subject: subject,
      sections: sections,
    );
  }

  static bool _isMetadata(String label) => {
        'Notice Number',
        'Notice Date',
        'Pledge Reference',
        'सूचना नंबर',
        'सूचना दिनांक',
        'गिरवी संदर्भ',
      }.contains(label);

  static bool _isSubject(String label) => label == 'Subject' || label == 'विषय';
}

class _NoticePreviewSectionData {
  _NoticePreviewSectionData({required this.title, required this.lines});

  final String title;
  final List<_NoticePreviewLine> lines;
}

class _NoticePreviewLine {
  const _NoticePreviewLine({
    required this.label,
    required this.value,
    required this.isParagraph,
    required this.isSectionHeading,
  });

  final String label;
  final String value;
  final bool isParagraph;
  final bool isSectionHeading;

  factory _NoticePreviewLine.parse(String line) {
    final separator = line.indexOf(':');
    if (separator <= 0) {
      return _NoticePreviewLine(
        label: '',
        value: line,
        isParagraph: !_sectionHeadings.contains(line),
        isSectionHeading: _sectionHeadings.contains(line),
      );
    }
    return _NoticePreviewLine(
      label: line.substring(0, separator).trim(),
      value: line.substring(separator + 1).trim(),
      isParagraph: false,
      isSectionHeading: false,
    );
  }

  static const _sectionHeadings = {
    'Pledge Account and Duration',
    'Simple Interest Breakdown',
    'Compound Interest Breakdown',
    'Payments and Adjustments',
    'Final Outstanding Summary',
    'Required Action',
    'साधारण ब्याज विवरण',
    'चक्रवृद्धि ब्याज विवरण',
    'गिरवी खाता और अवधि',
    'भुगतान और समायोजन',
    'अंतिम बकाया सारांश',
    'आवश्यक कार्रवाई',
  };
}

class _CaseActions extends StatelessWidget {
  final ContactRecoveryCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback? onPrepareNotice;
  final VoidCallback? onInitiateRecovery;
  final VoidCallback? onCloseDisposal;

  const _CaseActions({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onInitiateRecovery,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          label: 'View Account',
          color: GirviColors.shellBg,
          onTap: onOpenAccount,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.primaryActionLabel,
          color: GirviColors.warning,
          onTap: _primaryAction,
        ),
        if (item.stage == ContactRecoveryStage.recoveryInProgress ||
            item.stage == ContactRecoveryStage.settled) ...[
          const SizedBox(height: 8),
          _ActionButton(
            label: item.stage == ContactRecoveryStage.settled
                ? 'Recovery Closed'
                : 'Record Recovery',
            color: item.stage == ContactRecoveryStage.settled
                ? GirviColors.success
                : GirviColors.danger,
            onTap: onCloseDisposal,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          item.stageDescription,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  VoidCallback? get _primaryAction {
    switch (item.stage) {
      case ContactRecoveryStage.firstNoticeDue:
      case ContactRecoveryStage.secondNoticeDue:
      case ContactRecoveryStage.finalNoticeDue:
        return onPrepareNotice;
      case ContactRecoveryStage.disposalReady:
        return onInitiateRecovery;
      case ContactRecoveryStage.recoveryInProgress:
      case ContactRecoveryStage.settled:
        return null;
    }
  }
}

class _StageBadge extends StatelessWidget {
  final ContactRecoveryCase item;

  const _StageBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.accentBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.38)),
      ),
      child: Text(
        item.stageLabel,
        style: GirviStyles.statusBadge.copyWith(color: item.accentColor),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: GirviColors.textHint,
              ),
            ),
            TextSpan(
              text: value,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _AmountTile({
    required this.label,
    required this.value,
    this.accent = GirviColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : GirviColors.inputBgLocked,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color : GirviColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: enabled ? Colors.white : GirviColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PreviewTitleBadge extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PreviewTitleBadge({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_rounded,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              '$title | $subtitle',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
