import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../../logic/purchase/purchase_entry_controller.dart';
import '../../domain/print_template_pdf_profile.dart';
import 'purchase_voucher_template_context.dart';

class PurchaseVoucherPdfLayoutEngine {
  PurchaseVoucherPdfLayoutEngine._();

  static const double _policyTextMaxWidth = 500;
  static Future<void> warmPolicyText(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    LotusPdfTextRenderer textRenderer,
    PrintTemplatePdfProfile style,
  ) {
    return _warmPolicyText(settingsByMetal, textRenderer, style);
  }

  static List<pw.Widget> buildClassicOrEconomy(
    PurchaseVoucherTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    final templateProfile = context.templateProfile;
    final visibleColumns = _visibleColumns(
      context.lines,
      context.settingsByMetal,
    );
    return [
      if (isDuplicateCopy) _duplicateStamp(templateProfile),
      _shopHeader(
        profile: context.shopProfile,
        style: templateProfile,
        documentTitle: context.documentTitle,
        documentSubtitle:
            '${context.sourceLabel} | ${context.selectedTemplate.shortName}',
        documentNumber: context.documentNumber,
        documentDate: context.documentDate,
      ),
      pw.SizedBox(height: templateProfile.sectionGap),
      _counterpartyPanel(context.controller, templateProfile),
      pw.SizedBox(height: templateProfile.sectionGap),
      _purchaseItemsTable(context.lines, visibleColumns, templateProfile),
      pw.SizedBox(height: templateProfile.sectionGap),
      _summaryPanel(context.controller, templateProfile),
      ..._policySections(
        context.settingsByMetal,
        context.textRenderer,
        templateProfile,
      ),
      _footer(context.settingsByMetal, templateProfile),
    ];
  }

  static List<pw.Widget> buildSignature(
    PurchaseVoucherTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    final templateProfile = context.templateProfile;
    final visibleColumns = _visibleColumns(
      context.lines,
      context.settingsByMetal,
    );
    return [
      if (isDuplicateCopy) _duplicateStamp(templateProfile),
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: templateProfile.accentColor, width: 0.9),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _signatureHeader(
              profile: context.shopProfile,
              style: templateProfile,
              documentTitle: context.documentTitle,
              documentSubtitle:
                  '${context.sourceLabel} | ${context.selectedTemplate.shortName}',
              documentNumber: context.documentNumber,
              documentDate: _displayDate(context.documentDate),
            ),
            pw.SizedBox(height: 14),
            _signatureSellerAndVoucherDetails(
              ctrl: context.controller,
              style: templateProfile,
              documentNumber: context.documentNumber,
              documentDate: _displayDate(context.documentDate),
              sourceLabel: context.sourceLabel,
            ),
            pw.SizedBox(height: 14),
            _sectionTitle('CUSTOMER METAL ITEMS', templateProfile),
            pw.SizedBox(height: 8),
            _purchaseItemsTable(context.lines, visibleColumns, templateProfile),
            pw.SizedBox(height: 14),
            _signaturePaymentAndTotals(context.controller, templateProfile),
          ],
        ),
      ),
      ..._policySections(
        context.settingsByMetal,
        context.textRenderer,
        templateProfile,
      ),
      _footer(context.settingsByMetal, templateProfile),
    ];
  }

  static pw.Widget _summaryRow(
    String label,
    double value, {
    bool emphasize = false,
    required PrintTemplatePdfProfile style,
  }) {
    return _summaryTextRow(
      label,
      'Rs. ${value.toStringAsFixed(2)}',
      emphasize: emphasize,
      style: style,
    );
  }

  static pw.Widget _duplicateStamp(PrintTemplatePdfProfile style) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: style.duplicateStampColor,
        border: pw.Border.all(color: style.accentColor, width: 0.8),
      ),
      child: pw.Text(
        'DUPLICATE COPY',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: style.duplicateStampTextColor,
        ),
      ),
    );
  }

  static pw.Widget _purchaseItemsTable(
    List<PurchaseItemModel> lines,
    List<_PurchaseVoucherColumn> visibleColumns,
    PrintTemplatePdfProfile style,
  ) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(
        color: style.tableHeaderColor,
      ),
      headerStyle: pw.TextStyle(
        color: style.tableHeaderTextColor,
        fontSize: style.tableFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: style.bodyTextColor,
        fontSize: style.tableFontSize,
        fontWeight:
            style.isSignature ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.all(style.tableCellPadding),
      border: pw.TableBorder.all(
        color: style.tableBorderColor,
        width: style.tableBorderWidth,
      ),
      headers:
          visibleColumns.map((column) => column.label).toList(growable: false),
      data: lines.asMap().entries.map((entry) {
        return _purchaseLineCells(
          serial: entry.key + 1,
          item: entry.value,
          columns: visibleColumns,
        );
      }).toList(),
    );
  }

  static pw.Widget _signatureHeader({
    required ShopPrintDocumentProfile profile,
    required PrintTemplatePdfProfile style,
    required String documentTitle,
    required String documentSubtitle,
    required String documentNumber,
    required String documentDate,
  }) {
    final shopName =
        profile.primaryName.isEmpty ? 'Lotus ERP' : profile.primaryName;
    final address = profile.primaryAddress;
    final phone = _shopPhoneLine(profile);
    final email = profile.valueOf('business_email');
    final gstin = profile.gstin;
    final bis = profile.valueOf('bis_license');

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: style.accentColor, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 124,
            padding: const pw.EdgeInsets.only(right: 14),
            child: _brandMark(profile, style),
          ),
          pw.Container(width: 1, height: 124, color: style.borderColor),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                          color: style.bodyTextColor,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (address.isNotEmpty)
                        _headerInfoLine(
                          'location',
                          _compactAddress(address),
                          style,
                        ),
                      if (phone.isNotEmpty)
                        _headerInfoLine('phone', phone, style),
                      if (email.isNotEmpty)
                        _headerInfoLine('mail', email, style),
                      if (gstin.isNotEmpty)
                        _headerInfoLine('gst', 'GSTIN: $gstin', style),
                      if (bis.isNotEmpty) _headerInfoLine('gst', bis, style),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Container(
                  width: 150,
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        documentTitle,
                        textAlign: pw.TextAlign.right,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 16.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                          color: style.bodyTextColor,
                        ),
                      ),
                      pw.Container(
                        width: 58,
                        height: 1,
                        margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
                        color: style.accentColor,
                      ),
                      pw.Text(
                        'PURCHASE VOUCHER',
                        style: pw.TextStyle(
                          fontSize: 10.8,
                          fontWeight: pw.FontWeight.bold,
                          color: style.accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 13),
                      _invoiceMeta('Voucher No.', documentNumber, style),
                      _invoiceMeta('Voucher Date', documentDate, style),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureSellerAndVoucherDetails({
    required PurchaseEntryController ctrl,
    required PrintTemplatePdfProfile style,
    required String documentNumber,
    required String documentDate,
    required String sourceLabel,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _outlinedBox(
            'SELLER DETAILS',
            [
              _detailLine(
                'customer',
                'Seller Name',
                ctrl.nameCtrl.text.trim().isEmpty
                    ? 'Walk-in Seller'
                    : ctrl.nameCtrl.text.trim(),
                style,
              ),
              if (ctrl.mobileCtrl.text.trim().isNotEmpty)
                _detailLine(
                    'phone', 'Mobile', ctrl.mobileCtrl.text.trim(), style),
              if (ctrl.cityCtrl.text.trim().isNotEmpty)
                _addressDetailLine(ctrl.cityCtrl.text.trim(), style),
              if (ctrl.panCtrl.text.trim().isNotEmpty)
                _detailLine(
                  'gst',
                  'PAN / Aadhaar ID',
                  ctrl.panCtrl.text.trim(),
                  style,
                  showDivider: false,
                ),
            ],
            style,
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _outlinedBox(
            'VOUCHER DETAILS',
            [
              _detailLine('invoice', 'Voucher No.', documentNumber, style),
              _detailLine('calendar', 'Date', documentDate, style),
              _detailLine('items', 'Purchase Type', sourceLabel, style),
              _detailLine(
                'status',
                'Payout Status',
                ctrl.hasPendingSellerPayout ? 'PENDING' : 'SETTLED',
                style,
                valueColor: ctrl.hasPendingSellerPayout
                    ? const PdfColor.fromInt(0xFFB91C1C)
                    : const PdfColor.fromInt(0xFF166534),
                showDivider: false,
              ),
            ],
            style,
          ),
        ),
      ],
    );
  }

  static pw.Widget _signaturePaymentAndTotals(
    PurchaseEntryController ctrl,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _outlinedBox(
            'SELLER PAYOUT',
            [
              _pair('Cash Payout', _money(ctrl.cashPaid), style),
              _pair('UPI / Bank Payout', _money(ctrl.upiPaid), style),
              _pair('Card Payout', _money(ctrl.cardPaid), style),
              _pair('Payout Released', _money(ctrl.totalPaid), style),
            ],
            style,
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _outlinedBox(
            'AMOUNT SUMMARY',
            [
              _summaryLine(
                'Assessed Metal Value',
                _money(ctrl.grossPurchaseAmount),
                style,
              ),
              pw.Divider(color: style.borderColor),
              _summaryLine(
                'Seller Payable',
                _money(ctrl.grandTotal),
                style,
                strong: true,
              ),
              _summaryLine(
                _payoutBalanceLabel(ctrl),
                _money(ctrl.balanceDue.abs()),
                style,
                strong: true,
              ),
              if (ctrl.hasPendingSellerPayout &&
                  ctrl.payoutCommitmentDate != null)
                _summaryLine(
                  'Payout Commitment',
                  PurchaseEntryController.formatDisplayDate(
                    ctrl.payoutCommitmentDate!,
                  ),
                  style,
                ),
            ],
            style,
          ),
        ),
      ],
    );
  }

  static pw.Widget _brandMark(
    ShopPrintDocumentProfile profile,
    PrintTemplatePdfProfile style,
  ) {
    final logo = _loadLogoImage(profile.logoPath);
    if (logo != null) {
      return pw.Container(
        height: 94,
        width: 104,
        alignment: pw.Alignment.center,
        child: pw.Image(
          logo,
          fit: pw.BoxFit.contain,
          alignment: pw.Alignment.center,
        ),
      );
    }

    final shopName =
        profile.primaryName.isEmpty ? 'Lotus ERP' : profile.primaryName;
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 46,
          height: 46,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: style.accentColor, width: 1),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            _initials(shopName),
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: style.accentColor,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _firstBrandWord(shopName),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 19,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
            color: style.accentColor,
          ),
        ),
        pw.Text(
          'JEWELLERS',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            letterSpacing: 2,
            color: style.accentColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _outlinedBox(
    String title,
    List<pw.Widget> children,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: style.borderColor, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, style),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PrintTemplatePdfProfile style) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 24,
          height: 24,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: style.accentColor, width: 0.8),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.SvgImage(svg: _headerIconSvg(_sectionIconKey(title))),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.2,
            fontWeight: pw.FontWeight.bold,
            color: style.accentColor,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  static pw.Widget _detailLine(
    String iconKey,
    String label,
    String value,
    PrintTemplatePdfProfile style, {
    PdfColor? valueColor,
    bool showDivider = true,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: showDivider
            ? pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: style.borderColor, width: 0.45),
                ),
              )
            : null,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _iconBadge(iconKey, style),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 82,
              child: pw.Text(
                label,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 9.8,
                  fontWeight: pw.FontWeight.bold,
                  color: style.bodyTextColor,
                ),
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Text(
              ':',
              style: pw.TextStyle(
                fontSize: 10.1,
                fontWeight: pw.FontWeight.bold,
                color: style.bodyTextColor,
              ),
            ),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Text(
                value,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10.4,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor ?? style.bodyTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _addressDetailLine(
    String value,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: style.borderColor, width: 0.45),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _iconBadge('location', style),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Address',
                  style: pw.TextStyle(
                    fontSize: 9.8,
                    fontWeight: pw.FontWeight.bold,
                    color: style.bodyTextColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 27),
              child: pw.Text(
                value,
                maxLines: 4,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10.2,
                  fontWeight: pw.FontWeight.bold,
                  color: style.bodyTextColor,
                  lineSpacing: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pair(
    String label,
    String value,
    PrintTemplatePdfProfile style, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: style.bodyTextColor,
              ),
            ),
          ),
          pw.Text(
            ':',
            style: pw.TextStyle(
              fontSize: 10.2,
              fontWeight: pw.FontWeight.bold,
              color: style.bodyTextColor,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 108,
            child: pw.Text(
              value,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? style.bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryLine(
    String label,
    String value,
    PrintTemplatePdfProfile style, {
    bool strong = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: strong ? 13.2 : 10.4,
              fontWeight: pw.FontWeight.bold,
              color: style.bodyTextColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: strong ? 13.6 : 10.4,
              fontWeight: pw.FontWeight.bold,
              color: strong ? style.accentColor : style.bodyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerInfoLine(
    String iconKey,
    String value,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _iconBadge(iconKey, style, size: 18, padding: 3),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: style.bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _invoiceMeta(
    String label,
    String value,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: style.bodyTextColor,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            ':',
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: style.bodyTextColor,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 74,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.left,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.7,
                fontWeight: pw.FontWeight.bold,
                color: style.bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _iconBadge(
    String iconKey,
    PrintTemplatePdfProfile style, {
    double size = 19,
    double padding = 3.2,
  }) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: style.accentColor, width: 0.7),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Padding(
        padding: pw.EdgeInsets.all(padding),
        child: pw.SvgImage(svg: _headerIconSvg(iconKey)),
      ),
    );
  }

  static pw.MemoryImage? _loadLogoImage(String? rawPath) {
    final path = rawPath?.trim() ?? '';
    if (path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static String _shopPhoneLine(ShopPrintDocumentProfile profile) {
    final primary = profile.primaryPhone.trim();
    final helpDesk = profile.valueOf('help_desk_number').trim();
    final phones = <String>[
      if (primary.isNotEmpty) _formatPhone(primary),
      if (helpDesk.isNotEmpty && _digitsOnly(helpDesk) != _digitsOnly(primary))
        _formatPhone(helpDesk),
    ];
    return phones.join('  |  ');
  }

  static String _formatPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('+')) return trimmed;
    final digits = _digitsOnly(trimmed);
    if (digits.length == 10) return '+91 $digits';
    return trimmed;
  }

  static String _compactAddress(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _displayDate(String ddmmyyyy) {
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return ddmmyyyy;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = parts[2];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (day == null || month == null || month < 1 || month > 12) {
      return ddmmyyyy;
    }
    return '${day.toString().padLeft(2, '0')} ${monthNames[month - 1]} $year';
  }

  static String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(2)}';
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String _initials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'LE';
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  static String _firstBrandWord(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    return words.isEmpty ? 'LOTUS' : words.first.toUpperCase();
  }

  static String _sectionIconKey(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('seller')) return 'customer';
    if (normalized.contains('voucher')) return 'invoice';
    if (normalized.contains('item')) return 'items';
    if (normalized.contains('payout')) return 'payment';
    if (normalized.contains('amount')) return 'amount';
    if (normalized.contains('terms')) return 'policy';
    return 'invoice';
  }

  static String _headerIconSvg(String iconKey) {
    const stroke = '#B8781A';
    switch (iconKey) {
      case 'location':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 21s6-5.2 6-11a6 6 0 0 0-12 0c0 5.8 6 11 6 11z"/>
  <circle cx="12" cy="10" r="2.2"/>
</svg>
''';
      case 'phone':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.7 19.7 0 0 1-8.6-3.1 19.1 19.1 0 0 1-5.9-5.9A19.7 19.7 0 0 1 2.2 4.2 2 2 0 0 1 4.2 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7A2 2 0 0 1 22 16.9z"/>
</svg>
''';
      case 'mail':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="5" width="18" height="14" rx="2"/>
  <path d="m3 7 9 6 9-6"/>
</svg>
''';
      case 'gst':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="4" y="3" width="16" height="18" rx="2"/>
  <path d="M8 8h8"/>
  <path d="M8 12h8"/>
  <path d="M8 16h4"/>
</svg>
''';
      case 'customer':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20 21a8 8 0 0 0-16 0"/>
  <circle cx="12" cy="7" r="4"/>
</svg>
''';
      case 'calendar':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="5" width="18" height="16" rx="2"/>
  <path d="M16 3v4"/>
  <path d="M8 3v4"/>
  <path d="M3 10h18"/>
</svg>
''';
      case 'status':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <path d="m8 12 2.5 2.5L16 9"/>
</svg>
''';
      case 'items':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21 8-9-5-9 5 9 5 9-5z"/>
  <path d="M3 8v8l9 5 9-5V8"/>
  <path d="M12 13v8"/>
</svg>
''';
      case 'payment':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="6" width="18" height="12" rx="2"/>
  <path d="M3 10h18"/>
  <path d="M7 15h4"/>
</svg>
''';
      case 'amount':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="4" y="3" width="16" height="18" rx="2"/>
  <path d="M8 8h8"/>
  <path d="M8 12h8"/>
  <path d="M8 16h5"/>
</svg>
''';
      case 'invoice':
      default:
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 3h10l3 3v15H4V3h3z"/>
  <path d="M16 3v4h4"/>
  <path d="M8 11h8"/>
  <path d="M8 15h6"/>
</svg>
''';
    }
  }

  static pw.Widget _counterpartyPanel(
    PurchaseEntryController ctrl,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(style.panelPadding),
      decoration: pw.BoxDecoration(
        color: style.panelColor,
        border: pw.Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(style.radius)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SELLER DETAILS',
            style: pw.TextStyle(
              color: style.accentColor,
              fontSize: style.labelFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            ctrl.nameCtrl.text.trim().isEmpty ? '-' : ctrl.nameCtrl.text.trim(),
            style: pw.TextStyle(
              color: style.bodyTextColor,
              fontSize: style.bodyFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (ctrl.mobileCtrl.text.trim().isNotEmpty)
            pw.Text(
              'Mobile: ${ctrl.mobileCtrl.text.trim()}',
              style: pw.TextStyle(
                color: style.bodyTextColor,
                fontSize: style.bodyFontSize,
              ),
            ),
          if (ctrl.cityCtrl.text.trim().isNotEmpty)
            pw.Text(
              'Address: ${ctrl.cityCtrl.text.trim()}',
              style: pw.TextStyle(
                color: style.bodyTextColor,
                fontSize: style.bodyFontSize,
              ),
            ),
          if (ctrl.panCtrl.text.trim().isNotEmpty)
            pw.Text(
              'PAN / ID: ${ctrl.panCtrl.text.trim()}',
              style: pw.TextStyle(
                color: style.bodyTextColor,
                fontSize: style.bodyFontSize,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _summaryPanel(
    PurchaseEntryController ctrl,
    PrintTemplatePdfProfile style,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: style.summaryWidth,
        padding: pw.EdgeInsets.all(style.panelPadding),
        decoration: pw.BoxDecoration(
          color: style.summaryColor,
          border: pw.Border.all(
            color: style.borderColor,
            width: style.borderWidth,
          ),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(style.radius)),
        ),
        child: pw.Column(
          children: [
            _summaryRow(
              'Assessed Metal Value',
              ctrl.grossPurchaseAmount,
              style: style,
            ),
            pw.Divider(color: style.borderColor),
            _summaryRow(
              'Seller Payable',
              ctrl.grandTotal,
              emphasize: true,
              style: style,
            ),
            _summaryRow('Cash Payout', ctrl.cashPaid, style: style),
            _summaryRow('UPI / Bank Payout', ctrl.upiPaid, style: style),
            _summaryRow('Card Payout', ctrl.cardPaid, style: style),
            _summaryRow('Payout Released', ctrl.totalPaid, style: style),
            pw.Divider(color: style.borderColor),
            _summaryRow(
              _payoutBalanceLabel(ctrl),
              ctrl.balanceDue.abs(),
              emphasize: true,
              style: style,
            ),
            if (ctrl.hasPendingSellerPayout &&
                ctrl.payoutCommitmentDate != null)
              _summaryTextRow(
                'Payout Commitment',
                PurchaseEntryController.formatDisplayDate(
                  ctrl.payoutCommitmentDate!,
                ),
                emphasize: true,
                style: style,
              ),
          ],
        ),
      ),
    );
  }

  static List<_PurchaseVoucherColumn> _visibleColumns(
    List<PurchaseItemModel> lines,
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    bool enabled(bool Function(PurchaseBillingModel settings) read) {
      if (lines.isEmpty) return true;
      return lines
          .any((item) => read(_settingsFor(item.metal, settingsByMetal)));
    }

    return [
      const _PurchaseVoucherColumn.serial(),
      const _PurchaseVoucherColumn.metal(),
      const _PurchaseVoucherColumn.description(),
      if (enabled((settings) => settings.showGrossWeight))
        const _PurchaseVoucherColumn.gross(),
      if (enabled((settings) => settings.showLessWeight))
        const _PurchaseVoucherColumn.less(),
      if (enabled((settings) => settings.showNetWeight))
        const _PurchaseVoucherColumn.net(),
      if (enabled((settings) => settings.showPurity))
        const _PurchaseVoucherColumn.purity(),
      if (enabled((settings) => settings.showFineWeight))
        const _PurchaseVoucherColumn.fine(),
      if (enabled((settings) => settings.showRate))
        const _PurchaseVoucherColumn.rate(),
      if (enabled((settings) => settings.showTotalValue))
        const _PurchaseVoucherColumn.value(),
    ];
  }

  static List<String> _purchaseLineCells({
    required int serial,
    required PurchaseItemModel item,
    required List<_PurchaseVoucherColumn> columns,
  }) {
    return columns.map((column) {
      switch (column.type) {
        case _PurchaseVoucherColumnType.serial:
          return '$serial';
        case _PurchaseVoucherColumnType.metal:
          return item.metal.displayName;
        case _PurchaseVoucherColumnType.description:
          return item.descCtrl.text.trim().isEmpty
              ? '${item.metal.displayName} Purchase Item'
              : item.descCtrl.text.trim();
        case _PurchaseVoucherColumnType.gross:
          return item.grossWt.toStringAsFixed(3);
        case _PurchaseVoucherColumnType.less:
          return item.lessWt.toStringAsFixed(3);
        case _PurchaseVoucherColumnType.net:
          return item.netWt.toStringAsFixed(3);
        case _PurchaseVoucherColumnType.purity:
          return item.purity.toStringAsFixed(2);
        case _PurchaseVoucherColumnType.fine:
          return item.fineWt.toStringAsFixed(3);
        case _PurchaseVoucherColumnType.rate:
          return item.rate.toStringAsFixed(2);
        case _PurchaseVoucherColumnType.value:
          return item.totalValue.toStringAsFixed(2);
      }
    }).toList(growable: false);
  }

  static PurchaseBillingModel _settingsFor(
    PurchaseMetalType metal,
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    return settingsByMetal[metal] ??
        PurchaseBillingModel.defaultFor(_billingMetalFor(metal));
  }

  static pw.Widget _summaryTextRow(
    String label,
    String value, {
    bool emphasize = false,
    required PrintTemplatePdfProfile style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: style.bodyTextColor,
              fontSize: style.bodyFontSize,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: emphasize ? style.accentColor : style.bodyTextColor,
              fontSize: style.bodyFontSize,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _payoutBalanceLabel(PurchaseEntryController ctrl) {
    if (ctrl.hasSellerPayoutExcess) {
      return 'Payout Excess';
    }
    if (ctrl.hasPendingSellerPayout) {
      return 'Pending Seller Payout';
    }
    return 'Payout Balance';
  }

  static pw.Widget _shopHeader({
    required ShopPrintDocumentProfile profile,
    required PrintTemplatePdfProfile style,
    required String documentTitle,
    required String documentSubtitle,
    required String documentNumber,
    required String documentDate,
  }) {
    final title =
        profile.primaryName.isEmpty ? 'Lotus ERP' : profile.primaryName;
    final headerLines = profile.headerLines;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(style.headerPadding),
      decoration: pw.BoxDecoration(
        color: style.headerColor,
        border: pw.Border.all(
          color: style.headerBorderColor,
          width: style.headerBorderWidth,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(style.radius)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: style.headerPrimaryTextColor,
                    fontSize: style.titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                for (final line in headerLines.take(6))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 8.8,
                      ).copyWith(color: style.headerSecondaryTextColor),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                documentTitle,
                style: pw.TextStyle(
                  color: style.headerPrimaryTextColor,
                  fontSize: style.documentTitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                documentSubtitle,
                style: pw.TextStyle(
                  color: style.headerSecondaryTextColor,
                  fontSize: style.bodyFontSize,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Voucher: $documentNumber',
                style: pw.TextStyle(
                  color: style.headerPrimaryTextColor,
                  fontSize: style.bodyFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: $documentDate',
                style: pw.TextStyle(
                  color: style.headerPrimaryTextColor,
                  fontSize: style.bodyFontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _billingMetalFor(PurchaseMetalType metal) {
    switch (metal) {
      case PurchaseMetalType.gold:
        return BillingMetal.gold;
      case PurchaseMetalType.silver:
        return BillingMetal.silver;
      case PurchaseMetalType.platinum:
        return BillingMetal.platinum;
      case PurchaseMetalType.diamond:
        return BillingMetal.diamond;
    }
  }

  static List<pw.Widget> _policySections(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    LotusPdfTextRenderer textRenderer,
    PrintTemplatePdfProfile style,
  ) {
    final entries = <pw.Widget>[];

    for (final entry in settingsByMetal.entries) {
      final metalName = entry.key.displayName;
      final settings = entry.value;
      _addPolicyEntry(
        entries,
        title: '$metalName TERMS & SELLER DECLARATION',
        body: settings.termsAndConditions,
        textRenderer: textRenderer,
        style: style,
      );
      if (settings.showSupplierDetails || settings.showPanNumber) {
        _addPolicyEntry(
          entries,
          title: '$metalName SELLER OWNERSHIP DECLARATION',
          body: settings.sellerDeclarationText,
          textRenderer: textRenderer,
          style: style,
        );
      }
      _addPolicyEntry(
        entries,
        title: '$metalName SELLER RECLAIM POLICY',
        body: settings.returnPolicyText,
        textRenderer: textRenderer,
        style: style,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName VALUATION & PAYOUT POLICY',
        body: settings.buybackPolicyText,
        textRenderer: textRenderer,
        style: style,
      );
    }

    if (entries.isEmpty) return const [];

    return [
      pw.SizedBox(height: 16),
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(style.panelPadding),
        decoration: pw.BoxDecoration(
          color: style.policyPanelColor,
          border: pw.Border.all(
            color: style.borderColor,
            width: style.borderWidth,
          ),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(style.radius)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: entries,
        ),
      ),
    ];
  }

  static void _addPolicyEntry(
    List<pw.Widget> entries, {
    required String title,
    required String body,
    required LotusPdfTextRenderer textRenderer,
    required PrintTemplatePdfProfile style,
  }) {
    if (!_hasPrintableCopy(body)) return;

    if (entries.isNotEmpty) {
      entries.add(pw.SizedBox(height: 7));
    }
    entries.add(
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: style.labelFontSize,
          fontWeight: pw.FontWeight.bold,
          color: style.accentColor,
        ),
      ),
    );
    entries.add(pw.SizedBox(height: 2));
    entries.addAll(_policyBodyLines(body, textRenderer, style));
  }

  static List<pw.Widget> _policyBodyLines(
    String body,
    LotusPdfTextRenderer textRenderer,
    PrintTemplatePdfProfile style,
  ) {
    final textStyle = pw.TextStyle(
      fontSize: style.policyFontSize,
      color: style.bodyTextColor,
      lineSpacing: 1.3,
    );
    final lines = body
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .toList(growable: false);

    return [
      for (final line in lines)
        if (line.trim().isEmpty)
          pw.SizedBox(height: 4)
        else
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: textRenderer.text(
              line,
              style: textStyle,
              maxWidth: _policyTextMaxWidth,
            ),
          ),
    ];
  }

  static Future<void> _warmPolicyText(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    LotusPdfTextRenderer textRenderer,
    PrintTemplatePdfProfile style,
  ) async {
    final lines = settingsByMetal.values
        .expand(
          (settings) => <String>[
            settings.termsAndConditions,
            settings.sellerDeclarationText,
            settings.returnPolicyText,
            settings.buybackPolicyText,
          ],
        )
        .expand(
          (body) => body
              .replaceAll('\r\n', '\n')
              .replaceAll('\r', '\n')
              .split('\n')
              .map((line) => line.trimRight()),
        )
        .toSet();

    await textRenderer.warmTextLines(
      lines,
      specs: [
        LotusPdfTextSpec(
          fontSize: style.policyFontSize,
          color: style.bodyTextColor,
          bold: false,
          maxWidth: _policyTextMaxWidth,
        ),
      ],
    );
  }

  static pw.Widget _footer(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    PrintTemplatePdfProfile style,
  ) {
    final footerMessage = settingsByMetal.values
        .map((settings) => settings.footerMessage.trim())
        .where(_hasPrintableCopy)
        .toSet()
        .join(' | ');

    return pw.Column(
      children: [
        pw.SizedBox(height: 12),
        pw.Divider(color: style.borderColor),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                footerMessage,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                ).copyWith(color: style.bodyTextColor),
              ),
            ),
            pw.Text(
              'E&OE',
              style: pw.TextStyle(
                fontSize: 9.5,
                color: style.accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static bool _hasPrintableCopy(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '0' && text != '-';
  }
}

enum _PurchaseVoucherColumnType {
  serial,
  metal,
  description,
  gross,
  less,
  net,
  purity,
  fine,
  rate,
  value,
}

class _PurchaseVoucherColumn {
  final _PurchaseVoucherColumnType type;
  final String label;

  const _PurchaseVoucherColumn._(this.type, this.label);

  const _PurchaseVoucherColumn.serial()
      : this._(_PurchaseVoucherColumnType.serial, '#');

  const _PurchaseVoucherColumn.metal()
      : this._(_PurchaseVoucherColumnType.metal, 'Metal');

  const _PurchaseVoucherColumn.description()
      : this._(_PurchaseVoucherColumnType.description, 'Description');

  const _PurchaseVoucherColumn.gross()
      : this._(_PurchaseVoucherColumnType.gross, 'Gross');

  const _PurchaseVoucherColumn.less()
      : this._(_PurchaseVoucherColumnType.less, 'Less');

  const _PurchaseVoucherColumn.net()
      : this._(_PurchaseVoucherColumnType.net, 'Net');

  const _PurchaseVoucherColumn.purity()
      : this._(_PurchaseVoucherColumnType.purity, 'Purity');

  const _PurchaseVoucherColumn.fine()
      : this._(_PurchaseVoucherColumnType.fine, 'Fine');

  const _PurchaseVoucherColumn.rate()
      : this._(_PurchaseVoucherColumnType.rate, 'Rate');

  const _PurchaseVoucherColumn.value()
      : this._(_PurchaseVoucherColumnType.value, 'Value');
}
