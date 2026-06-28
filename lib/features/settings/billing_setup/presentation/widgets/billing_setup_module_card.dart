import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../domain/entities/billing_setup_module.dart';
import '../theme/billing_setup_design_tokens.dart';

class BillingSetupModuleCard extends StatefulWidget {
  final BillingSetupModule module;
  final VoidCallback onOpen;
  final double height;

  const BillingSetupModuleCard({
    super.key,
    required this.module,
    required this.onOpen,
    this.height = 218,
  });

  @override
  State<BillingSetupModuleCard> createState() => _BillingSetupModuleCardState();
}

class _BillingSetupModuleCardState extends State<BillingSetupModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = BillingSetupDesignTokens.accentFor(widget.module.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _hovered ? 1.018 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onOpen,
            borderRadius: BorderRadius.circular(14),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: widget.height,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BillingSetupColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hovered
                      ? accent.withValues(alpha: 0.50)
                      : BillingSetupColors.cardBorder,
                  width: _hovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? accent.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: _hovered ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: _hovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      BillingSetupDesignTokens.iconFor(widget.module.id),
                      color: accent,
                      size: 23,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: GoogleFonts.manrope(
                      color: _hovered ? accent : BillingSetupColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                    child: Text(
                      widget.module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.module.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: BillingSetupColors.textMuted,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Tag(label: widget.module.tag, accent: accent),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        widget.module.actionLabel,
                        style: GoogleFonts.inter(
                          color: accent.withValues(alpha: _hovered ? 1 : 0.62),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: _hovered ? 0.16 : 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: accent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color accent;

  const _Tag({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: accent,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
