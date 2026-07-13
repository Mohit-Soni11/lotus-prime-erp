import 'package:flutter/material.dart';

import 'package:lotus_erp/theme/stock/supplier/supplier_profile/supplier_profile_theme.dart';

class SupplierProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String supplierName;

  const SupplierProfileAppBar({
    super.key,
    required this.onBack,
    required this.supplierName,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(SupplierProfileStyles.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SupplierProfileStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: SupplierProfileColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(
            color: SupplierProfileColors.shellBorder,
            width: 1,
          ),
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
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 18),
            _buildDivider(),
            const SizedBox(width: 18),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SupplierProfileColors.brandGoldStart,
                    SupplierProfileColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:
                        SupplierProfileColors.brandGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                SupplierProfileIcons.moduleIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SupplierProfileStrings.appBarSubtitle,
                  style: SupplierProfileStyles.appBarSubtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  SupplierProfileStrings.appBarTitle,
                  style: SupplierProfileStyles.appBarTitle,
                ),
                const SizedBox(height: 5),
                const _RadarWidget(),
              ],
            ),
            const Spacer(),
            _buildBadge(supplierName),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1.5,
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              SupplierProfileColors.shellBorder,
              Colors.transparent,
            ],
          ),
        ),
      );

  Widget _buildBadge(String name) {
    final label = name.length > 18 ? '${name.substring(0, 16)}...' : name;
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SupplierProfileColors.shellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SupplierProfileColors.brandGold.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: SupplierProfileColors.brandGold.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            SupplierProfileIcons.business,
            color: SupplierProfileColors.brandGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SupplierProfileColors.brandGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const Text(
                  SupplierProfileStrings.moduleStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SupplierProfileColors.shellTextMuted,
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? SupplierProfileColors.shellBg
                  : SupplierProfileColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? SupplierProfileColors.brandGold
                    : SupplierProfileColors.shellBorder,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: SupplierProfileColors.brandGold
                            .withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              SupplierProfileIcons.backArrow,
              color: _hovered
                  ? SupplierProfileColors.brandGold
                  : SupplierProfileColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarWidget extends StatefulWidget {
  const _RadarWidget();

  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _wave(0),
              _wave(0.5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SupplierProfileColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SupplierProfileColors.onlineGreen,
                      blurRadius: 6,
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
            color: SupplierProfileColors.onlineGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SupplierProfileColors.onlineGreen.withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            SupplierProfileStrings.systemOnline,
            style: SupplierProfileStyles.systemOnlineText,
          ),
        ),
      ],
    );
  }

  Widget _wave(double delay) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final value = (_controller.value + delay) % 1.0;
          return Opacity(
            opacity: 1.0 - value,
            child: Transform.scale(
              scale: 1.0 + value * 1.5,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SupplierProfileColors.onlineGreen
                        .withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
