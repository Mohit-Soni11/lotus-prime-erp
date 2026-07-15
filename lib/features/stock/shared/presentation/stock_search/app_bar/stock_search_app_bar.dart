part of '../stock_search_screen.dart';

class _StockSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _StockSearchAppBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_StockSearchAppBar> createState() => _StockSearchAppBarState();
}

class _StockSearchAppBarState extends State<_StockSearchAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder, width: 1),
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
            _ShellIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            const _AppBarDivider(),
            const SizedBox(width: 18),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD76A), InvColors.brandGold],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: InvColors.brandGold.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'STOCK SEARCH CENTER',
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _ShellIconButton(
              icon: Icons.refresh_rounded,
              onTap: widget.onRefresh,
            ),
            const SizedBox(width: 14),
            _OnlineBadge(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}
