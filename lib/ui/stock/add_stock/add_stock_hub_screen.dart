// =============================================================================
// FILE        : add_stock_hub_screen.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / Hub Screen
// DESCRIPTION : Metal selection hub — 4 animated cards (Gold, Silver,
//               Platinum, Diamond). User picks metal here, then goes
//               directly to Purity → Items wizard (Step 1 removed).
//
// CHANGELOG:
//   v1 — Initial hub screen (replaces Step 1 Metal Selection from wizard)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/stock/stock_enums/stock_enums.dart';
import '../../../theme/stock/add_stock/add_stock_theme.dart';
import 'add_stock_screen.dart';

// =============================================================================
// HUB SCREEN
// =============================================================================

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

    // Stagger: cards appear after header
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardsAnim.forward();
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
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
              )),
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
      appBar: _HubAppBar(onBack: () => Navigator.maybePop(context)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section Label ─────────────────────────────────────────────
              FadeTransition(
                opacity: _headerAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'METAL TYPE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AddStockColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stock kaun se metal mein add karna hai?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AddStockColors.textBody,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Metal Cards Grid ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _AnimatedMetalCard(
                      animController: _cardsAnim,
                      delay: 0.0,
                      config: _MetalCardConfig.gold,
                      onTap: () => _navigate(StockCategory.gold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnimatedMetalCard(
                      animController: _cardsAnim,
                      delay: 0.12,
                      config: _MetalCardConfig.silver,
                      onTap: () => _navigate(StockCategory.silver),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AnimatedMetalCard(
                      animController: _cardsAnim,
                      delay: 0.24,
                      config: _MetalCardConfig.diamond,
                      onTap: () => _navigate(StockCategory.diamond),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnimatedMetalCard(
                      animController: _cardsAnim,
                      delay: 0.36,
                      config: _MetalCardConfig.platinum,
                      onTap: () => _navigate(StockCategory.platinum),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Info note ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _cardsAnim,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AddStockColors.brandGoldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AddStockColors.brandGoldBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AddStockColors.brandGold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Metal choose karne ke baad purity aur items enter kar sakte ho.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AddStockColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

// =============================================================================
// METAL CARD CONFIG — Each metal ka visual identity
// =============================================================================

class _MetalCardConfig {
  final String key;
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final Color cardBg;
  final Color tagColor;

  const _MetalCardConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.cardBg,
    required this.tagColor,
  });

  // ── GOLD ──────────────────────────────────────────────────────────────────
  static const gold = _MetalCardConfig(
    key: 'Gold',
    title: 'Gold',
    subtitle: 'Sona',
    tag: '22K · 18K · 24K',
    icon: Icons.diamond_rounded, // ring / jewel look
    accent: Color(0xFFD4AF37),
    accentLight: Color(0xFFFFF8E1),
    cardBg: Color(0xFFFFFDF5),
    tagColor: Color(0xFFB8860B),
  );

  // ── SILVER ────────────────────────────────────────────────────────────────
  static const silver = _MetalCardConfig(
    key: 'Silver',
    title: 'Silver',
    subtitle: 'Chaandi',
    tag: '999 · 925 · 800',
    icon: Icons.toll_rounded, // coin/bangle look
    accent: Color(0xFF78909C),
    accentLight: Color(0xFFF0F4F7),
    cardBg: Color(0xFFF5F7F9),
    tagColor: Color(0xFF546E7A),
  );

  // ── DIAMOND ───────────────────────────────────────────────────────────────
  static const diamond = _MetalCardConfig(
    key: 'Diamond',
    title: 'Diamond',
    subtitle: 'Heera',
    tag: 'Solitaire · Studded',
    icon: Icons.diamond_outlined, // gem look
    accent: Color(0xFF29B6F6),
    accentLight: Color(0xFFE1F5FE),
    cardBg: Color(0xFFF2FBFF),
    tagColor: Color(0xFF0288D1),
  );

  // ── PLATINUM ──────────────────────────────────────────────────────────────
  static const platinum = _MetalCardConfig(
    key: 'Platinum',
    title: 'Platinum',
    subtitle: 'Pletenium',
    tag: '950 · 900 · 850',
    icon: Icons.radio_button_checked_rounded, // band/ring look
    accent: Color(0xFF607D8B),
    accentLight: Color(0xFFECEFF1),
    cardBg: Color(0xFFF4F5F6),
    tagColor: Color(0xFF455A64),
  );
}

// =============================================================================
// ANIMATED METAL CARD
// =============================================================================

class _AnimatedMetalCard extends StatefulWidget {
  final AnimationController animController;
  final double delay; // 0.0 – 0.5
  final _MetalCardConfig config;
  final VoidCallback onTap;

  const _AnimatedMetalCard({
    required this.animController,
    required this.delay,
    required this.config,
    required this.onTap,
  });

  @override
  State<_AnimatedMetalCard> createState() => _AnimatedMetalCardState();
}

class _AnimatedMetalCardState extends State<_AnimatedMetalCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    // Entry animation (driven by parent controller with delay)
    final begin = widget.delay;
    final end = (widget.delay + 0.6).clamp(0.0, 1.0);

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animController,
        curve: Interval(begin, end, curve: Curves.easeOutQuart),
      ),
    );

    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animController,
        curve: Interval(begin, end, curve: Curves.easeOutQuart),
      ),
    );

    // Shimmer loop
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed
                  ? 0.95
                  : _hovered
                      ? 1.02
                      : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: _hovered ? cfg.accentLight : cfg.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hovered
                        ? cfg.accent.withOpacity(0.5)
                        : cfg.accent.withOpacity(0.15),
                    width: _hovered ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovered
                          ? cfg.accent.withOpacity(0.2)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: _hovered ? 20 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // ── Shimmer stripe ────────────────────────────────────
                      AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, __) {
                          return Positioned.fill(
                            child: Opacity(
                              opacity: _hovered ? 0.08 : 0.04,
                              child: Transform.translate(
                                offset: Offset(
                                  (_shimmerCtrl.value * 240) - 60,
                                  -60,
                                ),
                                child: Transform.rotate(
                                  angle: 0.4,
                                  child: Container(
                                    width: 40,
                                    color: cfg.accent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // ── Card Content ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _hovered
                                    ? cfg.accent
                                    : cfg.accent.withOpacity(0.12),
                                shape: BoxShape.circle,
                                boxShadow: _hovered
                                    ? [
                                        BoxShadow(
                                          color: cfg.accent.withOpacity(0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                cfg.icon,
                                size: 26,
                                color: _hovered ? Colors.white : cfg.accent,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              cfg.title,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AddStockColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),

                            // Subtitle (Hindi name)
                            Text(
                              cfg.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AddStockColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Purity tag pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cfg.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cfg.accent.withOpacity(0.25)),
                              ),
                              child: Text(
                                cfg.tag,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cfg.tagColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Arrow CTA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Add Items',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cfg.accent,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _hovered
                                        ? cfg.accent
                                        : cfg.accent.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: _hovered ? Colors.white : cfg.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HUB APP BAR  (same dark-shell pattern)
// =============================================================================

class _HubAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const _HubAppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  State<_HubAppBar> createState() => _HubAppBarState();
}

class _HubAppBarState extends State<_HubAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;
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
      height: 64,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Back button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _backHovered = true),
                onExit: (_) => setState(() => _backHovered = false),
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _backHovered
                          ? AddStockColors.shellBg
                          : AddStockColors.shellBorder.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _backHovered
                            ? AddStockColors.brandGold
                            : AddStockColors.shellBorder,
                        width: _backHovered ? 1.5 : 1.0,
                      ),
                      boxShadow: _backHovered
                          ? [
                              BoxShadow(
                                color:
                                    AddStockColors.brandGold.withOpacity(0.3),
                                blurRadius: 10,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: _backHovered
                          ? AddStockColors.brandGold
                          : AddStockColors.shellTextTitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Divider
              Container(
                width: 1,
                height: 28,
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
              ),
              const SizedBox(width: 16),

              // Gradient Icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), AddStockColors.brandGold],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AddStockColors.brandGold.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_box_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),

              // Title + Online status
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD STOCK',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AddStockColors.shellTextTitle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildRadarDot(),
                      const SizedBox(width: 6),
                      Text(
                        'Metal Select karein',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AddStockColors.shellTextMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Module badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AddStockColors.moduleBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AddStockColors.moduleBadgeBorder),
                ),
                child: Text(
                  'STOCK & INVENTORY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.moduleBadgeText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarDot() {
    return AnimatedBuilder(
      animation: _blinkCtrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1.0 - _blinkCtrl.value,
            child: Transform.scale(
              scale: 1.0 + (_blinkCtrl.value * 1.5),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AddStockColors.onlineGreen.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
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
                  blurRadius: 5,
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
