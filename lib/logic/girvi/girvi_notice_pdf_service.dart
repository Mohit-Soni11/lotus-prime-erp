import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_theme.dart';
import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/girvi_notice_history.dart';
import 'notice_pdf/notice_statement_data.dart';

part 'notice_pdf/notice_statement_layout.dart';
part 'notice_pdf/notice_statement_composition.dart';
part 'notice_pdf/notice_statement_finance.dart';
part 'notice_pdf/notice_statement_information.dart';

/// Renders approved wording as a branded statement. Original downloads keep
/// the saved text; an updated view may show separately dated verified figures.
class GirviNoticePdfService {
  static const defaultBranding = GirviInvoiceBranding.fallback;

  Future<Uint8List> build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    GirviInvoiceBranding branding = defaultBranding,
    String? itemPhotoPath,
  }) =>
      _buildDocument(
        ticketNo: item.loan.ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: item.now,
        deadline: item.now.add(Duration(days: item.noticePeriodDays)),
        branding: branding,
        itemPhotoPath: itemPhotoPath,
        originalLoanDurationMonths: item.loan.durationMonths,
      );

  Future<Uint8List> buildStoredNotice({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    required DateTime savedAt,
    DateTime? deadline,
    int? legacyNoticeStage,
    GirviInvoiceBranding branding = defaultBranding,
    String? itemPhotoPath,
    int? originalLoanDurationMonths,
    String? verifiedFinancialText,
    DateTime? financialAsOf,
  }) =>
      _buildDocument(
        ticketNo: ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: savedAt,
        deadline: deadline,
        legacyNoticeStage: legacyNoticeStage,
        branding: branding,
        itemPhotoPath: itemPhotoPath,
        originalLoanDurationMonths: originalLoanDurationMonths,
        verifiedFinancialText: verifiedFinancialText,
        financialAsOf: financialAsOf,
      );

  Future<Uint8List> _buildDocument({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
    required String noticeText,
    required DateTime savedAt,
    required GirviInvoiceBranding branding,
    String? itemPhotoPath,
    int? originalLoanDurationMonths,
    DateTime? deadline,
    int? legacyNoticeStage,
    String? verifiedFinancialText,
    DateTime? financialAsOf,
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
    final logo = await _loadImage(branding.logoPath);
    final signature = await _loadImage(branding.signaturePath);
    final itemPhoto = await _loadImage(itemPhotoPath);
    final layout = _NoticeStatementLayout(
      statement: statement,
      language: language,
      ticketNo: ticketNo,
      noticeType: noticeType,
      savedAt: savedAt,
      deadline: deadline,
      legacyNoticeStage: legacyNoticeStage,
      branding: branding,
      logo: logo,
      signature: signature,
      itemPhoto: itemPhoto,
      originalLoanDurationMonths: originalLoanDurationMonths,
    );
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(26, 20, 26, 28),
        ),
        header: layout.header,
        footer: layout.footer,
        build: (_) => layout.summaryPage(),
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(26, 20, 26, 28),
        ),
        header: layout.header,
        footer: layout.footer,
        build: (_) => layout.informationPage(),
      ),
    );
    return document.save();
  }

  Future<pw.MemoryImage?> _loadImage(String? source) async {
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
