import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'metal_card_shell.dart';
import 'stock_metal_ui.dart';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pill('Hallmark lane', ui.accent),
                      const SizedBox(height: 14),
                      Text(
                        ui.title,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${ui.hindiTitle} inventory',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF7C6221),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _coin(ui.accent.withOpacity(0.18), 46),
                    Positioned(right: 18, top: 18, child: _coin(ui.accent, 34)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniChip('22K Ready', ui.accent),
                _miniChip('Bridal', ui.accent),
                _miniChip(ui.quickTag, ui.accent),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.74),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.accent.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Expanded(child: _metric('HUID', 'Enabled')),
                  Container(
                    width: 1,
                    height: 24,
                    color: ui.accent.withOpacity(0.18),
                  ),
                  Expanded(child: _metric('Costing', 'Owner locked')),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: ui.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coin(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.4),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}
