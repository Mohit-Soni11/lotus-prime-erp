import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryMetalSummaryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String primaryValue;
  final String weightLabel;
  final String weightValue;
  final String actionLabel;
  final IconData icon;
  final String? logoAsset;
  final Color accent;
  final Color surface;
  final Color tint;
  final LinearGradient gradient;
  final Color textOnGradient;
  final bool selected;
  final VoidCallback onTap;

  const InventoryMetalSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryValue,
    required this.weightLabel,
    required this.weightValue,
    required this.actionLabel,
    required this.icon,
    required this.logoAsset,
    required this.accent,
    required this.surface,
    required this.tint,
    required this.gradient,
    required this.textOnGradient,
    required this.selected,
    required this.onTap,
  });

  @override
  State<InventoryMetalSummaryCard> createState() =>
      _InventoryMetalSummaryCardState();
}

class _InventoryMetalSummaryCardState extends State<InventoryMetalSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected || _hovered
        ? widget.accent.withValues(alpha: 0.55)
        : widget.accent.withValues(alpha: 0.22);
    final shadowOpacity = widget.selected || _hovered ? 0.18 : 0.10;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: widget.accent.withValues(alpha: 0.08),
            highlightColor: widget.accent.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: widget.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: shadowOpacity),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
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
                            gradient: widget.gradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accent.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.logoAsset == null
                              ? Icon(
                                  widget.icon,
                                  color: widget.textOnGradient,
                                  size: 28,
                                )
                              : Image.asset(
                                  widget.logoAsset!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    widget.icon,
                                    color: widget.textOnGradient,
                                    size: 28,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF374151),
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
                            label: widget.primaryLabel,
                            value: widget.primaryValue,
                            accent: widget.accent,
                            tint: widget.tint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: widget.weightLabel,
                            value: widget.weightValue,
                            accent: widget.accent,
                            tint: widget.tint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.accent
                            : widget.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.actionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: widget.selected
                                  ? Colors.white
                                  : widget.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color:
                                widget.selected ? Colors.white : widget.accent,
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
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color tint;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.42),
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
              color: const Color(0xFF374151),
              letterSpacing: 0.45,
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
                color: const Color(0xFF111827),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
