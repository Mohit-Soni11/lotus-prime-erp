import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_theme.dart';
import '../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../features/print_templates/application/global/lotus_print_template_renderer_registry.dart';
import '../../features/print_templates/application/global/lotus_printable_document.dart';
import '../../features/print_templates/domain/print_template_pdf_profile.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';

part 'girvi_invoice_pdf_render_sections.dart';
part 'girvi_invoice_pdf_table_sections.dart';
part 'girvi_invoice_pdf_detail_sections.dart';
part 'girvi_invoice_pdf_media_sections.dart';
part 'girvi_invoice_pdf_models.dart';

enum GirviInvoiceFormat {
  a4,
  compactA5;

  String get label => this == a4 ? 'A4 Size' : '80 mm Girvi Receipt';

  String get subtitle =>
      this == a4 ? 'Premium full-page invoice' : '80 mm roll counter copy';

  PdfPageFormat get pageFormat =>
      this == a4 ? PdfPageFormat.a4 : PdfPageFormat.a5.landscape;
}

class GirviInvoicePdfService {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _wholeAmountFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _compactAmountFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _navySoft = PdfColor.fromInt(0xFF22344E);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF111111);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);

  static const customerItemHeaders = <String>[
    'S.No',
    'Metal',
    'Item',
    'Pcs',
    'HUID',
    'Purity',
    'Gross Wt.',
    'Less Wt.',
    'Net Wt.',
  ];

  Future<Uint8List> build({
    required GirviInvoiceDraft draft,
    required GirviInvoiceFormat format,
    GirviBillingModel settings = const GirviBillingModel(),
    GirviInvoiceBranding branding = GirviInvoiceBranding.fallback,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    int copies = 1,
    bool duplicateStamp = false,
  }) async {
    final textRenderer = await LotusPdfTextRenderer.create();
    final template = _resolveTemplate(templateId);
    final printableDocuments = format == GirviInvoiceFormat.a4
        ? _printableDocuments(
            shopProfile: _shopProfileFromBranding(branding),
            draft: draft,
            settings: settings,
            template: template,
          )
        : null;
    if (printableDocuments == null) {
      await _warmPolicyText(settings, textRenderer, format);
    } else {
      for (final printableDocument in printableDocuments) {
        await LotusPrintTemplateRendererRegistry.warmPolicyText(
          printableDocument,
          textRenderer,
        );
      }
    }
    final devanagariFont = await LotusPdfTheme.loadDevanagariFont();
    final brandLogo = _loadBrandLogo(branding);
    final pdf = pw.Document(
      theme: await LotusPdfTheme.reportTheme(),
      title: '${draft.mode.title} ${draft.ticketNo} (${template.shortName})',
      author: branding.shopName,
      creator: branding.shopName,
      subject: 'Customer ${draft.mode.title.toLowerCase()}',
    );
    final safeCopies = copies.clamp(1, 5);

    for (var copy = 0; copy < safeCopies; copy++) {
      final copyLabel = documentCopyLabel(
        reissued: duplicateStamp,
        copyIndex: copy,
      );
      final compact = format == GirviInvoiceFormat.compactA5;
      final printables = printableDocuments;

      if (printables != null) {
        for (final printable in printables) {
          pdf.addPage(
            pw.MultiPage(
              pageTheme: pw.PageTheme(
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
                buildBackground: _hasWatermark(printable)
                    ? (_) => _documentWatermark(printable)
                    : null,
              ),
              build: (_) => LotusPrintTemplateRendererRegistry.buildA4(
                templateId: template.id,
                context: LotusPrintTemplateRenderContext(
                  document: printable,
                  textRenderer: textRenderer,
                ),
                isDuplicateCopy: duplicateStamp || copy > 0,
              ),
            ),
          );
        }
        continue;
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: format.pageFormat,
            margin: pw.EdgeInsets.fromLTRB(
              compact ? 18 : 28,
              compact ? 16 : 24,
              compact ? 18 : 28,
              compact ? 18 : 22,
            ),
          ),
          footer: (context) => _buildPageFooter(
            context,
            draft,
            compact,
          ),
          build: (_) => _buildDocument(
            draft,
            format,
            copyLabel,
            settings,
            branding,
            brandLogo,
            devanagariFont,
            textRenderer,
          ),
        ),
      );
    }

    return pdf.save();
  }

  bool _hasWatermark(LotusPrintableDocument document) {
    return document.watermarkText.trim().isNotEmpty;
  }

  pw.Widget _documentWatermark(LotusPrintableDocument document) {
    return pw.Center(
      child: pw.Opacity(
        opacity: 0.11,
        child: pw.Transform.rotate(
          angle: -0.45,
          child: pw.Text(
            document.watermarkText.trim().toUpperCase(),
            style: pw.TextStyle(
              color: PdfColor.fromInt(
                document.watermarkColorValue ?? 0xFF059669,
              ),
              fontSize: 72,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _warmPolicyText(
    GirviBillingModel settings,
    LotusPdfTextRenderer textRenderer,
    GirviInvoiceFormat format,
  ) async {
    final policySettings = settings.withGirviSafePolicyCopy();
    final compact = format == GirviInvoiceFormat.compactA5;
    final lines = <String>[
      policySettings.termsAndConditions,
      policySettings.termsAndConditionsHindi,
      policySettings.customerDeclaration,
      policySettings.customerDeclarationHindi,
      policySettings.footerMessage,
    ]
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
          fontSize: compact ? 7.2 : 8.5,
          color: _navySoft,
          bold: false,
          maxWidth: compact ? 430 : 470,
        ),
        LotusPdfTextSpec(
          fontSize: compact ? 7.4 : 8.8,
          color: _navySoft,
          bold: false,
          maxWidth: compact ? 430 : 500,
        ),
        const LotusPdfTextSpec(
          fontSize: 8,
          color: _muted,
          bold: false,
          maxWidth: 500,
        ),
      ],
    );
  }

  pw.MemoryImage? _loadBrandLogo(GirviInvoiceBranding branding) {
    final path = branding.logoPath?.trim() ?? '';
    if (path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static PrintTemplateDefinition _resolveTemplate(String templateId) {
    final template = PrintTemplateRegistry.byId(templateId);
    if (template.supports(PrintTemplateDocumentType.girviReceipt)) {
      return template;
    }
    return PrintTemplateRegistry.lotusClassic;
  }

  static String _documentDateLabel(GirviInvoiceDraft draft) {
    switch (draft.mode) {
      case GirviReceiptMode.pledge:
        return 'Issue Date';
      case GirviReceiptMode.interest:
        return 'Receipt Date';
      case GirviReceiptMode.release:
        return 'Release Date';
    }
  }

  static String _documentDateValue(GirviInvoiceDraft draft) {
    switch (draft.mode) {
      case GirviReceiptMode.pledge:
      case GirviReceiptMode.interest:
        return _dateFormat.format(draft.createdAt);
      case GirviReceiptMode.release:
        return _dateFormat.format(draft.releaseDate ?? draft.createdAt);
    }
  }

  static List<String> _girviHeaderLines(GirviInvoiceBranding branding) {
    return branding.printHeaderLines
        .where((line) => !line.trim().toUpperCase().contains('GSTIN'))
        .toList(growable: false);
  }

  static ShopPrintDocumentProfile _shopProfileFromBranding(
    GirviInvoiceBranding branding,
  ) {
    final fields = branding.printFields.isNotEmpty
        ? branding.printFields
            .where((field) => field.id.trim().toLowerCase() != 'gstin')
            .toList(growable: false)
        : <ShopPrintDocumentField>[
            ShopPrintDocumentField(
              id: 'shop_name',
              label: 'Shop Name',
              value: branding.shopName,
              group: ShopPrintFieldGroup.identity,
            ),
            if (branding.shopAddress.trim().isNotEmpty)
              ShopPrintDocumentField(
                id: 'business_address',
                label: 'Business Address',
                value: branding.shopAddress.trim(),
                group: ShopPrintFieldGroup.address,
              ),
            if (branding.shopMobile.trim().isNotEmpty)
              ShopPrintDocumentField(
                id: 'mobile_number',
                label: 'Business Mobile',
                value: branding.shopMobile.trim(),
                group: ShopPrintFieldGroup.contact,
              ),
            if (branding.shopAlternateMobile.trim().isNotEmpty)
              ShopPrintDocumentField(
                id: 'whatsapp_number',
                label: 'Help Desk Number',
                value: branding.shopAlternateMobile.trim(),
                group: ShopPrintFieldGroup.contact,
              ),
          ];

    return ShopPrintDocumentProfile(
      tenantId: '',
      fields: fields,
      logoPath: branding.logoPath,
      logoShape: branding.logoShape,
      signaturePath: branding.signaturePath,
      signatureShape: branding.signatureShape,
    );
  }

  List<LotusPrintableDocument>? _printableDocuments({
    required ShopPrintDocumentProfile shopProfile,
    required GirviInvoiceDraft draft,
    required GirviBillingModel settings,
    required PrintTemplateDefinition template,
  }) {
    if (draft.isReleaseReceipt) {
      final pledgeDraft = draft.copyWith(mode: GirviReceiptMode.pledge);
      final interestDraft = draft.copyWith(mode: GirviReceiptMode.interest);
      return [
        _printableDocument(
          shopProfile: shopProfile,
          draft: pledgeDraft,
          settings: settings,
          template: template,
          watermarkText: 'Released',
          watermarkColorValue: 0xFF059669,
        ),
        _printableDocument(
          shopProfile: shopProfile,
          draft: interestDraft,
          settings: settings,
          template: template,
        ),
        _printableDocument(
          shopProfile: shopProfile,
          draft: draft,
          settings: settings,
          template: template,
        ),
      ];
    }
    return [
      _printableDocument(
        shopProfile: shopProfile,
        draft: draft,
        settings: settings,
        template: template,
      ),
    ];
  }

  LotusPrintableDocument _printableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required GirviInvoiceDraft draft,
    required GirviBillingModel settings,
    required PrintTemplateDefinition template,
    String watermarkText = '',
    int? watermarkColorValue,
  }) {
    final policySettings = settings.withGirviSafePolicyCopy();
    if (draft.isReleaseReceipt) {
      return _releasePrintableDocument(
        shopProfile: shopProfile,
        draft: draft,
        settings: settings,
        template: template,
        policySettings: policySettings,
      );
    }
    if (draft.isInterestReceipt) {
      return _interestPrintableDocument(
        shopProfile: shopProfile,
        draft: draft,
        settings: settings,
        template: template,
        policySettings: policySettings,
      );
    }

    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: 'GIRVI INVOICE',
      subtitle: '',
      documentNumberLabel: 'Invoice No.',
      documentNumber: draft.ticketNo,
      documentDateLabel: '',
      documentDate: '',
      badgeLabel: draft.mode.badgeLabel,
      primaryPanel: _printableCustomerPanel(draft, settings),
      secondaryPanel: _printableLoanPanel(draft, settings),
      itemTable: _printableItemTable(draft.items, settings),
      settlementPanels: _printableSettlementPanels(draft, settings),
      policySections: _printablePolicySections(policySettings),
      footerMessage:
          policySettings.printFooterMessage ? policySettings.footerMessage : '',
      showHeaderDocumentMeta: true,
      showHeaderBadge: false,
      useFallbackShopName: false,
      renderPolicySectionsAsPages: true,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: _showGirviLegalFooter(policySettings),
      watermarkText: watermarkText,
      watermarkColorValue: watermarkColorValue,
    );
  }

  LotusPrintableDocument _releasePrintableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required GirviInvoiceDraft draft,
    required GirviBillingModel settings,
    required PrintTemplateDefinition template,
    required GirviBillingModel policySettings,
  }) {
    final releasePrincipal = draft.releasePrincipal ?? draft.loanAmount;
    final releaseInterest = draft.releaseInterest ?? 0;
    final releasePenalty = draft.releasePenalty ?? 0;
    final releaseDiscount = draft.releaseDiscount ?? 0;
    final releaseTotal = draft.releaseTotalAmount ??
        (releasePrincipal + releaseInterest + releasePenalty - releaseDiscount);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: 'RELEASE RECEIPT',
      subtitle: 'Final Girvi settlement and item release document',
      documentNumberLabel: 'Ticket No.',
      documentNumber: draft.ticketNo,
      documentDateLabel: 'Release Date',
      documentDate: _dateFormat.format(draft.releaseDate ?? draft.createdAt),
      badgeLabel: 'Release',
      primaryPanel: LotusPrintablePanel(
        title: 'FINAL SETTLEMENT',
        compactDetailDividers: true,
        details: [
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Principal Received',
            value: _formatAmount(releasePrincipal),
            highlight: true,
          ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Interest Received',
            value: _formatAmount(releaseInterest),
          ),
          if (releasePenalty > 0)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Penalty / Charges',
              value: _formatAmount(releasePenalty),
            ),
          if (releaseDiscount > 0)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Discount / Waiver',
              value: _formatAmount(releaseDiscount),
            ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Total Payable Cleared',
            value: _formatAmount(releaseTotal),
            highlight: true,
          ),
          if ((draft.releasePaymentMode ?? '').trim().isNotEmpty)
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'Collection Mode',
              value: draft.releasePaymentMode!.trim(),
            ),
        ],
      ),
      secondaryPanel: _releaseCustomerTicketPanel(draft, settings),
      itemTable: _releaseSettlementTable(
        releasePrincipal: releasePrincipal,
        releaseInterest: releaseInterest,
        releasePenalty: releasePenalty,
        releaseDiscount: releaseDiscount,
        releaseTotal: releaseTotal,
      ),
      settlementPanels: [
        if (draft.items.isNotEmpty) _releasedItemsPanel(draft),
        LotusPrintablePanel(
          title: 'DELIVERY STATUS',
          details: [
            LotusPrintableDetail(
              iconKey: 'status',
              label: 'Delivery Status',
              value: _deliveryStatusLabel(draft),
              highlight: true,
            ),
            LotusPrintableDetail(
              iconKey: 'calendar',
              label: 'Expected Pickup Date',
              value: draft.expectedDeliveryDate == null
                  ? '-'
                  : _dateFormat.format(draft.expectedDeliveryDate!),
            ),
            if (draft.deliveredAt != null)
              LotusPrintableDetail(
                iconKey: 'calendar',
                label: 'Delivered At',
                value: _dateFormat.format(draft.deliveredAt!),
                highlight: true,
              ),
          ],
        ),
        if ((draft.releaseNotes ?? '').trim().isNotEmpty)
          LotusPrintablePanel(
            title: 'RELEASE NOTES',
            details: [
              LotusPrintableDetail(
                iconKey: 'notes',
                label: 'Notes',
                value: draft.releaseNotes!.trim(),
                multiline: true,
              ),
            ],
          ),
      ],
      policySections: const [],
      footerMessage: '',
      showHeaderDocumentMeta: true,
      showHeaderBadge: true,
      useFallbackShopName: false,
      renderPolicySectionsAsPages: true,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: _showGirviLegalFooter(policySettings),
    );
  }

  LotusPrintableDocument _interestPrintableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required GirviInvoiceDraft draft,
    required GirviBillingModel settings,
    required PrintTemplateDefinition template,
    required GirviBillingModel policySettings,
  }) {
    final interestOutstanding = draft.interestOutstanding ?? 0;
    final principalOutstanding = draft.principalOutstanding ?? draft.loanAmount;
    final paidTill = draft.lastInterestPaidDate;
    final interestRows = _interestLedgerRows(draft);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: 'INTEREST RECEIPT',
      subtitle: 'Girvi interest collection acknowledgement',
      documentNumberLabel: 'Ticket No.',
      documentNumber: draft.ticketNo,
      documentDateLabel: 'Receipt Date',
      documentDate: _dateFormat.format(draft.createdAt),
      badgeLabel: 'Interest',
      primaryPanel: LotusPrintablePanel(
        title: 'INTEREST COLLECTION STATUS',
        compactDetailDividers: true,
        details: [
          if (paidTill != null)
            LotusPrintableDetail(
              iconKey: 'calendar',
              label: 'Interest Paid Till',
              value: _dateFormat.format(paidTill),
              highlight: true,
            ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Principal Outstanding',
            value: _formatAmount(principalOutstanding),
          ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Interest Outstanding',
            value: _formatAmount(interestOutstanding),
            danger: interestOutstanding > 0,
            highlight: interestOutstanding <= 0,
          ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Total Outstanding',
            value: _formatAmount(draft.totalOutstanding),
            highlight: true,
          ),
        ],
      ),
      secondaryPanel: _releaseCustomerTicketPanel(draft, settings),
      itemTable: LotusPrintableTable(
        title: 'INTEREST RECEIVED LEDGER',
        headers: const [
          'Date',
          'Mode',
          'Interest Period',
          'Months',
          'Interest Received',
          'Balance',
        ],
        rows: interestRows.isEmpty
            ? const [
                [
                  '-',
                  '-',
                  'No interest collection recorded',
                  '-',
                  '-',
                  '-',
                ],
              ]
            : interestRows,
      ),
      settlementPanels: const [],
      policySections: const [],
      footerMessage: '',
      showHeaderDocumentMeta: true,
      showHeaderBadge: true,
      useFallbackShopName: false,
      renderPolicySectionsAsPages: true,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: _showGirviLegalFooter(policySettings),
    );
  }

  static LotusPrintablePanel _releaseCustomerTicketPanel(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    return LotusPrintablePanel(
      title: 'CUSTOMER & LOAN DETAILS',
      compactDetailDividers: true,
      details: [
        LotusPrintableDetail(
          iconKey: 'customer',
          label: 'Customer',
          value: _fallback(draft.customerName, 'Walk-in Customer'),
          highlight: true,
        ),
        if (settings.showCustomerMobile)
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: _fallback(draft.customerMobile, '--'),
          ),
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Ticket No.',
          value: draft.ticketNo,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Start Date',
          value: _dateFormat.format(draft.startDate),
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Maturity Date',
          value: _dateFormat.format(draft.maturityDate),
        ),
        if (settings.showInterestRate)
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Monthly Interest Rate',
            value: '${_trimNumber(draft.interestRate)}%',
          ),
      ],
    );
  }

  static LotusPrintableTable _releaseSettlementTable({
    required double releasePrincipal,
    required double releaseInterest,
    required double releasePenalty,
    required double releaseDiscount,
    required double releaseTotal,
  }) {
    return LotusPrintableTable(
      title: 'RELEASE SETTLEMENT SUMMARY',
      headers: const ['S.No', 'Particular', 'Amount'],
      rows: [
        ['01', 'Total Principal', _formatAmount(releasePrincipal)],
        ['02', 'Total Interest', _formatAmount(releaseInterest)],
        if (releasePenalty > 0)
          ['03', 'Penalty / Charges', _formatAmount(releasePenalty)],
        if (releaseDiscount > 0)
          ['04', 'Discount / Waiver', '- ${_formatAmount(releaseDiscount)}'],
        ['05', 'Total Paid', _formatAmount(releaseTotal)],
      ],
    );
  }

  static List<List<String>> _interestLedgerRows(GirviInvoiceDraft draft) {
    final rows = draft.ledgerEntries.where((entry) {
      final hasInterest = entry.interestAmount > 0;
      final isInterestType = entry.typeLabel.toLowerCase().contains('interest');
      return hasInterest || isInterestType;
    }).toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.typeLabel.compareTo(b.typeLabel);
      });

    return [
      for (final entry in rows)
        [
          _dateFormat.format(entry.date),
          entry.modeLabel,
          _interestCoverageLabel(entry),
          _monthsLabel(entry.monthsCovered),
          _formatAmount(
            entry.interestAmount > 0 ? entry.interestAmount : entry.amount,
          ),
          _formatAmount(entry.balanceAfter),
        ],
    ];
  }

  static String _interestCoverageLabel(GirviInvoiceLedgerEntry entry) {
    final from = entry.interestFromDate;
    final to = entry.interestToDate;
    if (from != null && to != null) {
      return '${_dateFormat.format(from)} to ${_dateFormat.format(to)}';
    }
    final months = entry.monthsCovered ?? 0;
    if (months > 0) return _monthsLabel(months);
    return 'Interest received';
  }

  static String _monthsLabel(int? months) {
    final value = months ?? 0;
    if (value <= 0) return '-';
    return '$value month${value == 1 ? '' : 's'}';
  }

  static String _deliveryStatusLabel(GirviInvoiceDraft draft) {
    if (draft.deliveredAt != null) return 'Delivered';
    if (draft.accountStatus.trim().isNotEmpty) return draft.accountStatus;
    return 'Ready for Delivery';
  }

  static LotusPrintablePanel _releasedItemsPanel(
    GirviInvoiceDraft draft, {
    String title = 'PLEDGED ITEMS RELEASED',
  }) {
    final items = draft.items.take(6).toList(growable: false);
    return LotusPrintablePanel(
      title: title,
      compactDetailDividers: true,
      details: [
        for (final item in items)
          LotusPrintableDetail(
            iconKey: 'item',
            label: 'Item ${item.serialNo.toString().padLeft(2, '0')}',
            value:
                '${item.description} | ${item.metal} ${item.purity} | Net ${_trimNumber(item.netWeight)} g',
            multiline: true,
          ),
        if (draft.items.length > items.length)
          LotusPrintableDetail(
            iconKey: 'item',
            label: 'Additional Items',
            value: '${draft.items.length - items.length} more item(s)',
          ),
      ],
    );
  }

  static LotusPrintablePanel _printableCustomerPanel(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    return LotusPrintablePanel(
      title: 'CUSTOMER DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'customer',
          label: 'Customer',
          value: _fallback(draft.customerName, 'Walk-in Customer'),
          highlight: true,
        ),
        if (settings.showCustomerMobile)
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: _fallback(draft.customerMobile, '--'),
          ),
        if (settings.showCustomerCity)
          LotusPrintableDetail(
            iconKey: 'location',
            label: 'Address',
            value: draft.displayCustomerAddress,
            multiline: true,
          ),
      ],
    );
  }

  LotusPrintablePanel _printableLoanPanel(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    return LotusPrintablePanel(
      title: 'LOAN DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Invoice No.',
          value: draft.ticketNo,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: _documentDateLabel(draft),
          value: _documentDateValue(draft),
        ),
        if (settings.showStartDate)
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Start Date',
            value: _dateFormat.format(draft.startDate),
          ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Maturity Date',
          value: _dateFormat.format(draft.maturityDate),
          danger: true,
          highlight: true,
        ),
        if (draft.isReleaseReceipt && draft.releaseDate != null)
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Release Date',
            value: _dateFormat.format(draft.releaseDate!),
            danger: true,
            highlight: true,
          ),
        if (settings.showInterestRate)
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Monthly Interest',
            value: '${draft.interestRate.toStringAsFixed(2)}%',
          ),
        if (draft.lastInterestPaidDate != null)
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Interest Paid Till',
            value: _dateFormat.format(draft.lastInterestPaidDate!),
          ),
      ],
    );
  }

  LotusPrintableTable _printableItemTable(
    List<GirviInvoiceItemDraft> items,
    GirviBillingModel settings,
  ) {
    final itemSettings = _combinedItemSettings(items, settings);
    final columns = [
      ..._visibleColumns(itemSettings),
      if (itemSettings.showValuationPurity)
        _GirviInvoiceColumn(
          header: 'Val. Purity',
          width: 0.85,
          alignment: pw.Alignment.center,
          value: (item) => item.valuationPurity,
        ),
      if (itemSettings.showFineWeight)
        _GirviInvoiceColumn(
          header: 'Fine Wt.',
          width: 0.9,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.fineWeight.toStringAsFixed(3)} g',
        ),
      if (itemSettings.showRatePerGram)
        _GirviInvoiceColumn(
          header: 'Rate / g',
          width: 1.0,
          alignment: pw.Alignment.centerRight,
          value: (item) => _amount(item.ratePerGram),
        ),
      if (itemSettings.showValuationAmount)
        _GirviInvoiceColumn(
          header: 'Pledged Value',
          width: 1.15,
          alignment: pw.Alignment.centerRight,
          value: (item) => _amount(item.value),
        ),
    ];

    return LotusPrintableTable(
      title: 'PLEDGED ITEMS',
      headers: columns.map((column) => column.header).toList(growable: false),
      rows: [
        for (final item in items)
          [
            for (final column in columns) column.value(item),
          ],
      ],
    );
  }

  List<LotusPrintablePanel> _printableSettlementPanels(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    final totalDisbursed =
        draft.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final hasPaymentBreakdown = draft.payments.isNotEmpty;
    final disbursementSummary = draft.disbursementSummary.trim();
    final hasDisbursementSummary = disbursementSummary.isNotEmpty;
    final pledgedItemPhotoPath = _firstPledgedItemPhotoPath(draft, settings);
    final panels = <LotusPrintablePanel>[
      LotusPrintablePanel(
        title: 'LOAN DISBURSEMENT SUMMARY',
        photoPath: pledgedItemPhotoPath,
        photoLabel: 'Pledged Item Photo',
        extractPhotoProof: false,
        compactDetailDividers: true,
        details: [
          if (settings.showLoanAmount)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Loan Amount',
              value: _amount(draft.loanAmount),
              highlight: true,
            ),
          if (hasPaymentBreakdown)
            ...draft.payments.map(
              (payment) => LotusPrintableDetail(
                iconKey: 'payment',
                label: _paidLabel(payment.label),
                value: _amount(payment.amount),
              ),
            )
          else if (hasDisbursementSummary)
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'Payment Mode',
              value: disbursementSummary,
              multiline: true,
            ),
          if (hasPaymentBreakdown || hasDisbursementSummary)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Total Disbursed',
              value: _amount(
                hasPaymentBreakdown ? totalDisbursed : draft.loanAmount,
              ),
              highlight: true,
            ),
          LotusPrintableDetail(
            iconKey: 'status',
            label: 'Loan Tenure',
            value: '${draft.durationMonths} months',
          ),
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Maturity Date',
            value: _dateFormat.format(draft.maturityDate),
            danger: true,
            highlight: true,
          ),
          if (settings.showMonthlyInterest)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Monthly Interest',
              value: _amount(draft.monthlyInterest),
            ),
          if (settings.showTotalInterest)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Total Interest',
              value: _amount(draft.totalInterest),
            ),
          if (settings.showTotalDue && draft.isReleaseReceipt)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Original Maturity Due',
              value: _amount(draft.totalDue),
              highlight: true,
            ),
          if (settings.showTotalValue)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Pledged Valuation',
              value: _amount(draft.totalValue),
            ),
        ],
      ),
    ];

    if (draft.isInterestReceipt && draft.lastInterestPaidDate != null) {
      panels.add(
        LotusPrintablePanel(
          title: 'INTEREST STATUS',
          details: [
            LotusPrintableDetail(
              iconKey: 'calendar',
              label: 'Interest Paid Till',
              value: _dateFormat.format(draft.lastInterestPaidDate!),
              highlight: true,
            ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Principal Outstanding',
              value: _amount(draft.principalOutstanding ?? draft.loanAmount),
            ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Estimated Interest Outstanding',
              value: _amount(draft.interestOutstanding ?? draft.totalInterest),
            ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Estimated Total Outstanding',
              value: _amount(draft.totalOutstanding),
              highlight: true,
            ),
          ],
        ),
      );
    }

    if (draft.isReleaseReceipt) {
      panels.add(
        LotusPrintablePanel(
          title: 'RELEASE SETTLEMENT',
          details: [
            if (draft.releaseDate != null)
              LotusPrintableDetail(
                iconKey: 'calendar',
                label: 'Release Date',
                value: _dateFormat.format(draft.releaseDate!),
                highlight: true,
              ),
            if ((draft.releasePrincipal ?? 0) > 0)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Principal Settled',
                value: _amount(draft.releasePrincipal!),
              ),
            if ((draft.releaseInterest ?? 0) > 0)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Interest Settled',
                value: _amount(draft.releaseInterest!),
              ),
            if ((draft.releasePenalty ?? 0) > 0)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Penalty / Charges',
                value: _amount(draft.releasePenalty!),
              ),
            if ((draft.releaseDiscount ?? 0) > 0)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Discount Allowed',
                value: _amount(draft.releaseDiscount!),
              ),
            if ((draft.releaseTotalAmount ?? 0) > 0)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Total Received',
                value: _amount(draft.releaseTotalAmount!),
                highlight: true,
              ),
            if ((draft.releasePaymentMode ?? '').trim().isNotEmpty)
              LotusPrintableDetail(
                iconKey: 'payment',
                label: 'Release Payment Mode',
                value: draft.releasePaymentMode!.trim(),
              ),
            if ((draft.releasedBy ?? '').trim().isNotEmpty)
              LotusPrintableDetail(
                iconKey: 'customer',
                label: 'Released By',
                value: draft.releasedBy!.trim(),
              ),
          ],
        ),
      );
    }

    final custodyDetails = <LotusPrintableDetail>[
      if (draft.expectedDeliveryDate != null)
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Expected Delivery',
          value: _dateFormat.format(draft.expectedDeliveryDate!),
        ),
      if (draft.deliveredAt != null)
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Delivered At',
          value: _dateFormat.format(draft.deliveredAt!),
          highlight: true,
        ),
      if ((draft.releaseNotes ?? '').trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'notes',
          label: 'Release Notes',
          value: draft.releaseNotes!.trim(),
          multiline: true,
        ),
    ];
    if (custodyDetails.isNotEmpty) {
      panels.add(
        LotusPrintablePanel(
          title: 'DELIVERY & CUSTODY',
          details: custodyDetails,
        ),
      );
    }

    final complianceDetails = <LotusPrintableDetail>[
      if (settings.showKycDetails &&
          (draft.idProofType ?? '').trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'customer',
          label: 'ID Proof',
          value: draft.idProofType!.trim(),
        ),
      if (settings.showKycDetails &&
          (draft.idProofNumber ?? '').trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Document No',
          value: draft.idProofNumber!.trim(),
        ),
      if (settings.showNotes && (draft.notes ?? '').trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'notes',
          label: 'Remarks',
          value: draft.notes!.trim(),
          multiline: true,
        ),
    ];
    if (complianceDetails.isNotEmpty ||
        (settings.showKycPhoto && (draft.idProofImagePath ?? '').isNotEmpty)) {
      panels.add(
        LotusPrintablePanel(
          title: 'KYC & REMARKS',
          photoPath: settings.showKycPhoto ? draft.idProofImagePath ?? '' : '',
          photoLabel: 'KYC Document',
          details: complianceDetails,
        ),
      );
    }

    return panels;
  }

  static List<LotusPrintablePolicySection> _printablePolicySections(
    GirviBillingModel settings,
  ) {
    final policySettings = settings.withGirviSafePolicyCopy();
    final sections = <LotusPrintablePolicySection>[];
    final terms = _joinedBilingualBody(
      policySettings.termsAndConditions,
      policySettings.termsAndConditionsHindi,
    );
    final declaration = _joinedBilingualBody(
      policySettings.customerDeclaration,
      policySettings.customerDeclarationHindi,
    );

    if (policySettings.printTermsAndConditions && terms.isNotEmpty) {
      sections.add(
        LotusPrintablePolicySection(
          title: 'Terms & Conditions',
          body: terms,
        ),
      );
    }
    if (policySettings.printCustomerDeclaration && declaration.isNotEmpty) {
      sections.add(
        LotusPrintablePolicySection(
          title: 'Customer Declaration',
          body: declaration,
        ),
      );
    }
    return sections;
  }

  static bool _showGirviLegalFooter(GirviBillingModel settings) {
    return settings.printTermsAndConditions ||
        settings.printCustomerDeclaration ||
        (settings.printFooterMessage &&
            settings.footerMessage.trim().isNotEmpty);
  }

  static String _joinedBilingualBody(String english, String hindi) {
    return pairBilingualLines(english, hindi)
        .expand((line) => [line.english, line.hindi])
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _paidLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return 'Paid';
    final normalized = trimmed.toLowerCase();
    if (normalized.endsWith('paid') || normalized.endsWith('disbursed')) {
      return trimmed;
    }
    return '$trimmed Paid';
  }

  static String _firstPledgedItemPhotoPath(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    for (final item in draft.items) {
      if (!settings.settingsForMetal(item.metal).showItemPhotos) continue;
      for (final path in item.photoPaths) {
        final normalizedPath = _existingLocalImagePath(path);
        if (normalizedPath.isNotEmpty) return normalizedPath;
      }
    }
    return '';
  }

  static String _existingLocalImagePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    final normalizedPath = uri != null && uri.scheme == 'file'
        ? uri.toFilePath(windows: Platform.isWindows)
        : trimmed;
    return File(normalizedPath).existsSync() ? normalizedPath : '';
  }

  List<pw.Widget> _buildDocument(
    GirviInvoiceDraft draft,
    GirviInvoiceFormat format,
    String copyLabel,
    GirviBillingModel settings,
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
    pw.Font? devanagariFont,
    LotusPdfTextRenderer textRenderer,
  ) {
    final compact = format == GirviInvoiceFormat.compactA5;
    final sectionGap = compact ? 8.0 : 10.0;
    final itemSettings = _combinedItemSettings(draft.items, settings);
    final policySettings = settings.withGirviSafePolicyCopy();
    final photos = _loadPhotos(draft, settings);
    var nextSection = 1;
    final widgets = <pw.Widget>[
      _buildHeroHeader(
        draft,
        compact,
        copyLabel,
        settings,
        branding,
        brandLogo,
      ),
      pw.SizedBox(height: sectionGap),
      _buildCustomerAndLoanPanel(draft, compact, settings),
    ];
    final paymentStrip = _buildPaymentStrip(draft, settings, compact);
    if (paymentStrip != null) {
      widgets
        ..add(pw.SizedBox(height: compact ? 5 : 7))
        ..add(paymentStrip);
    }
    final lifecycleStrip = _buildLifecycleStrip(draft, compact);
    if (lifecycleStrip != null) {
      widgets
        ..add(pw.SizedBox(height: compact ? 5 : 7))
        ..add(lifecycleStrip);
    }
    final compactMetrics = _buildCompactLoanMetrics(
      draft,
      settings,
      compact,
    );
    if (compactMetrics != null) {
      widgets
        ..add(pw.SizedBox(height: compact ? 5 : 7))
        ..add(compactMetrics);
    }

    if (draft.items.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 110 : 145))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'PLEDGED ITEMS',
            subtitle:
                '${draft.items.length} item${draft.items.length == 1 ? '' : 's'} recorded',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9))
        ..add(
          _buildItemsTable(
            draft.items,
            itemSettings,
            compact,
          ),
        );
      if (_hasValuationFields(itemSettings)) {
        widgets
          ..add(pw.SizedBox(height: compact ? 7 : 9))
          ..add(pw.NewPage(freeSpace: compact ? 70 : 95))
          ..add(_buildSubsectionLabel('VALUATION DETAILS', compact))
          ..add(pw.SizedBox(height: compact ? 5 : 7))
          ..add(_buildValuationTable(draft.items, itemSettings, compact));
      }
    }

    final kycSection = _buildKycSection(draft, settings, compact);
    if (kycSection != null) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 115 : 150))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'CUSTOMER KYC',
            subtitle: 'Identity document recorded with this pledge ticket',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9))
        ..add(kycSection);
    }

    if (settings.showNotes && (draft.notes?.trim().isNotEmpty ?? false)) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(
          _buildTextSection(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'NOTES & REMARKS',
            subtitle: 'Remarks recorded for this Girvi ticket',
            body: draft.notes!.trim(),
            compact: compact,
          ),
        );
    }

    if (photos.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 115 : 145))
        ..add(
          _buildPhotoSection(
            photos,
            compact,
            sectionNumber: (nextSection++).toString().padLeft(2, '0'),
          ),
        );
    }

    if (policySettings.printTermsAndConditions &&
        (policySettings.termsAndConditions.trim().isNotEmpty ||
            policySettings.termsAndConditionsHindi.trim().isNotEmpty)) {
      final terms = pairBilingualLines(
        policySettings.termsAndConditions,
        policySettings.termsAndConditionsHindi,
      );
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 105 : 135))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'TERMS & CONDITIONS',
            subtitle:
                'Each condition is printed separately in English and Hindi',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9));
      for (var index = 0; index < terms.length; index++) {
        if (index > 0) widgets.add(pw.SizedBox(height: compact ? 5 : 7));
        widgets.add(
          _buildBilingualTermRow(
            index: index + 1,
            english: terms[index].english,
            hindi: terms[index].hindi,
            compact: compact,
            devanagariFont: devanagariFont,
            textRenderer: textRenderer,
          ),
        );
      }
    }

    if (policySettings.printCustomerDeclaration &&
        (policySettings.customerDeclaration.trim().isNotEmpty ||
            policySettings.customerDeclarationHindi.trim().isNotEmpty)) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 78 : 105))
        ..add(
          _buildCustomerDeclaration(
            number: (nextSection++).toString().padLeft(2, '0'),
            english: policySettings.customerDeclaration,
            hindi: policySettings.customerDeclarationHindi,
            compact: compact,
            devanagariFont: devanagariFont,
            textRenderer: textRenderer,
          ),
        );
    }
    widgets
      ..add(pw.SizedBox(height: sectionGap))
      ..add(pw.NewPage(freeSpace: compact ? 68 : 96))
      ..add(_buildDocumentSignoff(compact, settings));
    return widgets;
  }

  static List<({String english, String hindi})> pairBilingualLines(
    String english,
    String hindi,
  ) {
    List<String> lines(String value) => value
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);

    final englishLines = lines(english);
    final hindiLines = lines(hindi);
    final count = englishLines.length > hindiLines.length
        ? englishLines.length
        : hindiLines.length;
    return List.generate(
      count,
      (index) => (
        english: index < englishLines.length ? englishLines[index] : '',
        hindi: index < hindiLines.length ? hindiLines[index] : '',
      ),
      growable: false,
    );
  }

  static String documentCopyLabel({
    required bool reissued,
    required int copyIndex,
  }) {
    if (copyIndex > 0) return 'ADDITIONAL COPY';
    return reissued ? 'REISSUED BILL' : 'ORIGINAL BILL';
  }

  static bool sameCalendarDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _amount(double value) => _formatAmount(value);

  static String _formatAmount(double value) {
    final cents = (value * 100).round();
    if (cents % 100 == 0) {
      return 'Rs ${_wholeAmountFormat.format(cents ~/ 100)}';
    }
    return 'Rs ${_amountFormat.format(cents / 100)}';
  }

  static String _trimNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
  }
}
