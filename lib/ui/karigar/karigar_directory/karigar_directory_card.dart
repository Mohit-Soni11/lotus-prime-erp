// =============================================================================
// FILE        : karigar_directory_card.dart
// MODULE      : Karigar → Karigar Directory
// LAYER       : UI / Widget
// DESCRIPTION : Individual karigar card for the directory list.
//               Shows avatar, name, specialization, phone, city,
//               active jobs count, outstanding balance, and status badge.
//               Hover effect with gold border glow (same as CustomerListCard).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/karigar/karigar_directory/karigar_directory_ui_model.dart';
import '../../../theme/karigar/karigar_directory/karigar_directory_theme.dart';

class KarigarDirectoryCard extends StatefulWidget {
  final KarigarDirectoryItemModel karigar;
  final VoidCallback?             onTap;
  final VoidCallback?             onToggleStatus;

  const KarigarDirectoryCard({
    super.key,
    required this.karigar,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  State<KarigarDirectoryCard> createState() => _KarigarDirectoryCardState();
}

class _KarigarDirectoryCardState extends State<KarigarDirectoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final k = widget.karigar;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _isHovered
              ? KarigarDirectoryStyles.cardDecorationHover
              : KarigarDirectoryStyles.cardDecoration,
          child: Padding(
            padding: KarigarDirectoryStyles.cardPadding,
            child: Row(children: [
              // ── AVATAR ──────────────────────────────────────────────────
              _buildAvatar(k),
              const SizedBox(width: 16),

              // ── MAIN INFO ───────────────────────────────────────────────
              Expanded(child: _buildMainInfo(k)),
              const SizedBox(width: 12),

              // ── JOB + BALANCE BOX ────────────────────────────────────────
              _buildStatsBox(k),
              const SizedBox(width: 12),

              // ── MORE OPTIONS + ARROW ─────────────────────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showOptions(context, k),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        KarigarDirectoryIcons.moreOptions,
                        color: KarigarDirectoryColors.textHint,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      KarigarDirectoryIcons.arrowRight,
                      color: KarigarDirectoryColors.brandGold,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(KarigarDirectoryItemModel k) {
    return Stack(children: [
      Container(
        width: KarigarDirectoryStyles.avatarSize,
        height: KarigarDirectoryStyles.avatarSize,
        decoration: BoxDecoration(
          color: k.isActive
              ? KarigarDirectoryColors.brandGoldLight
              : KarigarDirectoryColors.inactiveBadgeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: k.isActive
                ? KarigarDirectoryColors.brandGold.withOpacity(0.35)
                : KarigarDirectoryColors.textHint.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          k.initials,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: k.isActive
                ? KarigarDirectoryColors.brandGold
                : KarigarDirectoryColors.textMuted,
          ),
        ),
      ),
      // Overdue dot
      if (k.hasOverdueJobs)
        Positioned(
          top: -2, right: -2,
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: KarigarDirectoryColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
    ]);
  }

  Widget _buildMainInfo(KarigarDirectoryItemModel k) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name + status badge
      Row(children: [
        Flexible(
          child: Text(
            k.name,
            style: KarigarDirectoryStyles.karigarName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(k.isActive),
      ]),
      const SizedBox(height: 5),

      // Specialization chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: KarigarDirectoryColors.brandGoldLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: KarigarDirectoryColors.brandGold.withOpacity(0.3)),
        ),
        child: Text(
          k.specialization,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: KarigarDirectoryColors.brandGold,
          ),
        ),
      ),
      const SizedBox(height: 6),

      // Phone
      Row(children: [
        const Icon(KarigarDirectoryIcons.phone,
            size: 13, color: KarigarDirectoryColors.textMuted),
        const SizedBox(width: 5),
        Text(k.phone, style: KarigarDirectoryStyles.karigarPhone),
      ]),
      const SizedBox(height: 4),

      // City + Rate
      Row(children: [
        const Icon(KarigarDirectoryIcons.city,
            size: 12, color: KarigarDirectoryColors.textMuted),
        const SizedBox(width: 4),
        Text(
          k.city ?? KarigarDirectoryStrings.noCity,
          style: KarigarDirectoryStyles.karigarDetail,
        ),
        const SizedBox(width: 12),
        const Icon(KarigarDirectoryIcons.rate,
            size: 12, color: KarigarDirectoryColors.textMuted),
        const SizedBox(width: 4),
        Text(k.rateDisplay, style: KarigarDirectoryStyles.karigarDetail),
        const SizedBox(width: 12),
        const Icon(KarigarDirectoryIcons.calendar,
            size: 12, color: KarigarDirectoryColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '${KarigarDirectoryStrings.memberSince} ${k.memberSince}',
          style: KarigarDirectoryStyles.karigarSince,
        ),
      ]),
    ]);
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? KarigarDirectoryColors.activeBadgeBg
            : KarigarDirectoryColors.inactiveBadgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? KarigarDirectoryColors.activeBadgeBorder
              : KarigarDirectoryColors.textHint.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        isActive
            ? KarigarDirectoryStrings.statusActive
            : KarigarDirectoryStrings.statusInactive,
        style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: isActive
              ? KarigarDirectoryColors.success
              : KarigarDirectoryColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatsBox(KarigarDirectoryItemModel k) {
    final rupee = NumberFormat('₹##,##,##0', 'en_IN');
    return Column(children: [
      // Active jobs
      Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: k.hasActiveJobs
              ? KarigarDirectoryColors.infoBg
              : KarigarDirectoryColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: k.hasActiveJobs
                ? KarigarDirectoryColors.info.withOpacity(0.3)
                : KarigarDirectoryColors.cardBorder,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            KarigarDirectoryIcons.jobs,
            size: 14,
            color: k.hasActiveJobs
                ? KarigarDirectoryColors.info
                : KarigarDirectoryColors.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            k.activeJobCount.toString(),
            style: GoogleFonts.manrope(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: k.hasActiveJobs
                  ? KarigarDirectoryColors.info
                  : KarigarDirectoryColors.textMuted,
            ),
          ),
          Text(
            'JOBS',
            style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: KarigarDirectoryColors.textMuted,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),

      // Outstanding
      Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: k.hasOutstanding
              ? KarigarDirectoryColors.warningBg
              : KarigarDirectoryColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: k.hasOutstanding
                ? KarigarDirectoryColors.warning.withOpacity(0.3)
                : KarigarDirectoryColors.cardBorder,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            KarigarDirectoryIcons.balance,
            size: 14,
            color: k.hasOutstanding
                ? KarigarDirectoryColors.warning
                : KarigarDirectoryColors.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            k.outstandingBalance > 9999
                ? '${(k.outstandingBalance / 1000).toStringAsFixed(0)}K'
                : k.outstandingBalance.toStringAsFixed(0),
            style: GoogleFonts.manrope(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: k.hasOutstanding
                  ? KarigarDirectoryColors.warning
                  : KarigarDirectoryColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'DUE ₹',
            style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: KarigarDirectoryColors.textMuted,
            ),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _showOptions(
      BuildContext context, KarigarDirectoryItemModel k) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: k.isActive
                    ? KarigarDirectoryColors.dangerBg
                    : KarigarDirectoryColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                k.isActive
                    ? KarigarDirectoryIcons.deactivate
                    : KarigarDirectoryIcons.activate,
                color: k.isActive
                    ? KarigarDirectoryColors.danger
                    : KarigarDirectoryColors.success,
                size: 20,
              ),
            ),
            title: Text(
              k.isActive
                  ? KarigarDirectoryStrings.btnDeactivate
                  : KarigarDirectoryStrings.btnActivate,
              style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: k.isActive
                    ? KarigarDirectoryColors.danger
                    : KarigarDirectoryColors.success,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onToggleStatus?.call();
            },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
