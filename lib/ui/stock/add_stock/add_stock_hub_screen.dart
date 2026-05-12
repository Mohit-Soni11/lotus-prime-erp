import 'package:flutter/material.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_screen.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_stock_screen.dart';
import 'add_stock_hub_app_bar.dart';
import 'diamond_stock_card.dart';
import 'gold_stock_card.dart';
import 'platinum_stock_card.dart';
import '../add_stock/add_stock_silver/silver_stock_card.dart';

class AddStockHubScreen extends StatefulWidget {
  const AddStockHubScreen({super.key});

  @override
  State<AddStockHubScreen> createState() => _AddStockHubScreenState();
}

class _AddStockHubScreenState extends State<AddStockHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cardsAnim;

  @override
  void initState() {
    super.initState();
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
    _cardsAnim.dispose();
    super.dispose();
  }

  void _navigate(StockCategory metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => metal == StockCategory.silver
            ? const SilverStockScreen()
            : AddStockScreen(metal: metal),
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
