import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/metal_card_shell.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';

class GoldStockCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback onTap;

  const GoldStockCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.gold);

    return MetalCardShell(
      animationController: animationController,
      delay: delay,
      accent: ui.accent,
      surface: ui.softSurface,
      onTap: onTap,
      child: SizedBox(
        height: 212,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _goldOrb(56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ui.title,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2530),
                        ),
                      ),
                      Text(
                        'Sona inventory desk',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ui.accent,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ui.accent.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ui.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ui.helperLine,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge('Batch entry', ui.accent),
                      _badge('Hallmark', ui.accent),
                      _badge(ui.quickTag, ui.accent),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Open Gold inventory',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ui.accent,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, size: 18, color: ui.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _goldOrb(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/logo/gold.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _badge(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}
