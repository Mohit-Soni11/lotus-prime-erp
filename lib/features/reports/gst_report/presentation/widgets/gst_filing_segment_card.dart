import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/gst_report_segment_projector.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';

class GstFilingSegmentCard extends StatefulWidget {
  const GstFilingSegmentCard({
    super.key,
    required this.segment,
    required this.invoiceCount,
    required this.taxableValue,
    required this.taxPayable,
    required this.auditCount,
    required this.onTap,
  });

  final GstFilingSegment segment;
  final int invoiceCount;
  final double taxableValue;
  final double taxPayable;
  final int auditCount;
  final VoidCallback onTap;

  @override
  State<GstFilingSegmentCard> createState() => _GstFilingSegmentCardState();
}

class _GstFilingSegmentCardState extends State<GstFilingSegmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.segment);
    final active = _hovered;
    final borderColor = palette.accent.withValues(alpha: active ? 0.40 : 0.26);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: active ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: palette.accent.withValues(alpha: 0.08),
            highlightColor: palette.accent.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: active ? 0.05 : 0.02),
                    blurRadius: active ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: palette.gradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _iconFor(widget.segment),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.segment.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: GstReportColors.textPrimary,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _descriptionFor(widget.segment),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: GstReportColors.textSecondary,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Invoices',
                            value:
                                GstReportFormatters.count(widget.invoiceCount),
                            accent: palette.accent,
                            tint: palette.tint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Tax Payable',
                            value: GstReportFormatters.money(widget.taxPayable),
                            accent: palette.accent,
                            tint: palette.tint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Taxable Value',
                            value:
                                GstReportFormatters.money(widget.taxableValue),
                            accent: palette.accent,
                            tint: palette.tint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Audit Alerts',
                            value: GstReportFormatters.count(widget.auditCount),
                            accent: widget.auditCount > 0
                                ? GstReportColors.danger
                                : GstReportColors.success,
                            tint: palette.tint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Open ${widget.segment.code} Workspace',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.accent,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: palette.accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return Icons.business_center_rounded;
      case GstFilingSegment.b2c:
        return Icons.storefront_rounded;
    }
  }

  static String _descriptionFor(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return 'Registered customer GSTIN ledger, IFF-ready B2B invoices and HSN filing checks';
      case GstFilingSegment.b2c:
        return 'Retail customer GST sales, place-of-supply tax split and non-GST estimate view';
    }
  }

  static _SegmentPalette _paletteFor(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return const _SegmentPalette(
          accent: GstReportColors.taxGreen,
          surface: Color(0xFFFFFFFF),
          tint: Color(0xFFE7F7F2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
        );
      case GstFilingSegment.b2c:
        return const _SegmentPalette(
          accent: GstReportColors.information,
          surface: Color(0xFFFFFFFF),
          tint: Color(0xFFEAF1FF),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF316BD6), Color(0xFF7C9BEF)],
          ),
        );
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.tint,
  });

  final String label;
  final String value;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: GstReportColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: GstReportColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentPalette {
  const _SegmentPalette({
    required this.accent,
    required this.surface,
    required this.tint,
    required this.gradient,
  });

  final Color accent;
  final Color surface;
  final Color tint;
  final LinearGradient gradient;
}
