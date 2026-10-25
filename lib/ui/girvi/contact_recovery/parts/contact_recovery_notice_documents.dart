part of '../contact_recovery_screen.dart';

extension _NoticeDocuments on _ContactRecoveryScreenState {
  Future<void> _previewPreparedNotice(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
    int noticePeriodDays,
    GirviInvoiceBranding branding,
  ) async {
    try {
      final itemPhotoPath =
          await _noticeItemPhotoResolver.resolve(item.loan.id);
      final bytes = await _noticePdfService.build(
        item: item,
        noticeType: noticeType,
        noticeLanguage: language,
        noticeText: noticeText,
        noticePeriodDays: noticePeriodDays,
        branding: branding,
        itemPhotoPath: itemPhotoPath,
      );
      if (!mounted) return;
      await _showNoticePreview(
        title: '${noticeType.label} PDF',
        subtitle: '${item.loan.ticketNo} · ${language.label} preview',
        bytes: bytes,
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${noticeType.label} PDF preview could not be generated.',
      );
    }
  }

  Future<void> _viewSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    await _controller.load();
    if (!mounted) return;
    if (_controller.state.errorMessage != null) return;
    final currentItem = _controller.state.allCases
        .where((entry) => entry.loan.id == item.loan.id)
        .firstOrNull;
    if (currentItem == null) {
      _controller.showInlineMessage(
        'This pledge account is no longer in Notice and Recovery.',
      );
      return;
    }
    final currentAction = currentItem.actionHistory
            .where((entry) => entry.id == action.id)
            .firstOrNull ??
        action;
    final drafts = _savedNoticeDrafts(currentItem, currentAction);
    if (drafts.isEmpty) {
      _controller.showInlineMessage(
        'No approved notice text is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }
    final draft = drafts[GirviNoticeLanguage.english];
    if (draft == null) {
      _controller.showInlineMessage(
        'No approved English notice is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }
    try {
      final requiresCorrectedView =
          _approvedNoticeUsesSupersededSimple(draft, currentItem);
      final hasVerifiedCompoundTimeline =
          currentItem.interestPeriodSnapshots.isNotEmpty &&
              currentItem.interestPeriodSnapshots.every(
                (period) =>
                    GirviInterestCalculationType.normalize(
                      period.interestType,
                    ) ==
                    GirviInterestCalculationType.compound,
              );
      String? verifiedFinancialText;
      if (requiresCorrectedView) {
        if (!hasVerifiedCompoundTimeline) {
          _controller.showInlineMessage(
            'The account requires Compound Interest. Refresh the pledge ledger before viewing its corrected notice.',
          );
          return;
        }
        final generator = GirviNoticeGenerationService(now: currentItem.now);
        final issues = generator.validate(currentItem);
        if (issues.isNotEmpty) {
          _controller.showInlineMessage(
            'The corrected account statement could not be verified: ${issues.first}',
          );
          return;
        }
        verifiedFinancialText = generator.build(
          item: currentItem,
          noticeType: draft.noticeType,
          language: draft.language,
        );
      }
      final bytes = await _buildSavedNoticePdf(
        draft,
        verifiedFinancialText: verifiedFinancialText,
        financialAsOf: requiresCorrectedView ? currentItem.now : null,
      );
      if (!mounted) return;
      await _showNoticePreview(
        title: requiresCorrectedView
            ? '${action.noticeLabel} · Updated Financial View'
            : '${action.noticeLabel} PDF',
        subtitle: currentItem.loan.ticketNo,
        bytes: bytes,
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${action.noticeLabel} PDF could not be generated.',
      );
    }
  }

  bool _approvedNoticeUsesSupersededSimple(
    _SavedNoticeDraft draft,
    ContactRecoveryCase item,
  ) =>
      NoticeStatementData.parse(draft.noticeText, draft.language).isSimple &&
      GirviLoanModel.chargeableMonthsBetween(
            item.loan.startDate,
            item.loan.releaseDate ?? item.now,
          ) >
          GirviLoanModel.compoundCycleMonths;

  Future<bool> _canDeliverApprovedNotice(_SavedNoticeDraft draft) async {
    await _controller.load();
    if (!mounted || _controller.state.errorMessage != null) return false;
    final currentItem = _controller.state.allCases
        .where((entry) => entry.loan.id == draft.item.loan.id)
        .firstOrNull;
    if (currentItem == null) {
      _controller.showInlineMessage(
        'This pledge account is no longer in Notice and Recovery.',
      );
      return false;
    }
    if (_approvedNoticeUsesSupersededSimple(draft, currentItem)) {
      _controller.showInlineMessage(
        'This approved notice has outdated Simple Interest figures. Prepare and approve a corrected Compound Interest notice before saving or printing.',
      );
      return false;
    }
    return true;
  }

  Map<GirviNoticeLanguage, _SavedNoticeDraft> _savedNoticeDrafts(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) {
    final drafts = <GirviNoticeLanguage, _SavedNoticeDraft>{};
    for (final document in item.documentsForNoticeAction(action.id)) {
      if (document.language != GirviNoticeLanguage.english ||
          document.noticeText.trim().isEmpty) {
        continue;
      }
      drafts[document.language] =
          _savedNoticeDraft(item, action, document: document);
    }
    final approvedText = action.noticeText?.trim() ?? '';
    if (drafts.isEmpty && approvedText.isNotEmpty) {
      final draft = _savedNoticeDraft(item, action);
      if (draft.language == GirviNoticeLanguage.english) {
        drafts[draft.language] = draft;
      }
    }
    return drafts;
  }

  Future<_SavedNoticeDraft?> _chooseSavedNoticeDraft(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final drafts = _savedNoticeDrafts(item, action);
    if (drafts.isEmpty) {
      _controller.showInlineMessage(
        'No approved notice text is available for ticket ${item.loan.ticketNo}.',
      );
      return null;
    }
    return drafts[GirviNoticeLanguage.english];
  }

  Future<Uint8List> _buildSavedNoticePdf(_SavedNoticeDraft draft,
      {String? verifiedFinancialText, DateTime? financialAsOf}) async {
    final approvedBranding = GirviNoticeBrandingSnapshot.decode(
      draft.action.brandingSnapshot,
    );
    if (draft.action.brandingSnapshot != null && approvedBranding == null) {
      throw StateError('The approved shop profile snapshot is invalid.');
    }
    final branding =
        approvedBranding ?? await _noticeBrandingRepository.fetch();
    final itemPhotoPath =
        await _noticeItemPhotoResolver.resolve(draft.item.loan.id);
    final usesDeliveryPeriod =
        draft.noticeText.contains('after receiving this notice');
    return _noticePdfService.buildStoredNotice(
      ticketNo: draft.item.loan.ticketNo,
      noticeType: draft.noticeType,
      noticeLanguage: draft.language,
      noticeText: draft.noticeText,
      savedAt: draft.action.actionAt,
      deadline: usesDeliveryPeriod ? null : draft.action.noticeDeadlineAt,
      noticePeriodDays: usesDeliveryPeriod
          ? GirviNoticeReviewPeriod.duration(
              approvedAt: draft.action.actionAt,
              approvedDeadline: draft.action.noticeDeadlineAt,
              fallbackDays: draft.item.noticePeriodDays,
            ).inDays
          : null,
      branding: branding,
      itemPhotoPath: itemPhotoPath,
      logoBytes: GirviNoticeBrandingSnapshot.assetBytes(
          draft.action.brandingSnapshot, 'logoBytes'),
      signatureBytes: GirviNoticeBrandingSnapshot.assetBytes(
          draft.action.brandingSnapshot, 'signatureBytes'),
      itemPhotoBytes: GirviNoticeBrandingSnapshot.assetBytes(
          draft.action.brandingSnapshot, 'itemPhotoBytes'),
      originalLoanDurationMonths: draft.item.loan.durationMonths,
      verifiedFinancialText: verifiedFinancialText,
      financialAsOf: financialAsOf,
      recoveryDisposition: draft.item.recoveryDisposition,
    );
  }

  Future<void> _downloadSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = await _chooseSavedNoticeDraft(item, action);
    if (draft == null) return;
    if (!await _canDeliverApprovedNotice(draft)) return;
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${draft.action.noticeLabel}',
        fileName: draft.fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';
      final bytes = await _buildSavedNoticePdf(draft);
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
      final proofRecorded = await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: draft.noticeType,
        noticeText: draft.noticeText,
        noticeLanguage: draft.language,
        noticeActionId: draft.action.id,
        actionType: GirviNoticeActionTypes.noticePdfSaved,
        deliveryChannel: 'PDF File',
        deliveryStatus: 'Saved',
        deliveryReference: normalizedPath,
      );
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} (${draft.language.label}) PDF saved for ticket ${item.loan.ticketNo}.${proofRecorded ? '' : ' Saving the audit record failed; the PDF file was saved.'}',
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} PDF could not be saved.',
      );
    }
  }

  Future<void> _printSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = await _chooseSavedNoticeDraft(item, action);
    if (draft == null) return;
    if (!await _canDeliverApprovedNotice(draft)) return;
    try {
      final bytes = await _buildSavedNoticePdf(draft);
      final printed = await Printing.layoutPdf(
        name: draft.fileName,
        onLayout: (_) async => bytes,
      );
      if (printed) {
        final proofRecorded = await _controller.recordNoticeDeliveryProof(
          item: item,
          noticeType: draft.noticeType,
          noticeText: draft.noticeText,
          noticeLanguage: draft.language,
          noticeActionId: draft.action.id,
          actionType: GirviNoticeActionTypes.noticePdfPrinted,
          deliveryChannel: 'Printer',
          deliveryStatus: 'Printed',
        );
        _controller.showInlineMessage(
          '${draft.action.noticeLabel} (${draft.language.label}) PDF sent to printer for ticket ${item.loan.ticketNo}.${proofRecorded ? '' : ' Saving the audit record failed.'}',
        );
      }
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} PDF could not be printed.',
      );
    }
  }
}
