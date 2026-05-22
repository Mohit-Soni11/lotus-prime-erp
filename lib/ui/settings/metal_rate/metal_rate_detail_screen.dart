// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_detail_screen.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Presentation
// DESCRIPTION : Clean daily rate board with optional supplier costing.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../logic/setting/metal_rate/metal_rate_controller.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/settings/metal_rate/metal_rate_theme.dart';
import 'metal_rate_app_bar.dart';

class MetalRateDetailScreen extends StatefulWidget {
  final MetalRateMetal metal;
  final MetalRateController controller;

  const MetalRateDetailScreen({
    super.key,
    required this.metal,
    required this.controller,
  });

  @override
  State<MetalRateDetailScreen> createState() => _MetalRateDetailScreenState();
}

class _MetalRateDetailScreenState extends State<MetalRateDetailScreen> {
  Future<void> _save(MetalRateProfile profile) async {
    await widget.controller.saveProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${profile.metal.label} rates saved and applied to billing.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: MetalRateColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reset() async {
    await widget.controller.resetProfile(widget.metal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.metal.label} default rates restored.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: MetalRateColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final profile = widget.controller.profileFor(widget.metal);
        final history = widget.controller.historyFor(widget.metal);
        final accent = _metalAccent(widget.metal);
        final isSaving = widget.controller.state == MetalRateLoadState.saving;

        return Scaffold(
          backgroundColor: MetalRateColors.bodyBg,
          appBar: MetalRateAppBar(
            screenTitle: '${widget.metal.label} Daily Rate Board',
            screenSubtitle: 'MCX, physical market, supplier cost and shop rate',
            onBack: () => Navigator.maybePop(context),
            actions: [
              _AppBarAction(
                label: MetalRateStrings.resetDefaults,
                icon: MetalRateIcons.reset,
                color: MetalRateColors.warning,
                onTap: isSaving ? null : _reset,
              ),
              const SizedBox(width: 8),
              _AppBarAction(
                label: isSaving ? 'Saving...' : 'Save Rates',
                icon: MetalRateIcons.save,
                color: MetalRateColors.success,
                onTap: isSaving ? null : () => _save(profile),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: MetalRateStyles.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(profile: profile, accent: accent),
                  const SizedBox(height: 14),
                  _ReferenceBoard(
                    profile: profile,
                    accent: accent,
                    controller: widget.controller,
                  ),
                  const SizedBox(height: 14),
                  _SupplierRateBoard(
                    profile: profile,
                    accent: accent,
                    controller: widget.controller,
                  ),
                  const SizedBox(height: 14),
                  _HistoryCard(history: history, accent: accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _HeroCard({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          MetalRateStyles.panel(borderColor: accent.withValues(alpha: 0.30)),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                profile.metal.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  MetalRateIcons.moduleIcon,
                  color: accent,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.metal.label} Daily Rate Board',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: MetalRateColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set shop rates manually. Supplier costing is optional, but useful when you want to see cost before deciding final counter rate.',
                  style: MetalRateStyles.cardSubtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      label: 'MCX 24KT',
                      value: _money(profile.mcxRatePer10g),
                      color: accent,
                    ),
                    _MetricChip(
                      label: 'Physical 24KT',
                      value: _money(profile.physicalMarketRatePer10g),
                      color: MetalRateColors.teal,
                    ),
                    _MetricChip(
                      label: 'Supplier Base',
                      value: _money(profile.supplierBaseRatePer10g),
                      color: MetalRateColors.warning,
                    ),
                    _MetricChip(
                      label: 'Primary Shop Rate',
                      value: _money(profile.primaryShopRatePer10g),
                      color: MetalRateColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBoard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;

  const _ReferenceBoard({
    required this.profile,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.market,
      title: 'Market Inputs',
      subtitle:
          'MCX and physical market are references. They never overwrite shop selling rates automatically.',
      color: accent,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 820;
              final cards = [
                _ReferenceInputCard(
                  title: 'MCX 24KT Reference',
                  value: profile.mcxRatePer10g,
                  color: accent,
                  helper: 'Type today MCX/local reference manually',
                  onChanged: (value) =>
                      controller.updateReferenceRate(profile.metal, value),
                ),
                _ReferenceInputCard(
                  title: 'Physical 24KT Market',
                  value: profile.physicalMarketRatePer10g,
                  color: MetalRateColors.teal,
                  helper: 'Offline bullion/area market rate',
                  onChanged: (value) =>
                      controller.updatePhysicalRate(profile.metal, value),
                ),
                _ReferenceValueCard(
                  title: 'Supplier Base',
                  value: profile.supplierBaseRatePer10g,
                  color: MetalRateColors.warning,
                  helper:
                      'Used only for internal supplier cost calculation below',
                ),
              ];

              if (narrow) {
                return Column(
                  children: cards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: card,
                          ))
                      .toList(),
                );
              }

              return Row(
                children: cards
                    .map((card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: card,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const _InfoLine(
            text:
                'Supplier rate is optional. Billing needs only final shop rate, but supplier costing helps avoid selling below your purchase level.',
            color: MetalRateColors.teal,
          ),
        ],
      ),
    );
  }
}

class _SupplierRateBoard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;

  const _SupplierRateBoard({
    required this.profile,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.save,
      title: 'Supplier Costing And Shop Rates',
      subtitle:
          'Enter supplier billing percent, see supplier cost, then decide the final shop rate.',
      color: MetalRateColors.success,
      child: Column(
        children: List.generate(profile.purityPlans.length, (index) {
          final plan = profile.purityPlans[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == profile.purityPlans.length - 1 ? 0 : 12,
            ),
            child: _PurityPricingCard(
              profile: profile,
              plan: plan,
              index: index,
              accent: accent,
              controller: controller,
            ),
          );
        }),
      ),
    );
  }
}

class _PurityPricingCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final Color accent;
  final MetalRateController controller;

  const _PurityPricingCard({
    required this.profile,
    required this.plan,
    required this.index,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final supplierCost = profile.supplierCostFor(plan);
    final suggested = profile.suggestedShopRateFor(plan);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MetalRateColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MetalRateColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 52,
                alignment: Alignment.center,
                decoration: MetalRateStyles.softPanel(accent),
                child: Text(
                  _purityLabel(plan.label),
                  style: GoogleFonts.manrope(
                    color: MetalRateColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_purityLabel(plan.label)} Rate Setup',
                      style: MetalRateStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_percent(plan.purityPercent)} purity item, supplier billing ${_percent(plan.supplierBillingPercent > 0 ? plan.supplierBillingPercent : plan.purityPercent)}%',
                      style: MetalRateStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              _MetricChip(
                label: 'Suggested',
                value: _money(suggested),
                color: MetalRateColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final tileWidth = narrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 30) / 4;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PercentInputTile(
                    width: tileWidth,
                    label: 'Supplier Basis',
                    value: plan.supplierBillingPercent > 0
                        ? plan.supplierBillingPercent
                        : plan.purityPercent,
                    color: MetalRateColors.warning,
                    helper: 'Example: 18KT billed as 80%',
                    onChanged: (value) => controller.updateSupplierBasis(
                      metal: profile.metal,
                      index: index,
                      supplierBillingPercent: value,
                    ),
                  ),
                  _ValueTile(
                    width: tileWidth,
                    label: 'Supplier Cost',
                    value: _money(supplierCost),
                    color: MetalRateColors.warning,
                    helper: 'Base x supplier basis',
                  ),
                  _PercentInputTile(
                    width: tileWidth,
                    label: 'Shop Markup',
                    value: plan.shopMarkupPercent,
                    color: MetalRateColors.teal,
                    helper: 'Extra percent over supplier cost',
                    onChanged: (value) => controller.updateSupplierBasis(
                      metal: profile.metal,
                      index: index,
                      shopMarkupPercent: value,
                    ),
                  ),
                  _ValueTile(
                    width: tileWidth,
                    label: 'Calculated Rate',
                    value: _money(suggested),
                    color: MetalRateColors.success,
                    helper: 'Suggestion only, not auto applied',
                  ),
                  _AmountInputTile(
                    width: tileWidth,
                    label: 'Final Shop Rate',
                    value: plan.manualDisplayRatePer10g,
                    color: accent,
                    helper: 'Billing will use this rate',
                    onChanged: (value) => controller.updateShopRate(
                      metal: profile.metal,
                      index: index,
                      value: value,
                    ),
                  ),
                  _ActionTile(
                    width: tileWidth,
                    label: 'Use Calculated',
                    value: _money(suggested),
                    color: MetalRateColors.success,
                    helper: 'Click only if you want to apply it',
                    onTap: () => controller.updateShopRate(
                      metal: profile.metal,
                      index: index,
                      value: suggested,
                    ),
                  ),
                  _AmountInputTile(
                    width: tileWidth,
                    label: 'Old Buy Rate',
                    value: plan.buyRatePer10g,
                    color: MetalRateColors.platinum,
                    helper: 'Optional exchange/purchase rate',
                    onChanged: (value) => controller.updateBuyRate(
                      metal: profile.metal,
                      index: index,
                      value: value,
                    ),
                  ),
                  _ValueTile(
                    width: tileWidth,
                    label: 'Spread',
                    value: _money(plan.manualDisplayRatePer10g - supplierCost),
                    color: plan.manualDisplayRatePer10g >= supplierCost
                        ? MetalRateColors.success
                        : MetalRateColors.danger,
                    helper: 'Shop rate minus supplier cost',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;

  const _HistoryCard({
    required this.history,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.reset,
      title: 'Rate History',
      subtitle: 'Recent saved rate changes for audit and bill verification.',
      color: accent,
      child: history.isEmpty
          ? _InfoLine(
              text: 'No saved history yet. Save today rates to create a log.',
              color: accent,
            )
          : Column(
              children: history.take(6).map((entry) {
                return _HistoryRow(entry: entry, accent: accent);
              }).toList(),
            ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MetalRateHistoryEntry entry;
  final Color accent;

  const _HistoryRow({
    required this.entry,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: MetalRateStyles.fieldBox,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: MetalRateStyles.softPanel(accent),
            child: Icon(MetalRateIcons.save, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(entry.changedAt),
                  style: GoogleFonts.inter(
                    color: MetalRateColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Shop ${_money(entry.profile.primaryShopRatePer10g)} | Buy ${_money(entry.profile.primaryBuyRatePer10g)}',
                  style: MetalRateStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceInputCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final String helper;
  final ValueChanged<double> onChanged;

  const _ReferenceInputCard({
    required this.title,
    required this.value,
    required this.color,
    required this.helper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _AmountInputTile(
      width: double.infinity,
      label: title,
      value: value,
      color: color,
      helper: helper,
      onChanged: onChanged,
    );
  }
}

class _ReferenceValueCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final String helper;

  const _ReferenceValueCard({
    required this.title,
    required this.value,
    required this.color,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return _ValueTile(
      width: double.infinity,
      label: title,
      value: _money(value),
      color: color,
      helper: helper,
    );
  }
}

class _AmountInputTile extends StatefulWidget {
  final double width;
  final String label;
  final double value;
  final Color color;
  final String helper;
  final ValueChanged<double> onChanged;

  const _AmountInputTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
    required this.onChanged,
  });

  @override
  State<_AmountInputTile> createState() => _AmountInputTileState();
}

class _AmountInputTileState extends State<_AmountInputTile> {
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _inputValue(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AmountInputTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _inputValue(widget.value);
    if (!_focusNode.hasFocus && _textCtrl.text != next) {
      _textCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.softPanel(widget.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: MetalRateStyles.smallLabel.copyWith(color: widget.color),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (raw) => widget.onChanged(_parseNumber(raw)),
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              decoration: _inputDecoration(
                color: widget.color,
                prefix: 'Rs ',
                suffix: 'per 10g',
              ),
            ),
            const SizedBox(height: 6),
            _HelperText(widget.helper),
          ],
        ),
      ),
    );
  }
}

class _PercentInputTile extends StatefulWidget {
  final double width;
  final String label;
  final double value;
  final Color color;
  final String helper;
  final ValueChanged<double> onChanged;

  const _PercentInputTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
    required this.onChanged,
  });

  @override
  State<_PercentInputTile> createState() => _PercentInputTileState();
}

class _PercentInputTileState extends State<_PercentInputTile> {
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _percentInputValue(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _PercentInputTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _percentInputValue(widget.value);
    if (!_focusNode.hasFocus && _textCtrl.text != next) {
      _textCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.softPanel(widget.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: MetalRateStyles.smallLabel.copyWith(color: widget.color),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (raw) => widget.onChanged(_parseNumber(raw)),
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              decoration: _inputDecoration(
                color: widget.color,
                suffix: '%',
              ),
            ),
            const SizedBox(height: 6),
            _HelperText(widget.helper),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color color;
  final String helper;

  const _ValueTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.softPanel(color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: MetalRateStyles.smallLabel.copyWith(color: color)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            _HelperText(helper),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color color;
  final String helper;
  final VoidCallback onTap;

  const _ActionTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MetalRateStyles.rInner),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: MetalRateStyles.softPanel(color),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: MetalRateStyles.smallLabel.copyWith(color: color),
                    ),
                  ),
                  Icon(MetalRateIcons.arrow, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: MetalRateColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _HelperText(helper),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;

  const _HelperText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MetalRateStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: MetalRateStyles.softPanel(color),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MetalRateStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: MetalRateStyles.cardSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoLine({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: MetalRateStyles.softPanel(color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(MetalRateIcons.shield, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: MetalRateColors.textBody,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: MetalRateStyles.softPanel(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MetalRateStyles.smallLabel.copyWith(color: color)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AppBarAction({
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required Color color,
  String? prefix,
  String? suffix,
}) {
  return InputDecoration(
    prefixText: prefix,
    suffixText: suffix,
    filled: true,
    fillColor: MetalRateColors.cardBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: MetalRateColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: MetalRateColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: 1.4),
    ),
  );
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

double _parseNumber(String value) =>
    double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;

String _inputValue(double value) {
  if (value <= 0) {
    return '';
  }
  return value.round().toString();
}

String _percentInputValue(double value) {
  if (value <= 0) {
    return '';
  }
  final whole = value.roundToDouble() == value;
  return whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

String _purityLabel(String label) {
  final value = label.trim().toUpperCase();
  final match = RegExp(r'^(\d+)K$').firstMatch(value);
  if (match != null) {
    return '${match.group(1)}KT';
  }
  return value;
}

String _percent(double value) {
  final whole = value.roundToDouble() == value;
  return whole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
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
