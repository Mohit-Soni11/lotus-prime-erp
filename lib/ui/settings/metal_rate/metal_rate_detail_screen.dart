// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_detail_screen.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Presentation
// DESCRIPTION : Smart metal pricing workspace for market, brand, cost and rates.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _editMode = false;

  Future<void> _save(MetalRateProfile profile) async {
    await widget.controller.saveProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${profile.metal.label} rate profile saved.',
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
          '${widget.metal.label} defaults restored.',
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
        final accent = _metalAccent(widget.metal);
        final isSaving = widget.controller.state == MetalRateLoadState.saving;

        return Scaffold(
          backgroundColor: MetalRateColors.bodyBg,
          appBar: MetalRateAppBar(
            screenTitle: '${widget.metal.label} Rate Intelligence',
            screenSubtitle: 'Smart margin and market benchmark engine',
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
                label: isSaving ? 'Saving...' : MetalRateStrings.saveProfile,
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
                  _HeroStrip(
                    profile: profile,
                    accent: accent,
                    editMode: _editMode,
                    onToggleEdit: () => setState(() => _editMode = !_editMode),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1080;
                      if (!wide) {
                        return Column(
                          children: [
                            _MarketBaseCard(
                              profile: profile,
                              accent: accent,
                              controller: widget.controller,
                              editMode: _editMode,
                            ),
                            const SizedBox(height: 14),
                            _CostEngineCard(
                              profile: profile,
                              controller: widget.controller,
                              editMode: _editMode,
                            ),
                            const SizedBox(height: 14),
                            _InsightPanel(profile: profile, accent: accent),
                            const SizedBox(height: 14),
                            _RecommendationTable(
                              profile: profile,
                              controller: widget.controller,
                              accent: accent,
                              editMode: _editMode,
                            ),
                            const SizedBox(height: 14),
                            _BrandBenchmarkCard(
                              profile: profile,
                              controller: widget.controller,
                              editMode: _editMode,
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 8,
                                child: Column(
                                  children: [
                                    _MarketBaseCard(
                                      profile: profile,
                                      accent: accent,
                                      controller: widget.controller,
                                      editMode: _editMode,
                                    ),
                                    const SizedBox(height: 14),
                                    _RecommendationTable(
                                      profile: profile,
                                      controller: widget.controller,
                                      accent: accent,
                                      editMode: _editMode,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _CostEngineCard(
                                      profile: profile,
                                      controller: widget.controller,
                                      editMode: _editMode,
                                    ),
                                    const SizedBox(height: 14),
                                    _InsightPanel(
                                      profile: profile,
                                      accent: accent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _BrandBenchmarkCard(
                            profile: profile,
                            controller: widget.controller,
                            editMode: _editMode,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroStrip extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final bool editMode;
  final VoidCallback onToggleEdit;

  const _HeroStrip({
    required this.profile,
    required this.accent,
    required this.editMode,
    required this.onToggleEdit,
  });

  @override
  Widget build(BuildContext context) {
    final recs = profile.recommendations;
    final primary = recs.isEmpty ? null : recs.first;
    final safeCount = recs.where((rec) => rec.guardrail == 'Safe').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          MetalRateStyles.panel(borderColor: accent.withValues(alpha: 0.28)),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                profile.metal.assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.metal.label} Smart Rate Engine',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: MetalRateColors.textDark,
                        ),
                      ),
                    ),
                    _ModeToggleButton(
                      editMode: editMode,
                      accent: accent,
                      onTap: onToggleEdit,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  editMode
                      ? 'Edit mode is open. Update MCX, physical market, brand rates, supplier cost, shop rate and making charge.'
                      : 'Live edit is hidden. Review MCX, physical market, brand benchmarks, your cost and AI pricing suggestions.',
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
                      label: 'Engine Base',
                      value: _money(profile.marketBaseRatePer10g),
                      color: MetalRateColors.warning,
                    ),
                    _MetricChip(
                      label: 'Primary Suggestion',
                      value: primary == null
                          ? '--'
                          : _money(primary.suggestedRatePer10g),
                      color: MetalRateColors.success,
                    ),
                    _MetricChip(
                      label: 'Safe Purities',
                      value: '$safeCount/${recs.length}',
                      color: MetalRateColors.diamond,
                    ),
                    _MetricChip(
                      label: 'Mode',
                      value: editMode ? 'Editing' : 'View',
                      color: MetalRateColors.violet,
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

class _ModeToggleButton extends StatelessWidget {
  final bool editMode;
  final Color accent;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.editMode,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = editMode ? MetalRateColors.success : accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              editMode ? MetalRateIcons.shield : MetalRateIcons.edit,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 7),
            Text(
              editMode ? 'Hide Edit' : 'Live Edit',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketBaseCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;
  final bool editMode;

  const _MarketBaseCard({
    required this.profile,
    required this.accent,
    required this.controller,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.market,
      title: 'Manual Market Base',
      subtitle:
          'This is not live data yet. Enter MCX/local bullion rate manually, then GST, duty and buffers are layered separately.',
      color: accent,
      child: Column(
        children: [
          _StepperField(
            label: 'MCX 24KT rate per 10g',
            value: profile.mcxRatePer10g,
            step: profile.mcxRatePer10g > 5000 ? 100 : 10,
            color: accent,
            money: true,
            editable: editMode,
            onChanged: (value) => controller.updateMarketInputs(
              metal: profile.metal,
              mcxRate: value,
            ),
          ),
          const SizedBox(height: 12),
          _StepperField(
            label: 'Physical market 24KT rate per 10g',
            value: profile.physicalMarketRatePer10g,
            step: profile.physicalMarketRatePer10g > 5000 ? 100 : 10,
            color: MetalRateColors.teal,
            money: true,
            editable: editMode,
            onChanged: (value) => controller.updateMarketInputs(
              metal: profile.metal,
              physicalRate: value,
            ),
          ),
          const SizedBox(height: 12),
          _MetricChip(
            label: 'Engine Base',
            value: _money(profile.marketBaseRatePer10g),
            color: MetalRateColors.warning,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StepperField(
                  label: 'GST',
                  value: profile.gstPercent,
                  step: 0.25,
                  suffix: '%',
                  color: MetalRateColors.teal,
                  editable: editMode,
                  onChanged: (value) => controller.updatePercent(
                    metal: profile.metal,
                    gst: value,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepperField(
                  label: 'Import duty',
                  value: profile.importDutyPercent,
                  step: 0.25,
                  suffix: '%',
                  color: MetalRateColors.warning,
                  editable: editMode,
                  onChanged: (value) => controller.updatePercent(
                    metal: profile.metal,
                    importDuty: value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _NoticeLine(
            text:
                'Live MCX/API sync is not connected on this screen. Current rates are saved manual benchmarks, so update them before daily billing.',
            color: MetalRateColors.warning,
          ),
        ],
      ),
    );
  }
}

class _CostEngineCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRateController controller;
  final bool editMode;

  const _CostEngineCard({
    required this.profile,
    required this.controller,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.engine,
      title: MetalRateStrings.costEngine,
      subtitle: 'Tune protection buffers and competitive posture.',
      color: MetalRateColors.teal,
      child: Column(
        children: [
          _PostureSelector(
            profile: profile,
            controller: controller,
            editable: editMode,
          ),
          const SizedBox(height: 12),
          _StepperField(
            label: 'Minimum margin guardrail',
            value: profile.minimumMarginPercent,
            step: 0.25,
            suffix: '%',
            color: MetalRateColors.success,
            editable: editMode,
            onChanged: (value) => controller.updatePercent(
              metal: profile.metal,
              minimumMargin: value,
            ),
          ),
          const SizedBox(height: 10),
          _StepperField(
            label: 'Beat premium brands by',
            value: profile.competitiveDiscountPercent,
            step: 0.25,
            suffix: '%',
            color: MetalRateColors.violet,
            editable: editMode,
            onChanged: (value) => controller.updatePercent(
              metal: profile.metal,
              competitiveDiscount: value,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StepperField(
                  label: 'Wastage risk',
                  value: profile.wastageBufferPercent,
                  step: 0.10,
                  suffix: '%',
                  color: MetalRateColors.warning,
                  editable: editMode,
                  onChanged: (value) => controller.updatePercent(
                    metal: profile.metal,
                    wastage: value,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepperField(
                  label: 'Holding cost',
                  value: profile.holdingCostPercent,
                  step: 0.10,
                  suffix: '%',
                  color: MetalRateColors.diamond,
                  editable: editMode,
                  onChanged: (value) => controller.updatePercent(
                    metal: profile.metal,
                    holding: value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StepperField(
            label: 'Transport and handling',
            value: profile.logisticsPercent,
            step: 0.10,
            suffix: '%',
            color: MetalRateColors.platinum,
            editable: editMode,
            onChanged: (value) => controller.updatePercent(
              metal: profile.metal,
              logistics: value,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostureSelector extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRateController controller;
  final bool editable;

  const _PostureSelector({
    required this.profile,
    required this.controller,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: MetalRateStyles.fieldBox,
      child: Row(
        children: PricingPosture.values.map((posture) {
          final active = posture == profile.posture;
          return Expanded(
            child: GestureDetector(
              onTap: editable
                  ? () => controller.updatePosture(profile.metal, posture)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? MetalRateColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  posture.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : MetalRateColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecommendationTable extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRateController controller;
  final Color accent;
  final bool editMode;

  const _RecommendationTable({
    required this.profile,
    required this.controller,
    required this.accent,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.shield,
      title: 'Purity Rate Plan',
      subtitle:
          'Clear per-purity view for market price, your cost, AI suggestion and your final selling rate.',
      color: accent,
      child: Column(
        children: [
          const _NoticeLine(
            text:
                'Data mode is manual. Fill My Cost when you know the exact landed cost, and fill My Selling Rate when you want to override the engine suggestion.',
            color: MetalRateColors.teal,
          ),
          const SizedBox(height: 12),
          ...List.generate(profile.purityPlans.length, (index) {
            final plan = profile.purityPlans[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == profile.purityPlans.length - 1 ? 0 : 10,
              ),
              child: _RatePlanRow(
                profile: profile,
                plan: plan,
                index: index,
                accent: accent,
                controller: controller,
                editMode: editMode,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RatePlanRow extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final Color accent;
  final MetalRateController controller;
  final bool editMode;

  const _RatePlanRow({
    required this.profile,
    required this.plan,
    required this.index,
    required this.accent,
    required this.controller,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    final rec = profile.recommendationFor(plan);
    final guardColor = rec.guardrail == 'Safe'
        ? MetalRateColors.success
        : rec.guardrail == 'Premium'
            ? MetalRateColors.violet
            : MetalRateColors.warning;
    final manual = rec.usesCostOverride ||
        rec.usesManualDisplayRate ||
        rec.usesManualMaking;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MetalRateColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: manual
              ? accent.withValues(alpha: 0.42)
              : MetalRateColors.cardBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth < 660;
          final metricWidth = fullWidth ? constraints.maxWidth : 154.0;
          final controlWidth = fullWidth ? constraints.maxWidth : 190.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PurityBadge(
                    label: _purityLabel(plan.label),
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_purityLabel(plan.label)} Pricing',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: MetalRateColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_percent(plan.purityPercent)} purity, per 10g rate planning',
                          style: MetalRateStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      _StatusPill(
                        label: rec.guardrail,
                        color: guardColor,
                      ),
                      if (manual)
                        const _StatusPill(
                          label: 'Manual',
                          color: MetalRateColors.teal,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'MCX Rate',
                    value: _money(rec.mcxRatePer10g),
                    helper: '24KT adjusted',
                    color: accent,
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Physical Market',
                    value: _money(rec.physicalRatePer10g),
                    helper: 'Offline rate',
                    color: MetalRateColors.teal,
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Brand Average',
                    value: _money(rec.brandAveragePer10g),
                    helper: 'Top brand metal',
                    color: MetalRateColors.violet,
                  ),
                  _RateOverrideControl(
                    width: controlWidth,
                    label: 'My Supplier Cost',
                    value: plan.landedCostOverridePer10g,
                    baseValue: rec.landedCostPer10g,
                    step: 100,
                    color: MetalRateColors.teal,
                    editable: editMode,
                    helper: rec.usesCostOverride
                        ? 'Actual landed cost'
                        : 'Auto landed cost',
                    onChanged: (value) => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      landedCost: value,
                    ),
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Safe Minimum',
                    value: _money(rec.safeMinimumPer10g),
                    helper: 'Cost plus guardrail',
                    color: MetalRateColors.success,
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'AI Suggestion',
                    value: _money(rec.suggestedRatePer10g),
                    helper: rec.usesManualDisplayRate
                        ? 'Overridden by you'
                        : 'Engine display rate',
                    color: MetalRateColors.violet,
                    strong: true,
                  ),
                  _RateOverrideControl(
                    width: controlWidth,
                    label: 'My Selling Rate',
                    value: plan.manualDisplayRatePer10g,
                    baseValue: rec.suggestedRatePer10g,
                    step: 100,
                    color: guardColor,
                    editable: editMode,
                    helper: rec.usesManualDisplayRate
                        ? 'Counter display rate'
                        : 'Auto engine rate',
                    onChanged: (value) => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      displayRate: value,
                    ),
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'AI Making',
                    value: '${rec.suggestedMakingPercent.toStringAsFixed(1)}%',
                    helper: '${_money(rec.suggestedMakingPerGram)}/g',
                    color: MetalRateColors.diamond,
                  ),
                  _RateAdjustTile(
                    width: metricWidth,
                    label: 'My Making Charge',
                    value: rec.selectedMakingPercent,
                    helper: rec.usesManualMaking
                        ? 'Your shop making'
                        : 'Auto AI making',
                    editable: editMode,
                    color: MetalRateColors.warning,
                    onChanged: (value) => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      makingPercent: value,
                    ),
                    onReset: () => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      makingPercent: 0,
                      makingPerGram: 0,
                    ),
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Customer Total',
                    value: _money(rec.customerTotalPer10g),
                    helper: 'Rate + making',
                    color: MetalRateColors.platinum,
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Margin',
                    value: '${rec.marginPercent.toStringAsFixed(1)}%',
                    helper: 'After cost + making',
                    color: rec.marginPercent >= profile.minimumMarginPercent
                        ? MetalRateColors.success
                        : MetalRateColors.danger,
                  ),
                  _RateMetricTile(
                    width: metricWidth,
                    label: 'Brand Position',
                    value: _brandPosition(rec.cheaperThanBrandPercent),
                    helper: 'Vs top brands',
                    color: rec.cheaperThanBrandPercent >= 0
                        ? MetalRateColors.success
                        : MetalRateColors.warning,
                  ),
                  _RateAdjustTile(
                    width: metricWidth,
                    label: 'Supplier Premium',
                    value: plan.supplierPremiumPercent,
                    helper: 'Supplier extra',
                    editable: editMode,
                    color: MetalRateColors.teal,
                    onChanged: (value) => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      supplierPremium: value,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PurityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PurityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 52,
      alignment: Alignment.center,
      decoration: MetalRateStyles.softPanel(color),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: MetalRateColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RateMetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String helper;
  final Color color;
  final bool strong;

  const _RateMetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
    this.strong = false,
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
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: strong ? 16 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MetalRateColors.textBody,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateOverrideControl extends StatelessWidget {
  final double width;
  final String label;
  final double value;
  final double baseValue;
  final double step;
  final Color color;
  final bool editable;
  final String helper;
  final ValueChanged<double> onChanged;

  const _RateOverrideControl({
    required this.width,
    required this.label,
    required this.value,
    required this.baseValue,
    required this.step,
    required this.color,
    required this.editable,
    required this.helper,
    required this.onChanged,
  });

  Future<void> _openEditor(BuildContext context) async {
    final input = TextEditingController(
      text: (value > 0 ? value : baseValue).round().toString(),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MetalRateColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            label,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              labelText: 'Rate per 10g',
              prefixText: 'Rs ',
              suffixText: 'per 10g',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 0.0),
              child: const Text('Use Auto'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  input.text.replaceAll(',', '').trim(),
                );
                if (parsed == null) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  parsed.clamp(0, 9999999).toDouble(),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    input.dispose();
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manual = value > 0;
    final displayValue = manual ? value : baseValue;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color:
              manual ? color.withValues(alpha: 0.08) : MetalRateColors.cardBg,
          borderRadius: BorderRadius.circular(MetalRateStyles.rInner),
          border: Border.all(
            color: manual
                ? color.withValues(alpha: 0.32)
                : MetalRateColors.cardBorder,
          ),
        ),
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
                _StatusPill(
                  label: manual ? 'Manual' : 'Auto',
                  color: manual ? color : MetalRateColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _money(displayValue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MetalRateColors.textBody,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (editable) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  _RoundButton(
                    icon: MetalRateIcons.minus,
                    color: color,
                    onTap: () {
                      final source = manual ? value : baseValue;
                      onChanged((source - step).clamp(0, 9999999).toDouble());
                    },
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: MetalRateIcons.plus,
                    color: color,
                    onTap: () {
                      final source = manual ? value : baseValue;
                      onChanged((source + step).clamp(0, 9999999).toDouble());
                    },
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: MetalRateIcons.edit,
                    color: color,
                    onTap: () => _openEditor(context),
                  ),
                  if (manual) ...[
                    const SizedBox(width: 8),
                    _RoundButton(
                      icon: MetalRateIcons.reset,
                      color: MetalRateColors.textMuted,
                      onTap: () => onChanged(0),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateAdjustTile extends StatelessWidget {
  final double width;
  final String label;
  final double value;
  final String helper;
  final bool editable;
  final Color color;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  const _RateAdjustTile({
    required this.width,
    required this.label,
    required this.value,
    required this.helper,
    required this.editable,
    required this.color,
    required this.onChanged,
    this.onReset,
  });

  Future<void> _openEditor(BuildContext context) async {
    final input = TextEditingController(text: value.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MetalRateColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            label,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              labelText: 'Percentage',
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            if (onReset != null)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, -1.0),
                child: const Text('Use Auto'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  input.text.replaceAll(',', '').trim(),
                );
                if (parsed == null) {
                  return;
                }
                Navigator.pop(dialogContext, parsed.clamp(0, 99).toDouble());
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    input.dispose();
    if (result == null) {
      return;
    }
    if (result < 0 && onReset != null) {
      onReset?.call();
      return;
    }
    onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.fieldBox,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: MetalRateStyles.smallLabel.copyWith(color: color)),
            const SizedBox(height: 5),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              helper,
              style: GoogleFonts.inter(
                color: MetalRateColors.textBody,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (editable) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  _RoundButton(
                    icon: MetalRateIcons.minus,
                    color: color,
                    onTap: () =>
                        onChanged((value - 0.5).clamp(0, 99).toDouble()),
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: MetalRateIcons.plus,
                    color: color,
                    onTap: () =>
                        onChanged((value + 0.5).clamp(0, 99).toDouble()),
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: MetalRateIcons.edit,
                    color: color,
                    onTap: () => _openEditor(context),
                  ),
                  if (onReset != null) ...[
                    const SizedBox(width: 8),
                    _RoundButton(
                      icon: MetalRateIcons.reset,
                      color: MetalRateColors.textMuted,
                      onTap: onReset!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BrandBenchmarkCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRateController controller;
  final bool editMode;

  const _BrandBenchmarkCard({
    required this.profile,
    required this.controller,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.benchmark,
      title: MetalRateStrings.brandBenchmark,
      subtitle:
          'Track top brand metal rates and making charge for every purity.',
      color: MetalRateColors.violet,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final children = List.generate(profile.brandBenchmarks.length, (i) {
            final brand = profile.brandBenchmarks[i];
            return _BrandRow(
              brand: brand,
              purityPlans: profile.purityPlans,
              editMode: editMode,
              onRate: (label, value) => controller.updateBrandBenchmark(
                metal: profile.metal,
                index: i,
                purityLabel: label,
                purityRate: value,
              ),
              onMaking: (label, value) => controller.updateBrandBenchmark(
                metal: profile.metal,
                index: i,
                purityLabel: label,
                purityMaking: value,
              ),
            );
          });
          return Column(children: children);
        },
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final MetalRateBrandBenchmark brand;
  final List<MetalRatePurityPlan> purityPlans;
  final bool editMode;
  final void Function(String label, double value) onRate;
  final void Function(String label, double value) onMaking;

  const _BrandRow({
    required this.brand,
    required this.purityPlans,
    required this.editMode,
    required this.onRate,
    required this.onMaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: MetalRateStyles.fieldBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(brand.brandName, style: MetalRateStyles.cardTitle),
              ),
              _StatusPill(
                label:
                    'Making ${brand.makingLowPercent.toStringAsFixed(0)}-${brand.makingHighPercent.toStringAsFixed(0)}%',
                color: MetalRateColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: purityPlans.map((plan) {
              return _BrandPurityTile(
                label: plan.label,
                rate: brand.rateFor(plan),
                making: brand.makingFor(plan),
                editMode: editMode,
                onRate: (value) => onRate(plan.label, value),
                onMaking: (value) => onMaking(plan.label, value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BrandPurityTile extends StatelessWidget {
  final String label;
  final double rate;
  final double making;
  final bool editMode;
  final ValueChanged<double> onRate;
  final ValueChanged<double> onMaking;

  const _BrandPurityTile({
    required this.label,
    required this.rate,
    required this.making,
    required this.editMode,
    required this.onRate,
    required this.onMaking,
  });

  Future<void> _editNumber({
    required BuildContext context,
    required String title,
    required double value,
    required bool money,
    required ValueChanged<double> onChanged,
  }) async {
    final input = TextEditingController(
      text: money ? value.round().toString() : value.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MetalRateColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            title,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              prefixText: money ? 'Rs ' : null,
              suffixText: money ? 'per 10g' : '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  input.text.replaceAll(',', '').trim(),
                );
                if (parsed == null) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  parsed.clamp(0, money ? 9999999 : 99).toDouble(),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    input.dispose();
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      padding: const EdgeInsets.all(10),
      decoration: MetalRateStyles.softPanel(MetalRateColors.violet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _purityLabel(label),
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          _BrandValueLine(
            label: 'Rate',
            value: _money(rate),
            editable: editMode,
            onTap: () => _editNumber(
              context: context,
              title: '${_purityLabel(label)} brand rate',
              value: rate,
              money: true,
              onChanged: onRate,
            ),
          ),
          const SizedBox(height: 6),
          _BrandValueLine(
            label: 'Making',
            value: '${making.toStringAsFixed(1)}%',
            editable: editMode,
            onTap: () => _editNumber(
              context: context,
              title: '${_purityLabel(label)} brand making',
              value: making,
              money: false,
              onChanged: onMaking,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandValueLine extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;
  final VoidCallback onTap;

  const _BrandValueLine({
    required this.label,
    required this.value,
    required this.editable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: MetalRateStyles.smallLabel),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: MetalRateColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (editable)
          _TinyIconButton(
            icon: MetalRateIcons.edit,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _InsightPanel({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final recs = profile.recommendations;
    final tight = recs.where((rec) => rec.guardrail != 'Safe').length;
    final avgMargin = recs.isEmpty
        ? 0.0
        : recs.fold<double>(0, (sum, rec) => sum + rec.marginPercent) /
            recs.length;
    final avgPosition = recs.isEmpty
        ? 0.0
        : recs.fold<double>(
              0,
              (sum, rec) => sum + rec.cheaperThanBrandPercent,
            ) /
            recs.length;

    return _SectionCard(
      icon: MetalRateIcons.engine,
      title: 'Engine Insight',
      subtitle: 'Decision summary for the current profile.',
      color: accent,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Average Margin',
                  value: '${avgMargin.toStringAsFixed(1)}%',
                  color: MetalRateColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: 'Brand Position',
                  value: '${avgPosition.toStringAsFixed(1)}%',
                  color: MetalRateColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NoticeLine(
            text: tight == 0
                ? 'All displayed rates are inside margin guardrails. You can safely apply these to billing after a market check.'
                : '$tight row needs attention. Raise display rate, reduce discount posture, or check supplier premium.',
            color:
                tight == 0 ? MetalRateColors.success : MetalRateColors.warning,
          ),
          const SizedBox(height: 12),
          const _NoticeLine(
            text:
                'Use manual rate only when you want the counter display to override the automatic suggestion.',
            color: MetalRateColors.teal,
          ),
        ],
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

class _StepperField extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final Color color;
  final ValueChanged<double> onChanged;
  final String suffix;
  final bool money;
  final bool editable;

  const _StepperField({
    required this.label,
    required this.value,
    required this.step,
    required this.color,
    required this.onChanged,
    this.suffix = '',
    this.money = false,
    this.editable = true,
  });

  Future<void> _openEditor(BuildContext context) async {
    final input = TextEditingController(
      text: money ? value.round().toString() : value.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MetalRateColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            label,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              prefixText: money ? 'Rs ' : null,
              suffixText: money ? 'per 10g' : suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  input.text.replaceAll(',', '').trim(),
                );
                if (parsed == null) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  parsed.clamp(0, 9999999).toDouble(),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    input.dispose();
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MetalRateStyles.fieldBox,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MetalRateStyles.smallLabel),
                const SizedBox(height: 5),
                Text(
                  money ? _money(value) : '${value.toStringAsFixed(2)}$suffix',
                  style: MetalRateStyles.metricValue,
                ),
              ],
            ),
          ),
          if (editable) ...[
            _RoundButton(
              icon: MetalRateIcons.minus,
              color: color,
              onTap: () =>
                  onChanged((value - step).clamp(0, 9999999).toDouble()),
            ),
            const SizedBox(width: 8),
            _RoundButton(
              icon: MetalRateIcons.plus,
              color: color,
              onTap: () =>
                  onChanged((value + step).clamp(0, 9999999).toDouble()),
            ),
            const SizedBox(width: 8),
            _RoundButton(
              icon: MetalRateIcons.edit,
              color: color,
              onTap: () => _openEditor(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Icon(icon, color: MetalRateColors.teal, size: 15),
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

class _NoticeLine extends StatelessWidget {
  final String text;
  final Color color;

  const _NoticeLine({
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

String _brandPosition(double value) {
  if (value >= 0) {
    return '${value.toStringAsFixed(1)}% below';
  }
  return '${(-value).toStringAsFixed(1)}% above';
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
