import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_invoice_summary_logic.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldInvoiceSummaryPanel extends StatelessWidget {
  final GoldStockController ctrl;

  const GoldInvoiceSummaryPanel({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final summary = ctrl.invoiceSummary;

        return Container(
          decoration: BoxDecoration(
            color: GoldStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GoldStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GoldStockColors.shadowLight,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: GoldStockColors.shadowMedium,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(summary: summary),
              const Divider(height: 1, color: GoldStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MetricGrid(summary: summary),
                    const SizedBox(height: 14),
                    _SnapshotList(summary: summary),
                    const SizedBox(height: 14),
                    _TotalsSection(summary: summary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final GoldInvoiceSummaryData summary;

  const _PanelHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final accent = summary.gstEnabled
        ? GoldStockColors.success
        : GoldStockColors.paymentPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(
              GoldStockIcons.invoiceSummary,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GoldStockStrings.invoiceSummaryTitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: GoldStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  GoldStockStrings.invoiceSummarySubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GoldStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: summary.gstEnabled
                ? GoldStockStrings.gstIncludedLabel
                : GoldStockStrings.gstExcludedLabel,
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final GoldInvoiceSummaryData summary;

  const _MetricGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tiles = <_MetricTileData>[
      _MetricTileData(
        label: GoldStockStrings.overviewPieces,
        value: '${summary.rowCount}',
        caption: 'One Gold item per row',
        tone: GoldStockColors.paymentPrimary,
      ),
      _MetricTileData(
        label: GoldStockStrings.overviewGross,
        value: '${summary.totalGrossWeight.toStringAsFixed(3)} g',
        tone: GoldStockColors.accentMetal,
      ),
      _MetricTileData(
        label: GoldStockStrings.totalFineLabel,
        value: '${summary.totalFineWeight.toStringAsFixed(3)} g',
        tone: GoldStockColors.paymentFine,
      ),
      _MetricTileData(
        label: GoldStockStrings.makingTotalLabel,
        value: _money(summary.totalMakingAmount),
        tone: GoldStockColors.accentPricing,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - ((columns - 1) * gap)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: width,
                  child: _MetricTile(data: tile),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SnapshotList extends StatelessWidget {
  final GoldInvoiceSummaryData summary;

  const _SnapshotList({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GoldStockColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: GoldStockColors.invoiceChipBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GoldStockColors.invoiceChipBorder,
                  ),
                ),
                child: const Icon(
                  GoldStockIcons.lineSnapshot,
                  size: 15,
                  color: GoldStockColors.paymentPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GoldStockStrings.invoiceSnapshotTitle.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: GoldStockColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      GoldStockStrings.invoiceSnapshotSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GoldStockColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!summary.hasItems)
            const _SoftInfoNote(
              tone: GoldStockColors.paymentNeutral,
              text:
                  'Add at least one Gold line to generate the invoice snapshot.',
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.min(360, 116.0 * summary.items.length),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: summary.items.length,
                itemBuilder: (context, index) =>
                    _SnapshotRow(item: summary.items[index]),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
          if (summary.hasRateVariance) ...[
            const SizedBox(height: 12),
            const _SoftInfoNote(
              tone: GoldStockColors.warning,
              text: GoldStockStrings.rateVarianceNote,
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final GoldInvoiceLineSnapshot item;

  const _SnapshotRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GoldStockColors.invoiceRowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldStockColors.invoiceRowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isEmpty
                          ? 'Untitled Gold Line'
                          : item.itemName,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: GoldStockColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          label: item.categoryLabel.isEmpty
                              ? 'Category Pending'
                              : item.categoryLabel,
                        ),
                        _MetaChip(
                          label:
                              '${GoldStockStrings.purityLabelShort} ${item.totalPurityPercent.toStringAsFixed(2)}%',
                        ),
                        _MetaChip(
                          label:
                              '${GoldStockStrings.perGramLabel} ${_money(item.ratePerGram)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    GoldStockStrings.lineTotalLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                      color: GoldStockColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(item.totalAmount),
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: GoldStockColors.paymentPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _DetailPill(
                label: GoldStockStrings.overviewGross,
                value: '${item.grossWeight.toStringAsFixed(3)} g',
              ),
              _DetailPill(
                label: GoldStockStrings.totalFineLabel,
                value: '${item.fineWeight.toStringAsFixed(3)} g',
              ),
              _DetailPill(
                label: GoldStockStrings.makingTotalLabel,
                value: '${_money(item.makingAmount)} • ${item.makingTypeLabel}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  final GoldInvoiceSummaryData summary;

  const _TotalsSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final accent = summary.gstEnabled
        ? GoldStockColors.success
        : GoldStockColors.paymentPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: GoldStockStrings.itemSnapshotTotalLabel,
            value: _money(summary.itemSnapshotAmount),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: GoldStockStrings.invoiceSubtotalLabel,
            value: _money(summary.invoiceSubtotal),
          ),
          if (summary.gstEnabled) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'GST',
              value: _money(summary.invoiceGstAmount),
              valueColor: GoldStockColors.success,
            ),
          ],
          const SizedBox(height: 10),
          _SummaryRow(
            label: GoldStockStrings.finalBillAmountLabel,
            value: _money(summary.finalBillAmount),
            emphasized: true,
            valueColor: accent,
          ),
        ],
      ),
    );
  }
}

class _MetricTileData {
  final String label;
  final String value;
  final String? caption;
  final Color tone;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.tone,
    this.caption,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricTileData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: data.tone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: GoldStockColors.textDark,
            ),
          ),
          if (data.caption != null) ...[
            const SizedBox(height: 4),
            Text(
              data.caption!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GoldStockColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: GoldStockColors.invoiceChipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GoldStockColors.invoiceChipBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: GoldStockColors.textBody,
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final String value;

  const _DetailPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldStockColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: GoldStockColors.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: GoldStockColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: emphasized ? 13 : 12,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            color: GoldStockColors.textBody,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: emphasized ? 18 : 14,
            fontWeight: FontWeight.w900,
            color: valueColor ?? GoldStockColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _SoftInfoNote extends StatelessWidget {
  final Color tone;
  final String text;

  const _SoftInfoNote({required this.tone, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tone,
          height: 1.45,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

String _money(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
