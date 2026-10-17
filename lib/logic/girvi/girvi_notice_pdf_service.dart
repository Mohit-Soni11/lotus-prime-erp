import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_theme.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/girvi_notice_history.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/contact_recovery_model.dart';

part 'notice_pdf/notice_pdf_header.dart';
part 'notice_pdf/notice_pdf_body.dart';
part 'notice_pdf/notice_pdf_style.dart';
part 'notice_pdf/notice_pdf_account_summary.dart';
part 'notice_pdf/notice_pdf_signature.dart';

/// September 29 layout (69c7957f), with pagination for current notice content.
class GirviNoticePdfService {
  Future<Uint8List> build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
  }) =>
      _buildDocument(
        ticketNo: item.loan.ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: item.now,
        item: item,
      );

  /// Saved notices never read today's account balance or customer response data.
  Future<Uint8List> buildStoredNotice({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    required DateTime savedAt,
    int? legacyNoticeStage,
  }) =>
      _buildDocument(
        ticketNo: ticketNo,
        noticeType: noticeType,
        language: noticeLanguage,
        noticeText: noticeText,
        savedAt: savedAt,
        legacyNoticeStage: legacyNoticeStage,
      );

  Future<Uint8List> _buildDocument({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
    required String noticeText,
    required DateTime savedAt,
    ContactRecoveryCase? item,
    int? legacyNoticeStage,
  }) async {
    final font = language == GirviNoticeLanguage.hindi
        ? await LotusPdfTheme.loadDevanagariFont()
        : null;
    final document = pw.Document(
      theme: await LotusPdfTheme.reportTheme(),
      title: '${noticeType.label} - $ticketNo',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: '${item == null ? 'Stored ' : ''}${language.label} Girvi notice',
    );
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => [
          if (item == null)
            _storedNoticeHeader(ticketNo, noticeType, language, font, savedAt,
                legacyNoticeStage)
          else ...[
            _header(item, noticeType, language, font),
            pw.SizedBox(height: 10),
            _accountSummary(item, noticeType, language, font),
          ],
          pw.SizedBox(height: 10),
          ..._noticeBodyWidgets(
            _noticeTextWithoutValuation(noticeText),
            language,
            font,
          ),
          pw.SizedBox(height: 20),
          _signatureBlock(language, font),
        ],
        footer: _footer,
      ),
    );
    return document.save();
  }
}
