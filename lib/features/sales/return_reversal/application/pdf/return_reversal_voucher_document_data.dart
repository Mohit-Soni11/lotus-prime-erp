part of 'return_reversal_voucher_pdf_service.dart';

List<_VoucherRow> _voucherRowsFor(ReturnReversalState state) {
  final sourceDocument = state.selectedSourceDocument;
  if (sourceDocument == null) return const [];

  final selectedRows = state.returnCartLineItems;
  final candidateRows = selectedRows.isNotEmpty
      ? selectedRows
      : sourceDocument.lineItems
          .where((line) => line.isReversed)
          .toList(growable: false);

  final sourceRows =
      candidateRows.isNotEmpty ? candidateRows : sourceDocument.lineItems;

  return sourceRows.map((line) {
    final draft = state.lineInspectionDrafts[line.lineNo] ??
        ReturnReversalLineInspectionDraft.fromLine(line);
    final valuation = _valuationFor(line, draft);
    return _VoucherRow(
      line: line,
      draft: draft,
      receivedRatio: valuation.receivedRatio,
      adjustedLineAmount: valuation.adjustedLineAmount,
      adjustedMakingAmount: valuation.adjustedMakingAmount,
      metalAmount: valuation.metalAmount,
      makingReturnedAmount: valuation.makingReturnedAmount,
      returnValue: valuation.returnValue,
    );
  }).toList(growable: false);
}

Future<ShopPrintDocumentProfile> _loadShopProfile() async {
  try {
    return await _shopProfileRepository.loadDocumentProfile();
  } catch (_) {
    return ShopPrintDocumentProfile.empty;
  }
}

_VoucherRow _valuationFor(
  ReturnReversalSourceLineItem line,
  ReturnReversalLineInspectionDraft draft,
) {
  final ratio =
      line.netWeight <= 0 ? 1.0 : (draft.receivedNetWeight / line.netWeight);
  final safeRatio = ratio.clamp(0.0, 1.0);
  final adjustedLineAmount = line.displayLineTotal * safeRatio;
  final adjustedMakingAmount = line.makingAmount * safeRatio;
  final fallbackMetalAmount =
      math.max(0.0, adjustedLineAmount - adjustedMakingAmount);
  final metalAmount = line.reversalMetalReturnAmount ?? fallbackMetalAmount;
  final makingReturnedAmount = line.reversalMakingReturnedAmount ??
      (draft.includeMakingCharge ? adjustedMakingAmount : 0.0);
  final returnValue = line.reversalLineReturnValue ??
      math.max(0.0, metalAmount + makingReturnedAmount);
  return _VoucherRow(
    line: line,
    draft: draft,
    receivedRatio: safeRatio,
    adjustedLineAmount: adjustedLineAmount,
    adjustedMakingAmount: adjustedMakingAmount,
    metalAmount: metalAmount,
    makingReturnedAmount: makingReturnedAmount,
    returnValue: returnValue,
  );
}

_VoucherSettlement _settlementFor(
  ReturnReversalState state,
  List<_VoucherRow> rows,
  ReturnReversalVoucherDocumentKind kind,
) {
  final document = state.selectedSourceDocument;
  final result = state.lastProcessResult;
  final returnValue = result?.returnValue ??
      rows.fold<double>(0, (sum, row) => sum + row.returnValue);
  final dueAdjusted = result?.dueAdjustedAmount ??
      (kind == ReturnReversalVoucherDocumentKind.salesReturn
          ? math.min(document?.dueAmount ?? 0, returnValue)
          : 0);
  final refundPayable =
      result?.refundPayableAmount ?? math.max(0.0, returnValue - dueAdjusted);
  return _VoucherSettlement(
    returnValue: returnValue,
    dueAdjustedAmount: dueAdjusted,
    refundPayableAmount: refundPayable,
  );
}

String _voucherStatusLabel(
  ReturnReversalState state,
  ReturnReversalSourceDocument? document,
  List<_VoucherRow> rows,
) {
  final resultStatus = state.lastProcessResult?.status.trim();
  if (resultStatus != null && resultStatus.isNotEmpty) {
    return resultStatus;
  }
  if ((document?.reversalVoucherNo.trim().isNotEmpty ?? false) ||
      rows.any((row) => row.line.isReversed)) {
    return 'POSTED';
  }
  return 'DRAFT';
}

LotusPrintableDocument _printableDocument({
  required ShopPrintDocumentProfile shopProfile,
  required ReturnReversalState state,
  required ReturnReversalSourceDocument sourceDocument,
  required ReturnReversalVoucherDocumentKind kind,
  required List<_VoucherRow> rows,
  required _VoucherSettlement settlement,
  required ReturnReversalVoucherPrintOptions options,
  required String templateId,
}) {
  final template = PrintTemplateRegistry.byId(templateId);
  return LotusPrintableDocument(
    shopProfile: shopProfile,
    template: template,
    profile: PrintTemplatePdfProfile.forTemplate(template.id),
    title: kind.title,
    subtitle: sourceDocument.type.label,
    documentNumberLabel: 'Voucher No',
    documentNumber: _voucherNo(state, sourceDocument),
    documentDateLabel: 'Voucher Date',
    documentDate: _formatDate(DateTime.now()),
    badgeLabel: _voucherStatusLabel(state, sourceDocument, rows),
    primaryPanel: _printableCustomerPanel(sourceDocument),
    secondaryPanel: _printableSourcePanel(state, sourceDocument),
    itemTable: _printableItemTable(kind, rows, options),
    settlementPanels: _printableSettlementPanels(
      kind,
      sourceDocument,
      rows,
      settlement,
      options,
    ),
    policySections: const [],
    footerMessage: '',
    showHeaderDocumentMeta: true,
    showHeaderBadge: true,
    useFallbackShopName: true,
    renderPolicySectionsAsPages: false,
    startPolicySectionsOnNewPage: false,
    showLegalSignatureFooter: false,
  );
}

LotusPrintablePanel _printableCustomerPanel(
  ReturnReversalSourceDocument sourceDocument,
) {
  return LotusPrintablePanel(
    title: 'CUSTOMER DETAILS',
    details: [
      LotusPrintableDetail(
        iconKey: 'customer',
        label: 'Customer',
        value: _fallback(sourceDocument.customerName, 'Walk-in Customer'),
        highlight: true,
      ),
      if (sourceDocument.mobile.trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'phone',
          label: 'Mobile',
          value: sourceDocument.mobile.trim(),
        ),
      if (sourceDocument.address.trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'location',
          label: 'Address',
          value: sourceDocument.address.trim(),
          multiline: true,
        ),
    ],
  );
}

LotusPrintablePanel _printableSourcePanel(
  ReturnReversalState state,
  ReturnReversalSourceDocument sourceDocument,
) {
  return LotusPrintablePanel(
    title: 'SOURCE DOCUMENT',
    details: [
      LotusPrintableDetail(
        iconKey: 'invoice',
        label: 'Source No',
        value: sourceDocument.documentNo,
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'calendar',
        label: 'Source Date',
        value: _formatDate(sourceDocument.documentDate),
      ),
      LotusPrintableDetail(
        iconKey: 'items',
        label: 'Source Type',
        value: sourceDocument.type.label,
      ),
      LotusPrintableDetail(
        iconKey: 'status',
        label: 'Desk Mode',
        value: state.operationType.ledgerLabel,
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'amount',
        label: 'Original Total',
        value: _formatMoney(sourceDocument.finalAmount),
      ),
      LotusPrintableDetail(
        iconKey: 'payment',
        label: 'Amount Received',
        value: _formatMoney(sourceDocument.paidAmount),
      ),
    ],
  );
}

LotusPrintableTable _printableItemTable(
  ReturnReversalVoucherDocumentKind kind,
  List<_VoucherRow> rows,
  ReturnReversalVoucherPrintOptions options,
) {
  final headers = <String>[
    'S. No.',
    'Item',
    'Metal',
    'Sold Wt',
    'Received Wt',
  ];
  if (options.includeOriginalPricing) headers.add('Invoice Value');
  headers.add('Return');
  if (options.includeStockRouting &&
      kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
    headers.add('Route');
  }

  return LotusPrintableTable(
    title: 'RETURN LINES',
    headers: headers,
    rows: [
      for (final row in rows)
        [
          row.line.lineNo.toString(),
          row.line.description,
          row.line.metalType,
          '${_formatWeight(row.line.netWeight)} g',
          '${_formatWeight(row.draft.receivedNetWeight)} g',
          if (options.includeOriginalPricing)
            _formatMoney(row.adjustedLineAmount),
          _formatMoney(row.returnValue),
          if (options.includeStockRouting &&
              kind != ReturnReversalVoucherDocumentKind.bookingCancellation)
            row.draft.stockRoute.label,
        ],
    ],
  );
}

List<LotusPrintablePanel> _printableSettlementPanels(
  ReturnReversalVoucherDocumentKind kind,
  ReturnReversalSourceDocument sourceDocument,
  List<_VoucherRow> rows,
  _VoucherSettlement settlement,
  ReturnReversalVoucherPrintOptions options,
) {
  return [
    if (options.includeSettlement)
      LotusPrintablePanel(
        title: kind.settlementTitle.toUpperCase(),
        details: [
          LotusPrintableDetail(
            iconKey: 'amount',
            label: kind == ReturnReversalVoucherDocumentKind.bookingCancellation
                ? 'Refund Value'
                : 'Return Value',
            value: _formatMoney(settlement.returnValue),
            highlight: true,
          ),
          if (settlement.dueAdjustedAmount > 0.005)
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Due Adjusted',
              value: _formatMoney(settlement.dueAdjustedAmount),
            ),
          LotusPrintableDetail(
            iconKey: 'amount',
            label: kind == ReturnReversalVoucherDocumentKind.bookingCancellation
                ? 'Refund Payable'
                : 'Refund Payable',
            value: _formatMoney(settlement.refundPayableAmount),
            highlight: true,
          ),
        ],
      ),
    if (options.includeVerificationAudit)
      LotusPrintablePanel(
        title: 'VERIFICATION AUDIT',
        details: [
          LotusPrintableDetail(
            iconKey: 'verified',
            label: 'Matched Lines',
            value: _matchedLineSummary(rows),
            highlight: true,
          ),
          LotusPrintableDetail(
            iconKey: 'items',
            label: 'Line Count',
            value: '${rows.length}',
          ),
          LotusPrintableDetail(
            iconKey: 'invoice',
            label: 'Source No',
            value: sourceDocument.documentNo,
          ),
        ],
      ),
  ];
}
