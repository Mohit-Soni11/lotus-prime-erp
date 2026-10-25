part of '../girvi_account_detail_screen.dart';

extension _GirviAccountPdfCatalogActions on _GirviAccountDetailScreenState {
  Future<GirviAccountPdfKind?> _chooseAccountPdfKind(
    GirviLoanWithCustomer account, {
    bool forPrint = false,
  }) {
    final kinds = GirviAccountPdfCatalog.available(
      account: account,
      hasFormalNotice: _controller.formalNotice != null,
    );
    return showDialog<GirviAccountPdfKind>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          forPrint ? 'Choose PDF to print' : 'Account PDFs',
          style: GoogleFonts.manrope(
            color: GirviColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 530,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final kind in kinds) ...[
                  _accountPdfChoice(dialogContext, kind),
                  if (kind != kinds.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _accountPdfChoice(
      BuildContext dialogContext, GirviAccountPdfKind kind) {
    final icon = switch (kind) {
      GirviAccountPdfKind.documentSet => Icons.folder_copy_rounded,
      GirviAccountPdfKind.originalInvoice => Icons.receipt_long_rounded,
      GirviAccountPdfKind.formalNotice => Icons.description_rounded,
    };
    return Material(
      color: GirviColors.cardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => Navigator.of(dialogContext).pop(kind),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: GirviColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: GirviColors.info, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.title,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      kind.subtitle,
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: GirviColors.textDark),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _buildAccountPdf(
    GirviLoanWithCustomer account,
    GirviAccountPdfKind kind,
  ) async {
    if (kind == GirviAccountPdfKind.originalInvoice) {
      return _buildGirviInvoicePdf(account);
    }
    if (kind == GirviAccountPdfKind.formalNotice) {
      return _buildFormalNoticePdf(account);
    }

    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: account.loan.id,
    );
    if (draft == null) {
      throw StateError('Account receipt data could not be loaded.');
    }
    return const GirviDocumentSetService().build(draft);
  }

  Future<Uint8List> _buildFormalNoticePdf(
    GirviLoanWithCustomer account,
  ) async {
    final notice = _controller.formalNotice;
    final noticeText = notice?.noticeText;
    if (notice == null ||
        noticeText == null ||
        notice.girviId != account.loan.id) {
      throw StateError('No saved formal notice exists for this account.');
    }
    final approvedBranding =
        GirviNoticeBrandingSnapshot.decode(notice.brandingSnapshot);
    if (notice.brandingSnapshot != null && approvedBranding == null) {
      throw StateError('The saved notice shop profile is invalid.');
    }
    final branding = approvedBranding ??
        await GirviInvoiceBrandingRepository(db: _db).fetch();
    final usesDeliveryPeriod =
        noticeText.contains('after receiving this notice');
    return GirviNoticePdfService().buildStoredNotice(
      ticketNo: account.loan.ticketNo,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: noticeText,
      savedAt: notice.actionAt,
      deadline: usesDeliveryPeriod ? null : notice.noticeDeadlineAt,
      noticePeriodDays: usesDeliveryPeriod
          ? GirviNoticeReviewPeriod.duration(
              approvedAt: notice.actionAt,
              approvedDeadline: notice.noticeDeadlineAt,
              fallbackDays: 7,
            ).inDays
          : null,
      branding: branding,
      itemPhotoPath:
          await NoticeItemPhotoResolver(_db).resolve(account.loan.id),
      logoBytes: GirviNoticeBrandingSnapshot.assetBytes(
        notice.brandingSnapshot,
        'logoBytes',
      ),
      signatureBytes: GirviNoticeBrandingSnapshot.assetBytes(
        notice.brandingSnapshot,
        'signatureBytes',
      ),
      itemPhotoBytes: GirviNoticeBrandingSnapshot.assetBytes(
        notice.brandingSnapshot,
        'itemPhotoBytes',
      ),
      originalLoanDurationMonths: account.loan.durationMonths,
      recoveryDisposition: GirviRecoveryDisposition.fromDb(
        _controller.recoveryClosure?.disposition,
      ),
    );
  }
}
