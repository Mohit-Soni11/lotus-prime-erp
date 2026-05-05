import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'metal_card_shell.dart';
import 'stock_metal_ui.dart';

class SilverStockCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback onTap;

  const SilverStockCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.silver);

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
                Expanded(
                  child: Text(
                    'Fast rack movement',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ui.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(ui.icon, size: 20, color: ui.accent),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              ui.title,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ui.tagLine,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.accent.withOpacity(0.16)),
              ),
              child: Column(
                children: [
                  _line('Purity presets', ui.quickTag),
                  const SizedBox(height: 10),
                  _line('Entry mode', 'Multi-piece batch intake'),
                  const SizedBox(height: 10),
                  _line('Ideal for', 'Anklets, chains, gifting items'),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ui.accent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ui.accent.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
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

  Widget _line(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF748A98),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
