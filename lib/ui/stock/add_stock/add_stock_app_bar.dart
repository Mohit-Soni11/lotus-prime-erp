import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/logic/stock/add_stock_controller.dart';
import '/theme/stock/add_stock/add_stock_theme.dart';
import 'stock_metal_ui.dart';

class AddStockAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onResetRequested;
  final AddStockController ctrl;

  const AddStockAppBar({
    super.key,
    required this.onBack,
    required this.onResetRequested,
    required this.ctrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(108);

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
            border: Border(
              bottom: BorderSide(color: AddStockColors.shellBorder, width: 1),
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
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _HoverActionButton(
                          icon: AddStockIcons.backArrow,
                          tooltip: 'Back',
                          onTap: widget.onBack,
                        ),
                        const SizedBox(width: 14),
                        _divider(),
                        const SizedBox(width: 14),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: ui.gradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(ui.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  _metalBadge(ui),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  _RadarWidget(blinkCtrl: _blinkCtrl),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${widget.ctrl.totalQuantity} pcs • ${widget.ctrl.totalGrossWeight.toStringAsFixed(3)}g gross • ${widget.ctrl.batchCode}',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AddStockColors.shellTextMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _divider(),
                        const SizedBox(width: 12),
                        _HoverActionButton(
                          icon: AddStockIcons.reset,
                          tooltip: AddStockStrings.btnResetBatch,
                          onTap: widget.onResetRequested,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AddStockColors.moduleBadgeBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AddStockColors.moduleBadgeBorder,
                            ),
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
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AddStockColors.shellBg,
                    border: Border(
                      top: BorderSide(
                        color: AddStockColors.shellBorder,
                        width: 0.5,
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
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ui.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: ui.accent.withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          widget.ctrl.rowsWithErrorsCount == 0
                              ? AddStockStrings.readyToSave
                              : '${widget.ctrl.rowsWithErrorsCount} ${AddStockStrings.rowsNeedAttention}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ui.accent,
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

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ui.accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ui.accent.withOpacity(0.3)),
      ),
      child: Text(
        ui.title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: ui.accent,
        ),
      ),
    );
  }
}

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
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : done
                    ? accentColor.withOpacity(0.5)
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
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
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
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: done
                ? [accentColor.withOpacity(0.6), accentColor.withOpacity(0.24)]
                : const [
                    AddStockColors.shellBorder,
                    AddStockColors.shellBorder,
                  ],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HoverActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HoverActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<_HoverActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hovered
                  ? AddStockColors.shellBg
                  : AddStockColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? AddStockColors.brandGold
                    : AddStockColors.shellBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered
                  ? AddStockColors.brandGold
                  : AddStockColors.shellTextTitle,
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
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: blinkCtrl,
            builder: (_, __) {
              final value = blinkCtrl.value;
              return Opacity(
                opacity: 1.0 - value,
                child: Transform.scale(
                  scale: 1.0 + (value * 1.5),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AddStockColors.onlineGreen.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
    );
  }
}
