// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_hub_screen.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Presentation
// DESCRIPTION : Hub screen with Gold, Silver, Diamond and Platinum rate cards.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/setting/metal_rate/metal_rate_controller.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/settings/metal_rate/metal_rate_theme.dart';
import 'metal_rate_app_bar.dart';
import 'metal_rate_detail_screen.dart';

class MetalRateHubScreen extends StatefulWidget {
  const MetalRateHubScreen({super.key});

  @override
  State<MetalRateHubScreen> createState() => _MetalRateHubScreenState();
}

class _MetalRateHubScreenState extends State<MetalRateHubScreen> {
  late final MetalRateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MetalRateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMetal(MetalRateMetal metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MetalRateDetailScreen(
          metal: metal,
          controller: _controller,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MetalRateColors.bodyBg,
      appBar: MetalRateAppBar(
        screenTitle: MetalRateStrings.hubTitle,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _controller.refresh,
          color: MetalRateColors.gold,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.state == MetalRateLoadState.loading ||
                  _controller.state == MetalRateLoadState.idle) {
                return const Center(
                  child: CircularProgressIndicator(color: MetalRateColors.gold),
                );
              }

              if (_controller.state == MetalRateLoadState.error) {
                return _ErrorState(
                  message: _controller.errorMessage ?? 'Unable to load rates.',
                  onRetry: _controller.refresh,
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: MetalRateStyles.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MetalRateStrings.selectMetal,
                      style: MetalRateStyles.sectionLabel,
                    ),
                    const SizedBox(height: 16),
                    _buildGrid(),
                    const SizedBox(height: 22),
                    _InfoBanner(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final profiles = _controller.profiles;
        if (wide) {
          return Row(
            children: profiles.map((profile) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _MetalRateCard(
                    profile: profile,
                    onTap: () => _openMetal(profile.metal),
                  ),
                ),
              );
            }).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 620 ? 2 : 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth > 620 ? 1.55 : 2.7,
          ),
          itemBuilder: (_, index) => _MetalRateCard(
            profile: profiles[index],
            onTap: () => _openMetal(profiles[index].metal),
          ),
        );
      },
    );
  }
}

class _MetalRateCard extends StatefulWidget {
  final MetalRateProfile profile;
  final VoidCallback onTap;

  const _MetalRateCard({
    required this.profile,
    required this.onTap,
  });

  @override
  State<_MetalRateCard> createState() => _MetalRateCardState();
}

class _MetalRateCardState extends State<_MetalRateCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1, end: 1.018)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final accent = _metalAccent(profile.metal);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: MetalRateStyles.metalCard(
              accent: accent,
              hovered: _hovered,
            ),
            child: Row(
              children: [
                _LogoTile(profile: profile, accent: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profile.metal.label,
                          style: MetalRateStyles.cardTitle),
                      const SizedBox(height: 5),
                      Text(
                        profile.marketSource,
                        style: MetalRateStyles.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SmallMetric(
                            label: 'Local Base',
                            value: _money(profile.marketBaseRatePer10g),
                            color: accent,
                          ),
                          _SmallMetric(
                            label: 'Primary Sell',
                            value: _money(profile.primaryShopRatePer10g),
                            color: MetalRateColors.success,
                          ),
                          _SmallMetric(
                            label: 'Primary Buy',
                            value: _money(profile.primaryBuyRatePer10g),
                            color: MetalRateColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(MetalRateIcons.arrow, color: accent, size: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _LogoTile({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          profile.metal.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: accent.withValues(alpha: 0.10),
            child: Icon(MetalRateIcons.moduleIcon, color: accent),
          ),
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: MetalRateStyles.softPanel(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MetalRateStyles.smallLabel.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: MetalRateStyles.softPanel(MetalRateColors.teal),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            MetalRateIcons.engine,
            color: MetalRateColors.teal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              MetalRateStrings.hubInfo,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: MetalRateColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            MetalRateIcons.warning,
            color: MetalRateColors.danger,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(message, style: MetalRateStyles.cardSubtitle),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Color _metalAccent(MetalRateMetal metal) {
  switch (metal) {
    case MetalRateMetal.gold:
      return MetalRateColors.gold;
    case MetalRateMetal.silver:
      return MetalRateColors.silver;
    case MetalRateMetal.diamond:
      return MetalRateColors.diamond;
    case MetalRateMetal.platinum:
      return MetalRateColors.platinum;
  }
}

String _money(double value) {
  if (value <= 0) {
    return '--';
  }
  final rounded = value.round().toString();
  return 'Rs ${rounded.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+\d$)'),
    (match) => '${match[1]},',
  )}';
}
