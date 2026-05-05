import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class AddStockHubAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const AddStockHubAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  State<AddStockHubAppBar> createState() => _AddStockHubAppBarState();
}

class _AddStockHubAppBarState extends State<AddStockHubAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  bool _backHovered = false;

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
    return Container(
      height: widget.preferredSize.height,
      decoration: const BoxDecoration(
        color: AddStockColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: AddStockColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _backHovered = true),
                onExit: (_) => setState(() => _backHovered = false),
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _backHovered
                          ? AddStockColors.shellBg
                          : AddStockColors.shellBorder.withOpacity(0.32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _backHovered
                            ? AddStockColors.brandGold
                            : AddStockColors.shellBorder,
                        width: _backHovered ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: _backHovered
                          ? AddStockColors.brandGold
                          : AddStockColors.shellTextTitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 28,
                color: AddStockColors.shellBorder,
              ),
              const SizedBox(width: 16),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD76A), AddStockColors.brandGold],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AddStockColors.brandGold.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADD STOCK DESK',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AddStockColors.shellTextTitle,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _HubRadar(blinkCtrl: _blinkCtrl),
                        const SizedBox(width: 8),
                        Text(
                          'Choose a metal workspace to continue',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AddStockColors.shellTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AddStockColors.moduleBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AddStockColors.moduleBadgeBorder),
                ),
                child: Text(
                  'STOCK & INVENTORY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AddStockColors.moduleBadgeText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubRadar extends StatelessWidget {
  final AnimationController blinkCtrl;

  const _HubRadar({required this.blinkCtrl});

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
