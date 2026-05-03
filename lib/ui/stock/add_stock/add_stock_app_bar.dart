// =============================================================================
// FILE        : add_stock_app_bar.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / AppBar
// DESCRIPTION : Dark-shell AppBar for Add Stock screen.
//               Matches Customer List / Karigar / Day Book pattern exactly:
//               ✅ Animated Hover Back Button (gold on hover)
//               ✅ Vertical Divider (gradient)
//               ✅ Gradient Module Icon + "ADD STOCK" Title
//               ✅ Radar Blink "SYSTEM ONLINE" status
//               ✅ Right: Refresh + "Stock & Inventory" badge
//               ✅ Step Indicator Row below (Metal → Purity → Items)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stock/add_stock_controller.dart';
import '../../../theme/stock/add_stock/add_stock_theme.dart';

// =============================================================================
// MAIN APP BAR
// =============================================================================

class AddStockAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final AddStockController ctrl;

  const AddStockAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
  });

  // AppBar height: 64 (main row) + 48 (step indicator row)
  @override
  Size get preferredSize => const Size.fromHeight(112.0);

  @override
  State<AddStockAppBar> createState() => _AddStockAppBarState();
}

class _AddStockAppBarState extends State<AddStockAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

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
          height: 112.0,
          decoration: const BoxDecoration(
            color: AddStockColors.shellPanelBg,
            border: Border(
              bottom: BorderSide(color: AddStockColors.shellBorder, width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Main Header Row ──────────────────────────────────────────
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // 1. Animated Back Button
                        _HoverBackButton(onTap: widget.onBack),
                        const SizedBox(width: 16),

                        // 2. Vertical Divider
                        _buildVerticalDivider(),
                        const SizedBox(width: 16),

                        // 3. Gradient Module Icon
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                AddStockColors.brandGold,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AddStockColors.brandGold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            AddStockIcons.inventory,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 4. Title + Radar
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AddStockStrings.screenTitle,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AddStockColors.shellTextTitle,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _RadarWidget(blinkCtrl: _blinkCtrl),
                          ],
                        ),

                        const Spacer(),

                        // 5. Right: Refresh + Module Badge
                        _buildVerticalDivider(),
                        const SizedBox(width: 12),
                        _HoverIconBtn(
                          icon: AddStockIcons.refresh,
                          tooltip: 'Refresh',
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AddStockColors.moduleBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AddStockColors.moduleBadgeBorder),
                          ),
                          child: Text(
                            AddStockStrings.moduleBadge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AddStockColors.moduleBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Step Indicator Row ───────────────────────────────────────
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AddStockColors.shellBg,
                    border: Border(
                      top: BorderSide(
                          color: AddStockColors.shellBorder, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _StepDot(
                        index: 0,
                        label: AddStockStrings.stepMetal,
                        currentStep: widget.ctrl.step,
                      ),
                      _StepLine(done: widget.ctrl.step.index > 0),
                      _StepDot(
                        index: 1,
                        label: AddStockStrings.stepPurity,
                        currentStep: widget.ctrl.step,
                      ),
                      _StepLine(done: widget.ctrl.step.index > 1),
                      _StepDot(
                        index: 2,
                        label: AddStockStrings.stepItems,
                        currentStep: widget.ctrl.step,
                      ),
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
      width: 1,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AddStockColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STEP DOT
// =============================================================================

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final AddStockStep currentStep;

  const _StepDot({
    required this.index,
    required this.label,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final done = index < currentStep.index;
    final active = index == currentStep.index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AddStockColors.brandGold
                : done
                    ? AddStockColors.brandGold.withOpacity(0.45)
                    : AddStockColors.shellBorder,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.black)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        active ? Colors.black : AddStockColors.shellTextMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? AddStockColors.brandGold
                : AddStockColors.shellTextMuted,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STEP LINE (connector between dots)
// =============================================================================

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: done
                ? [
                    AddStockColors.brandGold.withOpacity(0.6),
                    AddStockColors.brandGold.withOpacity(0.3),
                  ]
                : [
                    AddStockColors.shellBorder,
                    AddStockColors.shellBorder,
                  ],
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// =============================================================================
// ANIMATED HOVER BACK BUTTON (exact Customer List pattern)
// =============================================================================

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
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
                  ? AddStockColors.shellBg
                  : AddStockColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? AddStockColors.brandGold
                    : AddStockColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AddStockColors.brandGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              AddStockIcons.backArrow,
              color: _isHovered
                  ? AddStockColors.brandGold
                  : AddStockColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HOVER ICON BUTTON (for right-side actions)
// =============================================================================

class _HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HoverIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<_HoverIconBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AddStockColors.brandGoldLight
                  : AddStockColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? AddStockColors.brandGold
                    : AddStockColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? AddStockColors.brandGold
                  : AddStockColors.shellTextMuted,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// RADAR / SYSTEM ONLINE WIDGET (exact Customer List pattern)
// =============================================================================

class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  color: AddStockColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AddStockColors.onlineGreen,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AddStockColors.onlineGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AddStockColors.onlineGreen.withOpacity(0.25),
            ),
          ),
          child: Text(
            AddStockStrings.systemOnline,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AddStockColors.onlineGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
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
                  color: AddStockColors.onlineGreen.withOpacity(0.5),
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
