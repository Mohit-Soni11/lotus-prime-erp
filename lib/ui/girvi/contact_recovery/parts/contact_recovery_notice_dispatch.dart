part of '../contact_recovery_screen.dart';

enum _NoticeSendMethod { print, whatsapp, download }

class _NoticeSendDialog extends StatelessWidget {
  const _NoticeSendDialog();

  @override
  Widget build(BuildContext context) => SimpleDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Notice PDF',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how you want to send the notice.',
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        children: [
          _option(
            context,
            _NoticeSendMethod.print,
            Icons.print_rounded,
            'Print',
            'Open your connected printer and print now.',
          ),
          _option(
            context,
            _NoticeSendMethod.whatsapp,
            Icons.send_rounded,
            'WhatsApp',
            'Share the notice PDF with the customer.',
          ),
          _option(
            context,
            _NoticeSendMethod.download,
            Icons.download_rounded,
            'Download PDF',
            'Save a named PDF copy for later use.',
          ),
        ],
      );

  Widget _option(
    BuildContext context,
    _NoticeSendMethod method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final palette = switch (method) {
      _NoticeSendMethod.print => (
          accent: const Color(0xFFB77900),
          background: const Color(0xFFFFF6DD),
          border: const Color(0xFFF0CD76),
        ),
      _NoticeSendMethod.whatsapp => (
          accent: const Color(0xFF078A53),
          background: const Color(0xFFE7F8EF),
          border: const Color(0xFF9BDFC0),
        ),
      _NoticeSendMethod.download => (
          accent: const Color(0xFF1769D1),
          background: const Color(0xFFEAF2FF),
          border: const Color(0xFFA9C8F8),
        ),
    };

    return SimpleDialogOption(
      padding: const EdgeInsets.only(bottom: 10),
      onPressed: () => Navigator.of(context).pop(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: palette.border, width: 1.15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140E1A2B),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: palette.border),
              ),
              child: Icon(icon, color: palette.accent, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

extension _NoticeDispatch on _ContactRecoveryScreenState {
  Future<bool> _sendPreparedNotice(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String text,
    Map<GirviNoticeLanguage, String> documents,
    int days,
    _NoticeSendMethod method,
    GirviInvoiceBranding branding,
    String generatedText,
  ) async {
    try {
      final itemPhotoPath = item.itemPhotoPaths
          .where((path) => path.trim().isNotEmpty)
          .firstOrNull;
      final bytes = await (widget.noticePdfBytesBuilder?.call() ??
          _noticePdfService.build(
            item: item,
            noticeType: noticeType,
            noticeLanguage: language,
            noticeText: text,
            noticePeriodDays: days,
            branding: branding,
            itemPhotoPath: itemPhotoPath,
          ));
      final fileName = _noticeFileName(item.loan.ticketNo);
      final reference = await _dispatchNotice(
        method,
        bytes,
        fileName,
        item.loan.ticketNo,
        item.account.customerMobile,
        item.account.customerName,
        branding,
      );
      if (reference == null || !mounted) return false;

      final snapshot = await GirviNoticeBrandingSnapshot.capture(
        branding,
        itemPhotoPath: itemPhotoPath,
      );
      final saved = await _controller.recordNoticePrepared(
        item,
        noticeType,
        text,
        noticePeriodDays: days,
        autoGeneratedText: generatedText,
        noticeDocuments: documents,
        autoGeneratedDocuments: {language: generatedText},
        brandingSnapshot: snapshot,
        primaryLanguage: language,
      );
      if (!saved) {
        _controller.showInlineMessage(
          'The PDF action completed, but its notice record could not be saved. Check the account before trying again.',
        );
        return false;
      }
      final recorded = await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: noticeType,
        noticeText: text,
        noticeLanguage: language,
        actionType: switch (method) {
          _NoticeSendMethod.print => GirviNoticeActionTypes.noticePdfPrinted,
          _NoticeSendMethod.whatsapp => GirviNoticeActionTypes.noticePdfShared,
          _NoticeSendMethod.download => GirviNoticeActionTypes.noticePdfSaved,
        },
        deliveryChannel: switch (method) {
          _NoticeSendMethod.print => 'Printer',
          _NoticeSendMethod.whatsapp => 'WhatsApp',
          _NoticeSendMethod.download => 'PDF File',
        },
        deliveryStatus: switch (method) {
          _NoticeSendMethod.print => 'Printed',
          _NoticeSendMethod.whatsapp => 'Shared',
          _NoticeSendMethod.download => 'Saved',
        },
        deliveryReference: reference,
      );
      if (!recorded) {
        _controller.showInlineMessage(
          'The notice was prepared, but its PDF activity could not be recorded. Check Notice Documents.',
        );
      }
      return true;
    } catch (error) {
      _controller.showInlineMessage('Notice PDF could not be sent: $error');
      return false;
    }
  }

  Future<String?> _dispatchNotice(
    _NoticeSendMethod method,
    Uint8List bytes,
    String fileName,
    String ticketNo,
    String customerMobile,
    String customerName,
    GirviInvoiceBranding branding,
  ) async {
    final injected = widget.noticeDispatcher;
    if (injected != null) {
      return injected(method.name, bytes, fileName, customerMobile);
    }
    switch (method) {
      case _NoticeSendMethod.print:
        final printed = await Printing.layoutPdf(
          name: fileName,
          onLayout: (_) async => bytes,
        );
        return printed ? 'Printer' : null;
      case _NoticeSendMethod.download:
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Download Notice PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        if (outputPath == null) return null;
        final path = outputPath.toLowerCase().endsWith('.pdf')
            ? outputPath
            : '$outputPath.pdf';
        await File(path).writeAsBytes(bytes, flush: true);
        return path;
      case _NoticeSendMethod.whatsapp:
        final temp = await getTemporaryDirectory();
        final file = File('${temp.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);
        final result = await SharePlus.instance.share(ShareParams(
          title: 'Send Notice PDF',
          subject: 'Formal Notice - $ticketNo',
          text: _whatsAppMessage(
            customerName: customerName,
            ticketNo: ticketNo,
            shopName: branding.printShopName,
            shopPhone: branding.shopMobile,
          ),
          files: [
            XFile(file.path, mimeType: 'application/pdf', name: fileName),
          ],
          fileNameOverrides: [fileName],
        ));
        if (result.status == ShareResultStatus.dismissed) return null;
        if (!mounted) return null;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Confirm WhatsApp send',
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Was this PDF sent to the correct customer number ($customerMobile) on WhatsApp?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not sent'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sent'),
              ),
            ],
          ),
        );
        return confirmed == true ? 'WhatsApp: $customerMobile' : null;
    }
  }

  String _noticeFileName(String ticketNo) {
    final safeTicket =
        ticketNo.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'formal_notice_${safeTicket}_$today.pdf';
  }

  String _whatsAppMessage({
    required String customerName,
    required String ticketNo,
    required String shopName,
    required String shopPhone,
  }) {
    final phoneLine = shopPhone.trim().isEmpty ? '' : '\nPhone: $shopPhone';
    return 'Dear ${customerName.trim()},\n\n'
        'Please find attached the Formal Notice for Pledge Account $ticketNo. '
        'Please review it and contact $shopName within the stated response period for settlement and release of your pledged item.\n\n'
        '$shopName$phoneLine';
  }
}
