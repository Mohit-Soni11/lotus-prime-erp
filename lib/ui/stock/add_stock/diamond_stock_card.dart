import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'metal_card_shell.dart';
import 'stock_metal_ui.dart';

class DiamondStockCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback onTap;

  const DiamondStockCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.diamond);

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
                _facetOrb(ui.accent, 56),
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
                          color: const Color(0xFF10233A),
                        ),
                      ),
                      Text(
                        'Premium stone desk',
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
                    ui.accent.withOpacity(0.12),
                    Colors.white.withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ui.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ui.helperLine,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: const Color(0xFF35516C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge('Carats'),
                      _badge('Stone value'),
                      _badge(ui.quickTag),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Open premium intake',
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

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x331FA8E7)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF24557A),
        ),
      ),
    );
  }

  Widget _facetOrb(Color accent, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accent.withOpacity(0.24)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(0.28), width: 1.4),
      ),
      child: Icon(Icons.auto_awesome_rounded, size: 24, color: accent),
    );
  }
}
