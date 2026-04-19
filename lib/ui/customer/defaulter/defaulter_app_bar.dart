// ==========================================
// FILE: defaulter_app_bar.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Dark shell header bar.
//              Matches POS app bar pattern:
//              [Back] [Green Dot + SYSTEM ONLINE] [DEFAULTER LIST] [Count Badge] [Refresh]
//              NO "Enterprise POS Terminal" text. NO login badge.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/customer/defaulter/defaulter_theme.dart';

class DefaulterAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final int defaulterCount;
  final bool isLoading;

  const DefaulterAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.defaulterCount,
    required this.isLoading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<DefaulterAppBar> createState() => _DefaulterAppBarState();
}

class _DefaulterAppBarState extends State<DefaulterAppBar>
    with SingleTickerProviderStateMixin {
  // Online dot pulse animation
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: DefaulterStyles.shellHeaderDecoration,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // ── BACK BUTTON ──────────────────────────
              _BackButton(onTap: widget.onBack),

              const SizedBox(width: 16),

              // ── ONLINE INDICATOR ─────────────────────
              _OnlineBadge(pulseAnim: _pulseAnim),

              const SizedBox(width: 16),

              // ── TITLE BLOCK ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DefaulterStrings.moduleTitle,
                      style: DefaulterStyles.shellModuleTitle,
                    ),
                    Text(
                      DefaulterStrings.moduleSubtitle,
                      style: DefaulterStyles.shellSubtitle,
                    ),
                  ],
                ),
              ),

              // ── COUNT BADGE ──────────────────────────
              if (widget.defaulterCount > 0)
                _CountBadge(count: widget.defaulterCount),

              const SizedBox(width: 12),

              // ── REFRESH BUTTON ───────────────────────
              _RefreshButton(
                onTap: widget.onRefresh,
                isLoading: widget.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: DefaulterColors.shellPanelBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DefaulterColors.shellBorder, width: 1),
        ),
        child: const Icon(
          DefaulterIcons.backArrow,
          color: DefaulterColors.shellTextTitle,
          size: 16,
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _OnlineBadge({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DefaulterColors.shellPanelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DefaulterColors.shellBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing green dot
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DefaulterColors.onlineGreen
                    .withOpacity(pulseAnim.value),
                boxShadow: [
                  BoxShadow(
                    color: DefaulterColors.onlinePulse,
                    blurRadius: 6 * pulseAnim.value,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          Text(
            DefaulterStrings.systemOnline,
            style: DefaulterStyles.onlineBadgeText,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey<int>(count),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: DefaulterColors.riskCriticalDot.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DefaulterColors.riskCriticalDot.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          '$count Accounts',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: DefaulterColors.riskCriticalDot,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _RefreshButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: DefaulterStrings.tooltipRefresh,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: DefaulterColors.shellPanelBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DefaulterColors.shellBorder, width: 1),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DefaulterColors.brandGold,
                    ),
                  )
                : const Icon(
                    DefaulterIcons.refreshData,
                    color: DefaulterColors.shellTextMuted,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}