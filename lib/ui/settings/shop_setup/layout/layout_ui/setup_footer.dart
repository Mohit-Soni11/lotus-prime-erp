import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../theme/settings/shop_setup/layout/layout_theme.dart';

class SetupFooter extends StatelessWidget {
  final VoidCallback onNext;
  final bool isLoading;
  final bool isLastStep;

  const SetupFooter({
    super.key,
    required this.onNext,
    this.isLoading = false,
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: LayoutColors.panelBg.withOpacity(0.9),
            border: const Border(top: BorderSide(color: LayoutColors.borderStroke, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- LEFT: SUBTLE TRUST BADGE ---
              _buildTrustBadge(),

              // --- RIGHT: GOLD BUTTON ---
              _buildElegantButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Row(
      children: [
        // ✅ Updated: Uses 'textPlaceholder'
        const Icon(Icons.lock_outline_rounded, color: LayoutColors.textPlaceholder, size: 16),
        const SizedBox(width: 8),
        Text(
          "Secured by 256-bit Encryption",
          style: GoogleFonts.inter(
            // ✅ Updated: Uses 'textPlaceholder'
            color: LayoutColors.textPlaceholder, 
            fontSize: 12,
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }

  Widget _buildElegantButton() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        // ✅ Updated: Uses 'goldGradient'
        gradient: isLoading ? null : LayoutColors.goldGradient,
        color: isLoading ? LayoutColors.cardSurface : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isLoading ? [] : [
          BoxShadow(
            // ✅ Updated: Uses 'goldPrimary'
            color: LayoutColors.goldPrimary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: LayoutColors.textBody, strokeWidth: 2))
            : Row(
                children: [
                  Text(
                    isLastStep ? "COMPLETE SETUP" : "CONTINUE",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF18181B), // Dark text on Gold is best for contrast
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF18181B), size: 16),
                ],
              ),
      ),
    );
  }
}