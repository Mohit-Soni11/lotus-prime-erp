// =============================================================================
// FILE        : silver_app_bar.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Components
// DESCRIPTION : Premium App Bar for Silver Stock module.
//               ✅ 100% Isolated Silver Theme — zero Gold dependency.
//               ✅ Silver image logo (chaandi ka actual photo).
//               ✅ Hover back button with silver glow.
//               ✅ 2-step Purity → Items stepper.
//               ✅ SYSTEM ONLINE green dot radar widget.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/logic/stock/add_stock_controller.dart';
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final AddStockController ctrl;

  const SilverAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(114.0); // 70 + 44 stepper

  @override
  State<SilverAppBar> createState() => _SilverAppBarState();
}

class _SilverAppBarState extends State<SilverAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: SilverStockColors.shellPanelBg,
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // ══════════════════════════════════════════════
                // TOP ROW: Back | Divider | Logo | Title | System Online
                // ══════════════════════════════════════════════
                Container(
                  height: 70.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _SilverBackButton(onTap: widget.onBack),
                      const SizedBox(width: 18),
                      _buildVerticalDivider(),
                      const SizedBox(width: 18),

                      // ✅ Silver image logo — icon box hata diya
                      _SilverLogoOrb(size: 34),
                      const SizedBox(width: 14),

                      // ── Title + SILVER badge ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            SilverStockStrings.screenTitle,
                            style: SilverStockStyles.shellTitle.copyWith(
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _silverMetalBadge(),
                        ],
                      ),
                      const Spacer(),

                      // ✅ SYSTEM ONLINE only — coin badge hata diya
                      _SystemOnlineWidget(blinkCtrl: _blinkCtrl),
                    ],
                  ),
                ),

                // ══════════════════════════════════════════════
                // BOTTOM ROW: Purity → Items Stepper
                // ══════════════════════════════════════════════
                Container(
                  height: 44.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: const BoxDecoration(
                    color: SilverStockColors.shellBg,
                    border: Border(
                      top: BorderSide(
                        color: SilverStockColors.shellBorder,
                        width: 1.0,
                      ),
                      bottom: BorderSide(
                        color: SilverStockColors.shellBorder,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _StepDot(
                        index: 0,
                        label: SilverStockStrings.stepPurity,
                        currentStep: widget.ctrl.step,
                        accentColor: SilverStockColors.brandSilver,
                      ),
                      _StepLine(
                        done: widget.ctrl.step.index > 0,
                        accentColor: SilverStockColors.brandSilver,
                      ),
                      _StepDot(
                        index: 1,
                        label: SilverStockStrings.stepItems,
                        currentStep: widget.ctrl.step,
                        accentColor: SilverStockColors.brandSilver,
                      ),
                      const Spacer(),
                      _buildStatusChip(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            SilverStockColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _silverMetalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SilverStockColors.brandSilver.withOpacity(0.4),
        ),
      ),
      child: Text(
        'SILVER',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: SilverStockColors.brandSilver,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final hasErrors = widget.ctrl.rowsWithErrorsCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasErrors
            ? SilverStockColors.danger.withOpacity(0.12)
            : SilverStockColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasErrors
              ? SilverStockColors.danger.withOpacity(0.3)
              : SilverStockColors.success.withOpacity(0.3),
        ),
      ),
      child: Text(
        hasErrors
            ? '${widget.ctrl.rowsWithErrorsCount} ${SilverStockStrings.rowsNeedAttention}'
            : SilverStockStrings.readyToSave,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color:
              hasErrors ? SilverStockColors.danger : SilverStockColors.success,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ SILVER IMAGE LOGO — actual chaandi photo, rounded corners with glow
// ─────────────────────────────────────────────────────────────────────────────

class _SilverLogoOrb extends StatelessWidget {
  final double size;
  const _SilverLogoOrb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: SilverStockColors.brandSilver.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'lib/logo/silver and platinum .jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM ONLINE — Blinking green dot radar widget
// ─────────────────────────────────────────────────────────────────────────────

class _SystemOnlineWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _SystemOnlineWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SilverStockColors.onlineGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: SilverStockColors.onlineGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildWave(blinkCtrl, 0.0),
                _buildWave(blinkCtrl, 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SilverStockColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SilverStockColors.onlineGreen,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            SilverStockStrings.systemOnline,
            style: GoogleFonts.inter(
              color: SilverStockColors.onlineGreen,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWave(AnimationController ctrl, double delay) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final val = (ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + (val * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SilverStockColors.onlineGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOVER BACK BUTTON — Silver glow on hover
// ─────────────────────────────────────────────────────────────────────────────

class _SilverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SilverBackButton({required this.onTap});

  @override
  State<_SilverBackButton> createState() => _SilverBackButtonState();
}

class _SilverBackButtonState extends State<_SilverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? SilverStockColors.shellBg
                  : SilverStockColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? SilverStockColors.brandSilver
                    : SilverStockColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: SilverStockColors.brandSilver.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              SilverStockIcons.backArrow,
              color: _isHovered
                  ? SilverStockColors.brandSilver
                  : SilverStockColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEPPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final AddStockStep currentStep;
  final Color accentColor;

  const _StepDot({
    required this.index,
    required this.label,
    required this.currentStep,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final done = index < currentStep.index;
    final active = index == currentStep.index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : done
                    ? accentColor.withOpacity(0.2)
                    : SilverStockColors.shellBorder.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  active || done ? accentColor : SilverStockColors.shellBorder,
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 14, color: accentColor)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? SilverStockColors.shellBg
                        : SilverStockColors.shellTextMuted,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
            color: active ? accentColor : SilverStockColors.shellTextMuted,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  final Color accentColor;

  const _StepLine({required this.done, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        height: 2.0,
        decoration: BoxDecoration(
          color: done
              ? accentColor
              : SilverStockColors.shellBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
