import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';

class GirviBillingIntroPanel extends StatelessWidget {
  final Color accent;
  final bool autoPrint;
  final int invoiceFieldCount;

  const GirviBillingIntroPanel({
    super.key,
    required this.accent,
    required this.autoPrint,
    required this.invoiceFieldCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Icon(Icons.security_rounded, color: accent, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Girvi billing controls',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BillingSetupColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage interest calculation, receipt fields and printed customer terms.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.35,
                        color: BillingSetupColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final pills = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _SummaryPill(
                label: '$invoiceFieldCount active fields',
                icon: Icons.view_column_outlined,
                accent: accent,
              ),
              _SummaryPill(
                label: autoPrint ? 'Auto print on' : 'Auto print off',
                icon: Icons.print_rounded,
                accent: accent,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 14),
                pills,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 14),
              pills,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _SummaryPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BillingSetupColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
