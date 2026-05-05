import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'metal_card_shell.dart';
import 'stock_metal_ui.dart';

class PlatinumStockCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback onTap;

  const PlatinumStockCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.platinum);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ui.title,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      _ring(ui.accent.withOpacity(0.24)),
                      Positioned(left: 8, child: _ring(ui.accent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Premium wedding bands and custom pieces',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _panel('Purity desk', ui.quickTag, ui.accent)),
                const SizedBox(width: 10),
                Expanded(
                  child: _panel(
                    'Workflow',
                    'Precise, low-volume intake',
                    ui.accent,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ui.accent.withOpacity(0.16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 16,
                    color: ui.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High-value, minimalist desk with premium controls',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: ui.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
    );
  }
}
