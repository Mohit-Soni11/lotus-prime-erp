import 'package:flutter/material.dart';

import '../../application/gst_report_segment_projector.dart';
import '../../domain/gst_filing_period.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';

class GstFilingCompletionDialog extends StatelessWidget {
  const GstFilingCompletionDialog({
    super.key,
    required this.segment,
    required this.snapshot,
    required this.filing,
  });

  final GstFilingSegment segment;
  final GstReportSnapshot snapshot;
  final GstFilingPeriod filing;

  static Future<bool> show({
    required BuildContext context,
    required GstFilingSegment segment,
    required GstReportSnapshot snapshot,
    required GstFilingPeriod filing,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GstFilingCompletionDialog(
        segment: segment,
        snapshot: snapshot,
        filing: filing,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final segmentInvoices = _segmentInvoices;
    final segmentTax = _sum(segmentInvoices, (row) => row.gstAmount);
    final monthLabel = GstReportFormatters.monthYear(filing.month);
    final dueDate = filing.isQuarterClosingMonth
        ? filing.gstr3bDueDateForStateCode(snapshot.identity.stateCode)
        : filing.monthlyTaxPaymentDueDate;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Material(
          color: GstReportColors.bodyPanel,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              color: GstReportColors.bodyPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GstReportColors.bodyBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GstReportColors.taxGreen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: GstReportColors.taxGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm GST Filing Completion',
                            style: GstReportStyles.sectionTitle,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Please confirm only after the required GST work is filed or paid.',
                            style:
                                GstReportStyles.body.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(false),
                      style: IconButton.styleFrom(
                        foregroundColor: GstReportColors.textSecondary,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GstReportColors.bodySubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GstReportColors.bodyBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Filing Period',
                          value: monthLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryMetric(
                          label: '${segment.code} GST',
                          value: GstReportFormatters.money(segmentTax),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Output GST Liability',
                          value: GstReportFormatters.money(
                            snapshot.dashboard.totalGst,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Checklist(
                  title: 'Before marking complete',
                  rows: _checklistRows(dueDate),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GstReportColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: GstReportColors.warning.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: GstReportColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This will save the current GST amount as a filing snapshot. It will not change invoice values.',
                          style: GstReportStyles.body.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: GstReportColors.textSecondary,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: GstReportColors.taxGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Yes, Complete Filing'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<GstInvoiceRow> get _segmentInvoices {
    switch (segment) {
      case GstFilingSegment.b2b:
        return snapshot.gstr1B2bInvoices;
      case GstFilingSegment.b2c:
        return snapshot.gstr1B2cInvoices;
    }
  }

  List<_ChecklistRow> _checklistRows(DateTime dueDate) {
    final rows = <_ChecklistRow>[
      if (filing.hasMonthlyTaxPayment)
        _ChecklistRow(
          title: 'PMT-06 Monthly Tax Payment',
          detail:
              'Pay ${GstReportFormatters.money(snapshot.dashboard.totalGst)} for ${GstReportFormatters.monthYear(filing.month)} by ${GstReportFormatters.date(filing.monthlyTaxPaymentDueDate)}.',
        ),
      if (segment == GstFilingSegment.b2b && filing.iffDueDate != null)
        _ChecklistRow(
          title: 'IFF B2B Upload',
          detail:
              'Upload B2B invoices by ${GstReportFormatters.date(filing.iffDueDate!)} if you are using IFF for this QRMP month.',
        ),
      _ChecklistRow(
        title: '${segment.code} GST Workspace',
        detail:
            '${_segmentInvoices.length} invoices checked with taxable value and GST split.',
      ),
      const _ChecklistRow(
        title: 'GST Audit Checks',
        detail:
            'Missing HSN, GSTIN, place of supply and GST split warnings reviewed.',
      ),
      if (filing.isQuarterClosingMonth)
        _ChecklistRow(
          title: 'GSTR-1 and GSTR-3B Quarter Filing',
          detail:
              'Quarter final filing for ${filing.quarterLabel} ${filing.quarterRangeLabel}; final 3B due ${GstReportFormatters.date(dueDate)}.',
        ),
    ];
    return rows;
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return rows.fold<double>(0, (sum, row) => sum + selector(row));
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GstReportStyles.body.copyWith(
            color: GstReportColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GstReportStyles.body.copyWith(
            color: GstReportColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_ChecklistRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: GstReportColors.taxGreen,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.detail,
                        style: GstReportStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (row != rows.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow {
  const _ChecklistRow({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}
