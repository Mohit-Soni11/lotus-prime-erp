import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerMetalPurchaseCardHeader extends StatelessWidget {
  final String title;
  final String caption;
  final Color accent;
  final String assetPath;

  const CustomerMetalPurchaseCardHeader({
    super.key,
    required this.title,
    required this.caption,
    required this.accent,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetalAvatar(
          assetPath: assetPath,
          accent: accent,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerMetalPurchaseInfoPanel extends StatelessWidget {
  final String summary;
  final Color accent;
  final List<String> tags;

  const CustomerMetalPurchaseInfoPanel({
    super.key,
    required this.summary,
    required this.accent,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                CustomerMetalPurchaseBadge(label: tag, accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerMetalPurchaseCardFooter extends StatelessWidget {
  final String actionLabel;
  final Color accent;

  const CustomerMetalPurchaseCardFooter({
    super.key,
    required this.actionLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            actionLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
      ],
    );
  }
}

class CustomerMetalPurchaseBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const CustomerMetalPurchaseBadge({
    super.key,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _MetalAvatar extends StatelessWidget {
  final String assetPath;
  final Color accent;

  const _MetalAvatar({
    required this.assetPath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.34),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
