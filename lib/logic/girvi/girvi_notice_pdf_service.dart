import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_theme.dart';
import '../../core/pdf/girvi_recovery_watermark.dart';
import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/girvi_recovery_disposition.dart';
import 'notice_pdf/notice_statement_data.dart';
import 'notice_pdf/notice_period_display.dart';

part 'notice_pdf/notice_statement_layout.dart';
part 'notice_pdf/notice_statement_composition.dart';
part 'notice_pdf/notice_statement_finance.dart';
part 'notice_pdf/notice_statement_information.dart';

/// Renders the approved account statement and its formal notice.
/// Original downloads keep saved wording; corrected views date their figures.
class GirviNoticePdfService {
  static const defaultBranding = GirviInvoiceBranding.fallback;

  Future<Uint8List> build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    int? noticePeriodDays,
    GirviInvoiceBranding branding = defaultBranding,
    String? itemPhotoPath,
  }) =>
      _buildDocument(
        ticketNo: item.loan.ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: item.now,
        noticePeriodDays: noticePeriodDays ?? item.noticePeriodDays,
        branding: branding,
        itemPhotoPath: itemPhotoPath,
        originalLoanDurationMonths: item.loan.durationMonths,
        recoveryDisposition: item.recoveryDisposition,
      );

  Future<Uint8List> buildStoredNotice({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    required DateTime savedAt,
    DateTime? deadline,
    int? noticePeriodDays,
    GirviInvoiceBranding branding = defaultBranding,
    String? itemPhotoPath,
    Uint8List? logoBytes,
    Uint8List? signatureBytes,
    Uint8List? itemPhotoBytes,
    int? originalLoanDurationMonths,
    String? verifiedFinancialText,
    DateTime? financialAsOf,
    GirviRecoveryDisposition? recoveryDisposition,
  }) =>
      _buildDocument(
        ticketNo: ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: savedAt,
        deadline: deadline,
        noticePeriodDays: noticePeriodDays,
        branding: branding,
        itemPhotoPath: itemPhotoPath,
        logoBytes: logoBytes,
        signatureBytes: signatureBytes,
        itemPhotoBytes: itemPhotoBytes,
        originalLoanDurationMonths: originalLoanDurationMonths,
        verifiedFinancialText: verifiedFinancialText,
        financialAsOf: financialAsOf,
        recoveryDisposition: recoveryDisposition,
      );

  Future<Uint8List> _buildDocument({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
    required String noticeText,
    required DateTime savedAt,
    required GirviInvoiceBranding branding,
    String? itemPhotoPath,
    Uint8List? logoBytes,
    Uint8List? signatureBytes,
    Uint8List? itemPhotoBytes,
    int? originalLoanDurationMonths,
    DateTime? deadline,
    int? noticePeriodDays,
    String? verifiedFinancialText,
    DateTime? financialAsOf,
    GirviRecoveryDisposition? recoveryDisposition,
  }) async {
    if (language != GirviNoticeLanguage.english) {
      throw UnsupportedError('Notice PDFs are available in English only.');
    }
    final approvedStatement = NoticeStatementData.parse(noticeText, language);
    final statement = verifiedFinancialText == null || financialAsOf == null
        ? approvedStatement
        : approvedStatement.withVerifiedFinancials(
            NoticeStatementData.parse(verifiedFinancialText, language),
            asOf: financialAsOf,
          );
    final document = pw.Document(
      theme: await LotusPdfTheme.reportTheme(),
      title: '${noticeType.label} - $ticketNo',
      author: branding.printShopName,
      creator: branding.printShopName,
      subject: '${language.label} pledge account notice',
    );
    final logo = await _loadImage(branding.logoPath, approvedBytes: logoBytes);
    final signature =
        await _loadImage(branding.signaturePath, approvedBytes: signatureBytes);
    final itemPhoto =
        await _loadImage(itemPhotoPath, approvedBytes: itemPhotoBytes);
    final layout = _NoticeStatementLayout(
      statement: statement,
      language: language,
      ticketNo: ticketNo,
      noticeType: noticeType,
      savedAt: savedAt,
      deadline: deadline,
      noticePeriodDays: noticePeriodDays,
      branding: branding,
      logo: logo,
      signature: signature,
      itemPhoto: itemPhoto,
      originalLoanDurationMonths: originalLoanDurationMonths,
    );
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(26, 14, 26, 18),
          buildForeground: recoveryDisposition == null
              ? null
              : (_) => girviRecoveryWatermark(recoveryDisposition),
        ),
        header: (context) =>
            context.pageNumber == 1 ? layout.header(context) : pw.SizedBox(),
        build: (_) => [
          ...layout.summaryPage(),
          pw.NewPage(),
          ...layout.informationPage(),
        ],
      ),
    );
    return document.save();
  }

  Future<pw.MemoryImage?> _loadImage(String? source,
      {Uint8List? approvedBytes}) async {
    if (approvedBytes != null) {
      if (approvedBytes.isEmpty) return null;
      try {
        if (img.decodeImage(approvedBytes) == null) return null;
        return pw.MemoryImage(approvedBytes);
      } catch (_) {
        return null;
      }
    }
    final path = source?.trim() ?? '';
    if (path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (img.decodeImage(bytes) == null) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
