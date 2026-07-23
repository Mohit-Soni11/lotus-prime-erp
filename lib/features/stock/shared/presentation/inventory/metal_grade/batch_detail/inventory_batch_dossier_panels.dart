part of '../../inventory_screen.dart';

class _BatchDossierHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final String title;
  final _InventoryBatchGroup batch;
  final VoidCallback onDocuments;
  final VoidCallback? onCloseVariance;
  final bool isClosingVariance;

  const _BatchDossierHeader({
    required this.ui,
    required this.title,
    required this.batch,
    required this.onDocuments,
    required this.onCloseVariance,
    required this.isClosingVariance,
  });

  @override
  Widget build(BuildContext context) {
    final statusAccent = _dossierBatchStatusAccent(batch);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        batch.batchCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: ui.textOnGradient,
                        ),
                      ),
                    ),
                    if (batch.isGst) ...[
                      const SizedBox(width: 10),
                      _HeaderGstTag(textColor: ui.textOnGradient),
                    ],
                    const SizedBox(width: 10),
                    _DossierHeaderStatusTag(
                      label: batch.stockStatusLabel,
                      accent: statusAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  batch.dossierSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ui.textOnGradient.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderMetric(
                label: 'Quantity',
                value: batch.quantityBalanceLabel,
                textColor: ui.textOnGradient,
              ),
              _HeaderMetric(
                label: 'Actual Fine',
                value: '${_weight(batch.actualFine)} g',
                textColor: ui.textOnGradient,
              ),
              if (onCloseVariance != null)
                _HeaderActionButton(
                  label: isClosingVariance ? 'Closing...' : 'Close Variance',
                  icon: Icons.fact_check_rounded,
                  textColor: ui.textOnGradient,
                  onTap: isClosingVariance ? null : onCloseVariance,
                ),
              _HeaderActionButton(
                label: 'Documents',
                icon: Icons.description_rounded,
                textColor: ui.textOnGradient,
                onTap: onDocuments,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryBatchPdfPreviewScreen extends StatelessWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final _InventoryBatchGroup batch;
  final _InventoryBatchDocumentType type;

  const _InventoryBatchPdfPreviewScreen({
    required this.metal,
    required this.grade,
    required this.batch,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: _batchPdfFileName(batch, type),
        build: (_) => _buildBatchPdfBytes(
          metal: metal,
          grade: grade,
          batch: batch,
          type: type,
        ),
      ),
    );
  }
}

class _InventoryBatchDocumentDialog extends StatelessWidget {
  final ValueChanged<_InventoryBatchDocumentType> onView;
  final ValueChanged<_InventoryBatchDocumentType> onPrint;
  final ValueChanged<_InventoryBatchDocumentType> onDownload;

  const _InventoryBatchDocumentDialog({
    required this.onView,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 18,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: InvColors.brandGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: InvColors.brandGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Documents',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: InvColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Preview, print or download professional inventory PDFs.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: InvColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final type in _InventoryBatchDocumentType.values) ...[
                _InventoryBatchDocumentOption(
                  type: type,
                  onView: () => onView(type),
                  onPrint: () => onPrint(type),
                  onDownload: () => onDownload(type),
                ),
                if (type != _InventoryBatchDocumentType.values.last)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryBatchDocumentOption extends StatelessWidget {
  final _InventoryBatchDocumentType type;
  final VoidCallback onView;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  const _InventoryBatchDocumentOption({
    required this.type,
    required this.onView,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: InvColors.brandGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              type == _InventoryBatchDocumentType.fullDossier
                  ? Icons.assignment_rounded
                  : Icons.fact_check_rounded,
              color: InvColors.brandGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _DocumentMiniAction(
            label: 'View',
            icon: Icons.visibility_rounded,
            onTap: onView,
          ),
          const SizedBox(width: 8),
          _DocumentMiniAction(
            label: 'Print',
            icon: Icons.print_rounded,
            onTap: onPrint,
          ),
          const SizedBox(width: 8),
          _DocumentMiniAction(
            label: 'Download',
            icon: Icons.download_rounded,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}

class _DocumentMiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DocumentMiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: InvColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: InvColors.brandGold.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: InvColors.brandGold),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchOverviewPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchOverviewPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return _DossierPanel(
      icon: Icons.inventory_2_rounded,
      title: 'Batch Overview',
      subtitle: 'Supplier, quantity, purity and valuation profile',
      accent: ui.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (batch.supplierName.trim().isNotEmpty)
            _DossierInfoRow(label: 'Supplier', value: batch.supplierName),
          if (batch.supplierInvoiceNo.trim().isNotEmpty)
            _DossierInfoRow(
              label: 'Supplier Invoice',
              value: batch.supplierInvoiceNo,
            ),
          if (batch.taxType.trim().isNotEmpty)
            _DossierInfoRow(
                label: 'Purchase Type',
                value: batch.isGst ? 'GST Purchase' : 'Non-GST Purchase'),
          if (batch.createdAt > 0)
            _DossierInfoRow(
              label: 'Batch Date',
              value: DateFormat('dd MMM yyyy').format(
                DateTime.fromMillisecondsSinceEpoch(batch.createdAt),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DossierMetric(
                  label: 'Total Qty',
                  value: batch.totalQuantityLabel,
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Available Qty',
                  value: batch.availableQuantityLabel,
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Sold Qty',
                  value: batch.soldQuantityLabel,
                  accent: InvColors.danger),
              if (_hasWeightDifference(
                  batch.totalGrossWeight, batch.totalNetWeight))
                _DossierMetric(
                    label: 'Gross Weight',
                    value: '${_weight(batch.totalGrossWeight)} g',
                    accent: ui.accent),
              _DossierMetric(
                  label: 'Total Weight',
                  value: '${_weight(batch.totalNetWeight)} g',
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Available Weight',
                  value: '${_weight(batch.availableNetWeight)} g',
                  accent: const Color(0xFF0F766E)),
              if (batch.soldNetWeight > 0)
                _DossierMetric(
                    label: 'Sold Weight',
                    value: '${_weight(batch.soldNetWeight)} g',
                    accent: InvColors.danger),
              if (batch.hasScaleVariance)
                _DossierMetric(
                    label: 'Scale Variance',
                    value: batch.scaleVarianceLabel,
                    accent: batch.hasResidualWeight
                        ? const Color(0xFFF59E0B)
                        : InvColors.danger),
              if (batch.purityPercent > 0)
                _DossierMetric(
                    label: 'Base Purity',
                    value: '${_percent(batch.purityPercent)}%',
                    accent: const Color(0xFF2563EB)),
              if (batch.wastagePercent > 0)
                _DossierMetric(
                    label: 'Wastage',
                    value: '${_percent(batch.wastagePercent)}%',
                    accent: const Color(0xFFF59E0B)),
              if (batch.valuationPurityPercent > 0)
                _DossierMetric(
                    label: 'Valuation Purity',
                    value: '${_percent(batch.valuationPurityPercent)}%',
                    accent: InvColors.brandGold),
              if (batch.actualFine > 0)
                _DossierMetric(
                    label: 'Actual Fine',
                    value: '${_weight(batch.actualFine)} g',
                    accent: InvColors.success),
              if (batch.valuationFine > 0)
                _DossierMetric(
                    label: 'Valuation Fine',
                    value: '${_weight(batch.valuationFine)} g',
                    accent: InvColors.brandGold),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color textColor;
  final VoidCallback? onTap;

  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchPaymentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchPaymentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final payment = batch.payment;
    return _DossierPanel(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Payment Summary',
      subtitle: 'Cash, metal, GST, due and return snapshot',
      accent: ui.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_paymentMetrics(payment).isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in _paymentMetrics(payment))
                  _DossierMetric(
                    label: metric.label,
                    value: metric.value,
                    accent: metric.accent,
                  ),
              ],
            ),
          if (_paymentMetrics(payment).isNotEmpty &&
              _paymentInfoRows(payment, batch.isGst).isNotEmpty)
            const SizedBox(height: 12),
          for (final row in _paymentInfoRows(payment, batch.isGst))
            _DossierInfoRow(label: row.label, value: row.value),
          if (_paymentMetrics(payment).isEmpty &&
              _paymentInfoRows(payment, batch.isGst).isEmpty)
            Text(
              'No payment settlement information is recorded for this batch.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: InvColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  List<_DossierMetricData> _paymentMetrics(_InventoryPaymentSummary payment) {
    final metrics = <_DossierMetricData>[];
    if (payment.grandTotal > 0) {
      metrics.add(_DossierMetricData(
          'Final Bill', _money(payment.grandTotal), ui.accent));
    }
    if (payment.totalPaid > 0) {
      metrics.add(_DossierMetricData(
          'Total Paid', _money(payment.totalPaid), InvColors.success));
    }
    if (payment.balanceDue > 0) {
      metrics.add(_DossierMetricData(
          'Cash Due', _money(payment.balanceDue), InvColors.danger));
    }
    if (payment.metalPaidFine > 0) {
      metrics.add(_DossierMetricData('Metal Paid',
          '${_weight(payment.metalPaidFine)} g', InvColors.brandGold));
    }
    if (payment.fineDueWeight > 0) {
      metrics.add(_DossierMetricData(
          'Fine Due', '${_weight(payment.fineDueWeight)} g', InvColors.danger));
    }
    if (payment.fineReturnWeight > 0) {
      metrics.add(_DossierMetricData('Fine Return',
          '${_weight(payment.fineReturnWeight)} g', const Color(0xFF0F766E)));
    }
    if (payment.supplierCreditValue > 0) {
      metrics.add(_DossierMetricData('Supplier Credit',
          _money(payment.supplierCreditValue), InvColors.brandGold));
    }
    return metrics;
  }

  List<_DossierInfoData> _paymentInfoRows(
    _InventoryPaymentSummary payment,
    bool isGst,
  ) {
    final rows = <_DossierInfoData>[];
    if (payment.paymentMode.trim().isNotEmpty) {
      rows.add(
          _DossierInfoData('Payment Mode', _titleCase(payment.paymentMode)));
    }
    if (payment.cashPaid > 0) {
      rows.add(_DossierInfoData('Cash', _money(payment.cashPaid)));
    }
    if (payment.upiPaid > 0) {
      rows.add(_DossierInfoData('UPI', _money(payment.upiPaid)));
    }
    if (payment.bankPaid > 0) {
      rows.add(_DossierInfoData('Bank', _money(payment.bankPaid)));
    }
    if (payment.cardPaid > 0) {
      rows.add(_DossierInfoData('Card', _money(payment.cardPaid)));
    }
    if (isGst && payment.gstAmount > 0) {
      rows.add(_DossierInfoData('GST Total', _money(payment.gstAmount)));
      rows.add(_DossierInfoData(
        'CGST / SGST',
        '${_money(payment.cgstAmount)} / ${_money(payment.sgstAmount)}',
      ));
    }
    if (payment.paymentStatus.trim().isNotEmpty) {
      rows.add(_DossierInfoData('Status', payment.paymentStatus));
    }
    return rows;
  }
}

class _BatchDocumentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchDocumentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final path = batch.payment.attachmentPath.trim();
    return _DossierPanel(
      icon: Icons.attach_file_rounded,
      title: 'Supplier Bill Document',
      subtitle: 'View or locate the bill attached during stock intake',
      accent: ui.accent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              path.isEmpty
                  ? 'No supplier bill attachment is linked with this batch.'
                  : path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: path.isEmpty ? InvColors.textMuted : InvColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DossierActionButton(
            label: 'Open Bill',
            icon: Icons.open_in_new_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _openLocalPath(path),
          ),
          const SizedBox(width: 10),
          _DossierActionButton(
            label: 'Show File',
            icon: Icons.folder_open_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _showLocalFile(path),
          ),
        ],
      ),
    );
  }
}

class _BatchStockLedgerPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchStockLedgerPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return _DossierPanel(
      icon: Icons.view_list_rounded,
      title: 'Batch Item Ledger',
      subtitle: 'Item-wise quantity, unit, weight and sale balance',
      accent: ui.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 1180
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DossierMetric(
                    label: 'Total Qty',
                    value: batch.totalQuantityLabel,
                    accent: ui.accent,
                  ),
                  _DossierMetric(
                    label: 'Available Qty',
                    value: batch.availableQuantityLabel,
                    accent: InvColors.success,
                  ),
                  _DossierMetric(
                    label: 'Sold Qty',
                    value: batch.soldQuantityLabel,
                    accent: InvColors.danger,
                  ),
                  _DossierMetric(
                    label: 'Total Weight',
                    value: '${_weight(batch.totalNetWeight)} g',
                    accent: ui.accent,
                  ),
                  _DossierMetric(
                    label: 'Available Weight',
                    value: '${_weight(batch.availableNetWeight)} g',
                    accent: InvColors.success,
                  ),
                  if (batch.soldNetWeight > 0)
                    _DossierMetric(
                      label: 'Sold Weight',
                      value: '${_weight(batch.soldNetWeight)} g',
                      accent: InvColors.danger,
                    ),
                  if (batch.hasScaleVariance)
                    _DossierMetric(
                      label: 'Scale Variance',
                      value: batch.scaleVarianceLabel,
                      accent: batch.hasResidualWeight
                          ? const Color(0xFFF59E0B)
                          : InvColors.danger,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _DossierLedgerSection(
                title: 'Stock Item Lines',
                subtitle: 'Total, available and sold movement per item',
                units: batch.units,
                itemWidth: itemWidth,
                ui: ui,
                accent: ui.accent,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DossierMetricData {
  final String label;
  final String value;
  final Color accent;

  const _DossierMetricData(this.label, this.value, this.accent);
}

class _DossierInfoData {
  final String label;
  final String value;

  const _DossierInfoData(this.label, this.value);
}

class _DossierLedgerSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_InventoryGradeUnit> units;
  final double itemWidth;
  final StockMetalUiData ui;
  final Color accent;

  const _DossierLedgerSection({
    required this.title,
    required this.subtitle,
    required this.units,
    required this.itemWidth,
    required this.ui,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                _stockUnitCountText(units.length),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: InvColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final unit in units)
              SizedBox(
                width: itemWidth,
                child: _InventoryGradeUnitCard(unit: unit, ui: ui),
              ),
          ],
        ),
      ],
    );
  }
}

Color _dossierBatchStatusAccent(_InventoryBatchGroup batch) {
  if (batch.hasScaleVariance) return const Color(0xFFF59E0B);
  if (batch.isSoldOut) return InvColors.danger;
  if (batch.isPartiallySold) return const Color(0xFFF59E0B);
  return InvColors.success;
}
