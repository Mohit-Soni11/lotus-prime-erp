// =============================================================================
// FILE        : add_stock_app_bar.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / AppBar
// DESCRIPTION : Dark-shell AppBar for Add Stock screen.
//               ✅ v2: Metal step removed — 2-step indicator (Purity → Items)
//               ✅ v2: Metal badge shown next to title (metal identity visible)
//               ✅ Animated Hover Back Button (gold on hover)
//               ✅ Vertical Divider (gradient)
//               ✅ Gradient Module Icon + "ADD STOCK" Title
//               ✅ Radar Blink "SYSTEM ONLINE" status
//               ✅ Right: Refresh + "Stock & Inventory" badge
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stock/add_stock_controller.dart';
import '../../../models/stock/stock_enums/stock_enums.dart';
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

  // AppBar height: 64 (main row) + 44 (step indicator row)
  @override
  Size get preferredSize => const Size.fromHeight(108.0);

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

  // ✅ v2: Metal-specific accent colour for badge
  Color get _metalAccent {
    switch (widget.ctrl.selectedMetal) {
      case StockCategory.gold:
        return const Color(0xFFD4AF37);
      case StockCategory.silver:
        return const Color(0xFF78909C);
      case StockCategory.diamond:
        return const Color(0xFF29B6F6);
      case StockCategory.platinum:
        return const Color(0xFF607D8B);
      default:
        return AddStockColors.brandGold;
    }
  }

  IconData get _metalIcon {
    switch (widget.ctrl.selectedMetal) {
      case StockCategory.gold:
        return Icons.diamond_rounded;
      case StockCategory.silver:
        return Icons.toll_rounded;
      case StockCategory.diamond:
        return Icons.hexagon_outlined;
      case StockCategory.platinum:
        return Icons.radio_button_checked_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          height: 108.0,
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
                // ── Main Header Row ────────────────────────────────────────
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

                        // 3. Metal Icon (changes per metal) ✅ v2
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _metalAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _metalAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _metalIcon,
                            color: _metalAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 4. Title + Metal badge + Radar
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + metal badge on same line
                              Row(
                                children: [
                                  Text(
                                    AddStockStrings.screenTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AddStockColors.shellTextTitle,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✅ v2: Metal badge — shows selected metal
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _metalAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: _metalAccent.withOpacity(0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.ctrl.selectedMetal.label
                                          .toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: _metalAccent,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              _RadarWidget(blinkCtrl: _blinkCtrl),
                            ],
                          ),
                        ),

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

                // ── Step Indicator Row (2 steps: Purity → Items) ✅ v2 ────
                Container(
                  height: 44,
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
                        label: AddStockStrings.stepPurity,
                        currentStep: widget.ctrl.step,
                        accentColor: _metalAccent,
                      ),
                      _StepLine(
                          done: widget.ctrl.step.index > 0,
                          accentColor: _metalAccent),
                      _StepDot(
                        index: 1,
                        label: AddStockStrings.stepItems,
                        currentStep: widget.ctrl.step,
                        accentColor: _metalAccent,
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
// STEP DOT  (✅ v2: uses metal accent colour)
// =============================================================================

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
          duration: const Duration(milliseconds: 250),
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : done
                    ? accentColor.withOpacity(0.45)
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
            color: active ? accentColor : AddStockColors.shellTextMuted,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STEP LINE  (✅ v2: uses metal accent colour)
// =============================================================================

class _StepLine extends StatelessWidget {
  final bool done;
  final Color accentColor;
  const _StepLine({required this.done, required this.accentColor});

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
                    accentColor.withOpacity(0.6),
                    accentColor.withOpacity(0.3),
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
// ANIMATED HOVER BACK BUTTON  (unchanged)
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
// HOVER ICON BUTTON  (unchanged)
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
// RADAR / SYSTEM ONLINE WIDGET  (unchanged)
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
