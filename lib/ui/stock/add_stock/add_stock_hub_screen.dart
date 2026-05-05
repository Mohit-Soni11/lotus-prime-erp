import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_screen.dart';
import 'add_stock_hub_app_bar.dart';
import 'diamond_stock_card.dart';
import 'gold_stock_card.dart';
import 'platinum_stock_card.dart';
import 'silver_stock_card.dart';

class AddStockHubScreen extends StatefulWidget {
  const AddStockHubScreen({super.key});

  @override
  State<AddStockHubScreen> createState() => _AddStockHubScreenState();
}

class _AddStockHubScreenState extends State<AddStockHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final AnimationController _cardsAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _cardsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _cardsAnim.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _cardsAnim.dispose();
    super.dispose();
  }

  void _navigate(StockCategory metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AddStockScreen(metal: metal),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AddStockColors.bodyBg,
      appBar: AddStockHubAppBar(onBack: () => Navigator.maybePop(context)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 960
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _headerAnim,
                    child: _HubHero(width: constraints.maxWidth),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: GoldStockCard(
                          animationController: _cardsAnim,
                          delay: 0.00,
                          onTap: () => _navigate(StockCategory.gold),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SilverStockCard(
                          animationController: _cardsAnim,
                          delay: 0.10,
                          onTap: () => _navigate(StockCategory.silver),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: DiamondStockCard(
                          animationController: _cardsAnim,
                          delay: 0.20,
                          onTap: () => _navigate(StockCategory.diamond),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: PlatinumStockCard(
                          animationController: _cardsAnim,
                          delay: 0.30,
                          onTap: () => _navigate(StockCategory.platinum),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _cardsAnim,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AddStockColors.brandGoldBorder,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AddStockColors.shadowLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AddStockColors.brandGoldLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.design_services_rounded,
                              color: AddStockColors.brandGold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Har metal card ko alag file aur alag UI ke saath maintain karna easy rahega. Yahan se jo workspace choose karoge, usi metal ke liye purity presets aur batch form open hoga.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.55,
                                color: AddStockColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HubHero extends StatelessWidget {
  final double width;

  const _HubHero({required this.width});

  @override
  Widget build(BuildContext context) {
    final isWide = width >= 920;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101827), Color(0xFF1F2937)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _leftCopy()),
                const SizedBox(width: 18),
                SizedBox(width: 320, child: _rightPanel()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leftCopy(),
                const SizedBox(height: 18),
                _rightPanel(),
              ],
            ),
    );
  }

  Widget _leftCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'METAL WORKSPACES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFFE7C86A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Choose the inventory lane you want to open.',
          style: GoogleFonts.manrope(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Har metal ke liye alag UI aur focused workflow rahega. Isse future mein Gold, Silver, Diamond, aur Platinum ka design independently evolve kar paoge.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.6,
            color: const Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroChip(label: 'Supplier-linked batch'),
            _HeroChip(label: 'Purity presets'),
            _HeroChip(label: 'Multi-item save'),
          ],
        ),
      ],
    );
  }

  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _HeroHeading(),
          SizedBox(height: 12),
          _HeroPoint(
            title: 'Independent card design',
            body:
                'Har metal card ka layout alag file mein rahega, isliye copy-paste style sameness khatam hogi.',
          ),
          SizedBox(height: 10),
          _HeroPoint(
            title: 'Cleaner screen files',
            body:
                'Hub aur form dono lean orchestrator files ban jayenge, heavy widget code separate modules mein chala jayega.',
          ),
          SizedBox(height: 10),
          _HeroPoint(
            title: 'Safer future edits',
            body:
                'Agar kal Diamond ka premium UI change karna ho, to Gold ya Silver flow touch nahi hoga.',
          ),
        ],
      ),
    );
  }
}

class _HeroHeading extends StatelessWidget {
  const _HeroHeading();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Why this split helps',
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF9FAFB),
        ),
      ),
    );
  }
}

class _HeroPoint extends StatelessWidget {
  final String title;
  final String body;

  const _HeroPoint({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AddStockColors.brandGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title\n',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: body,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.5,
                    color: const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
