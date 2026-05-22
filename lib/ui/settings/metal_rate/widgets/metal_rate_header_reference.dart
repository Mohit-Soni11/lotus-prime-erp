part of '../metal_rate_detail_screen.dart';

class _HeaderCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _HeaderCard({
    required this.profile,
    required this.accent,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          MetalRateStyles.panel(borderColor: accent.withValues(alpha: 0.32)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final identity = Row(
            children: [
              _HeaderLogo(profile: profile, accent: accent),
              const SizedBox(width: 16),
              Expanded(
                  child: _HeaderTextBlock(profile: profile, accent: accent)),
            ],
          );
          final liveControl = _LiveRateControl(
            accent: accent,
            isEditing: isEditing,
            isSaving: isSaving,
            onEdit: onEdit,
            onSave: onSave,
            onReset: onReset,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: liveControl),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              liveControl,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _HeaderLogo({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: MetalRateColors.shellBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Image.asset(
        profile.metal.assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          MetalRateIcons.moduleIcon,
          color: accent,
          size: 34,
        ),
      ),
    );
  }
}

class _HeaderTextBlock extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _HeaderTextBlock({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${profile.metal.label} Rate Master',
          style: GoogleFonts.manrope(
            color: MetalRateColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage counter selling rates, old-metal purchase rates, and daily rate history.',
          style: MetalRateStyles.cardSubtitle,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(
              label: 'Local Base',
              value: _money(profile.marketBaseRatePer10g),
              color: accent,
            ),
            _MetricChip(
              label: 'Primary Sell',
              value: _money(profile.primaryShopRatePer10g),
              color: MetalRateColors.success,
            ),
            _MetricChip(
              label: 'Primary Buy',
              value: _money(profile.primaryBuyRatePer10g),
              color: MetalRateColors.warning,
            ),
            _MetricChip(
              label: 'Rate Rows',
              value: '${profile.purityPlans.length}',
              color: MetalRateColors.violet,
            ),
          ],
        ),
      ],
    );
  }
}

class _MarketReferenceSection extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;
  final bool enabled;

  const _MarketReferenceSection({
    required this.profile,
    required this.accent,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.market,
      title: 'Market Reference',
      subtitle:
          'Local physical market is the calculation base. MCX is only an optional reference.',
      color: accent,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AmountInputTile(
                    width: width,
                    label: _spotReferenceLabel(profile.metal),
                    value: profile.mcxRatePer10g,
                    color: MetalRateColors.violet,
                    helper: 'Optional reference only',
                    enabled: enabled,
                    onChanged: (value) => controller.updateReferenceRate(
                      profile.metal,
                      value,
                    ),
                  ),
                  _AmountInputTile(
                    width: width,
                    label: 'Local Physical Market',
                    value: profile.physicalMarketRatePer10g,
                    color: accent,
                    helper: 'Primary market reference',
                    enabled: enabled,
                    onChanged: (value) => controller.updatePhysicalRate(
                      profile.metal,
                      value,
                    ),
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Local Rate Base',
                    value: _money(profile.marketBaseRatePer10g),
                    color: MetalRateColors.success,
                    helper: 'Used for parity reference',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const _InfoLine(
            text:
                'Billing uses Counter Selling Rate. Local Physical Market is maintained only as a reference for parity checks.',
            color: MetalRateColors.warning,
          ),
        ],
      ),
    );
  }
}

class _LiveRateControl extends StatelessWidget {
  final Color accent;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _LiveRateControl({
    required this.accent,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: isEditing
          ? _EditControlPanel(
              key: const ValueKey('editing'),
              accent: accent,
              isSaving: isSaving,
              onSave: onSave,
              onReset: onReset,
            )
          : _LiveRateBadge(
              key: const ValueKey('live'),
              accent: accent,
              onTap: onEdit,
            ),
    );
  }
}

class _LiveRateBadge extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;

  const _LiveRateBadge({
    super.key,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_LiveRateBadge> createState() => _LiveRateBadgeState();
}

class _LiveRateBadgeState extends State<_LiveRateBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _hovered = false;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 188,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MetalRateColors.onlineGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? MetalRateColors.onlineGreen
                  : MetalRateColors.onlineGreen.withValues(alpha: 0.28),
              width: _hovered ? 1.3 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: MetalRateColors.onlineGreen.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _LiveWave(controller: _pulseCtrl, delay: 0),
                    _LiveWave(controller: _pulseCtrl, delay: 0.5),
                    const Icon(
                      MetalRateIcons.market,
                      color: MetalRateColors.onlineGreen,
                      size: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LIVE RATE',
                      style: MetalRateStyles.smallLabel.copyWith(
                        color: MetalRateColors.onlineGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Click to edit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MetalRateColors.textBody,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveWave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _LiveWave({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - value,
          child: Transform.scale(
            scale: 1 + (value * 1.4),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MetalRateColors.onlineGreen.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditControlPanel extends StatelessWidget {
  final Color accent;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _EditControlPanel({
    super.key,
    required this.accent,
    required this.isSaving,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 244,
      padding: const EdgeInsets.all(12),
      decoration: MetalRateStyles.softPanel(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(MetalRateIcons.edit, color: accent, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'EDIT MODE',
                  style: MetalRateStyles.smallLabel.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeaderActionButton(
                  label: isSaving ? 'Saving' : 'Save',
                  icon: MetalRateIcons.save,
                  color: MetalRateColors.success,
                  onTap: isSaving ? null : onSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderActionButton(
                  label: 'Reset',
                  icon: MetalRateIcons.reset,
                  color: MetalRateColors.warning,
                  onTap: isSaving ? null : onReset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
