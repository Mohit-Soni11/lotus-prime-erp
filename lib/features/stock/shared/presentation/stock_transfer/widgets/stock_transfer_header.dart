import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_shared_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferHeader extends StatelessWidget {
  final StockTransferSummary summary;

  const StockTransferHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8D8), Color(0xFFE3B821)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: InvColors.brandGold.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Icon(
                      Icons.sync_alt_rounded,
                      color: Color(0xFF8A5F00),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Transfer Desk',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2F2100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Branch, counter, vault and exhibition movement with unit-level audit.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4E3905),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: compact ? 2 : 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: compact ? 2.6 : 2.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _HeroMetric(
                    label: 'Available',
                    value: '${summary.availableUnits} pcs',
                  ),
                  _HeroMetric(
                    label: 'In Transit',
                    value: '${summary.inTransitUnits} pcs',
                  ),
                  _HeroMetric(
                    label: 'Open Slips',
                    value: '${summary.inTransitTransfers}',
                  ),
                  _HeroMetric(
                    label: 'Transferred Today',
                    value: '${summary.transferredToday} pcs',
                  ),
                  _HeroMetric(
                    label: 'Transit Weight',
                    value: transferWeight(summary.inTransitNetWeight),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6F560C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
