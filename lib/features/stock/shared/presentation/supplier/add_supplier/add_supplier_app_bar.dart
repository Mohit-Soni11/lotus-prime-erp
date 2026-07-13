import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/add_supplier_logic.dart';
import 'package:lotus_erp/theme/stock/supplier/add_supplier/add_supplier_theme.dart';

class AddSupplierAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final AddSupplierLogic logic;

  const AddSupplierAppBar({
    super.key,
    required this.onBack,
    required this.logic,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(AddSupplierStyles.appBarHeight);

  @override
  State<AddSupplierAppBar> createState() => _AddSupplierAppBarState();
}

class _AddSupplierAppBarState extends State<AddSupplierAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AddSupplierStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AddSupplierColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: AddSupplierColors.shellBorder, width: 1),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            _buildVerticalDivider(),
            const SizedBox(width: 18),
            _buildModuleIcon(),
            const SizedBox(width: 14),
            ListenableBuilder(
              listenable: widget.logic,
              builder: (context, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AddSupplierStrings.appBarSubtitle,
                    style: AddSupplierStyles.appBarSubtitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.logic.isEditMode
                        ? AddSupplierStrings.appBarTitleEdit
                        : AddSupplierStrings.appBarTitleAdd,
                    style: AddSupplierStyles.appBarTitle,
                  ),
                ],
              ),
            ),
            const Spacer(),
            _RadarWidget(pulseCtrl: _pulseCtrl),
          ],
        ),
      ),
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
            AddSupplierColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildModuleIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AddSupplierColors.goldGradientStart,
            AddSupplierColors.brandGold,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AddSupplierColors.brandGold.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        AddSupplierIcons.moduleIcon,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

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
            duration: const Duration(milliseconds: 250),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AddSupplierColors.shellBg
                  : AddSupplierColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? AddSupplierColors.brandGold
                    : AddSupplierColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AddSupplierColors.brandGold.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              AddSupplierIcons.backArrow,
              color: _isHovered
                  ? AddSupplierColors.brandGold
                  : AddSupplierColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarWidget extends StatelessWidget {
  final AnimationController pulseCtrl;

  const _RadarWidget({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AddSupplierColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AddSupplierColors.onlineGreen.withValues(alpha: 0.3),
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
                _buildWave(0.0),
                _buildWave(0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AddSupplierColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AddSupplierColors.onlineGreen,
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
          const Text(
            AddSupplierStrings.systemOnline,
            style: AddSupplierStyles.systemOnlineText,
          ),
        ],
      ),
    );
  }

  Widget _buildWave(double delay) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final value = (pulseCtrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - value,
          child: Transform.scale(
            scale: 1.0 + (value * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AddSupplierColors.onlineGreen.withValues(alpha: 0.5),
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
