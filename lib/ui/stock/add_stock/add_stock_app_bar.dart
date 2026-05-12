import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/logic/stock/add_stock_controller.dart';
import '/theme/stock/add_stock/add_stock_theme.dart';
import 'stock_metal_ui.dart';

class AddStockAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final AddStockController ctrl;
  final bool showStepper;

  const AddStockAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
    this.showStepper = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(showStepper ? 114.0 : 70.0);

  @override
  State<AddStockAppBar> createState() => _AddStockAppBarState();
}

class _AddStockAppBarState extends State<AddStockAppBar>
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
        final ui = stockMetalUiFor(widget.ctrl.selectedMetal);
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AddStockColors.shellPanelBg,
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
                // ══════════════════════════════════════════════════════════════
                // TOP ROW: Premium Header
                // ══════════════════════════════════════════════════════════════
                Container(
                  height: 70.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HoverBackButton(onTap: widget.onBack),
                      const SizedBox(width: 18),
                      _buildVerticalDivider(),
                      const SizedBox(width: 18),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: ui.gradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: ui.accent.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Icon(ui.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AddStockStrings.screenTitle,
                            style: AddStockStyles.shellTitle.copyWith(
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _metalBadge(ui),
                        ],
                      ),
                      const Spacer(),
                      _RadarWidget(blinkCtrl: _blinkCtrl),
                    ],
                  ),
                ),

                // ══════════════════════════════════════════════════════════════
                // BOTTOM ROW: Clean Process Stepper (hidden when showStepper=false)
                // ══════════════════════════════════════════════════════════════
                if (widget.showStepper)
                  Container(
                    height: 44.0,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: const BoxDecoration(
                      color: AddStockColors.shellBg,
                      border: Border(
                        top: BorderSide(
                          color: AddStockColors.shellBorder,
                          width: 1.0,
                        ),
                        bottom: BorderSide(
                          color: AddStockColors.shellBorder,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _StepDot(
                          index: 0,
                          label: AddStockStrings.stepPurity,
                          currentStep: widget.ctrl.step,
                          accentColor: ui.accent,
                        ),
                        _StepLine(
                          done: widget.ctrl.step.index > 0,
                          accentColor: ui.accent,
                        ),
                        _StepDot(
                          index: 1,
                          label: AddStockStrings.stepItems,
                          currentStep: widget.ctrl.step,
                          accentColor: ui.accent,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.ctrl.rowsWithErrorsCount == 0
                                ? AddStockColors.success.withOpacity(0.12)
                                : AddStockColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.ctrl.rowsWithErrorsCount == 0
                                  ? AddStockColors.success.withOpacity(0.3)
                                  : AddStockColors.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.ctrl.rowsWithErrorsCount == 0
                                ? AddStockStrings.readyToSave
                                : '${widget.ctrl.rowsWithErrorsCount} ${AddStockStrings.rowsNeedAttention}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: widget.ctrl.rowsWithErrorsCount == 0
                                  ? AddStockColors.success
                                  : AddStockColors.danger,
                            ),
                          ),
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
      width: 1.5,
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

  Widget _metalBadge(StockMetalUiData ui) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ui.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ui.accent.withOpacity(0.4)),
      ),
      child: Text(
        ui.title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: ui.accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS FOR APP BARS
// ─────────────────────────────────────────────────────────────────────────────

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  void _updateHover(bool value) {
    if (_isHovered == value) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isHovered == value) {
        return;
      }
      setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
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

class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AddStockColors.onlineGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AddStockColors.onlineGreen.withOpacity(0.3),
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
          Text(
            AddStockStrings.systemOnline,
            style: GoogleFonts.inter(
              color: AddStockColors.onlineGreen,
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
                    : AddStockColors.shellBorder.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: active || done ? accentColor : AddStockColors.shellBorder,
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
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
                        ? AddStockColors.shellBg
                        : AddStockColors.shellTextMuted,
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
            color: active ? accentColor : AddStockColors.shellTextMuted,
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
          color:
              done ? accentColor : AddStockColors.shellBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 4,
                  )
                ]
              : [],
        ),
      ),
    );
  }
}
