import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_grade_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';

import 'widgets/metal_valuation_app_bar.dart';
import 'widgets/metal_valuation_tokens.dart';

class MetalValuationGradeScreen extends StatefulWidget {
  final String metalType;
  final VoidCallback? onBack;

  const MetalValuationGradeScreen({
    super.key,
    required this.metalType,
    this.onBack,
  });

  @override
  State<MetalValuationGradeScreen> createState() =>
      _MetalValuationGradeScreenState();
}

class _MetalValuationGradeScreenState extends State<MetalValuationGradeScreen> {
  late final MetalValuationGradeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MetalValuationGradeController(metalType: widget.metalType)
      ..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metalLabel = titleCase(widget.metalType);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: MetalValuationColors.canvas,
          appBar: MetalValuationAppBar(
            title: '${metalLabel.toUpperCase()} MOVEMENT GRADES',
            onBack: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          body: Stack(
            children: [
              _GradeBody(
                metalLabel: metalLabel,
                snapshot: _controller.snapshot,
                hasError: _controller.hasError,
                errorMessage: _controller.errorMessage,
                onRetry: _controller.refresh,
              ),
              if (_controller.isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color:
                          MetalValuationColors.canvas.withValues(alpha: 0.34),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 18),
                      child: const CircularProgressIndicator(
                        color: MetalValuationColors.goldDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradeBody extends StatelessWidget {
  final String metalLabel;
  final MetalValuationGradeSnapshot snapshot;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _GradeBody({
    required this.metalLabel,
    required this.snapshot,
    required this.hasError,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Center(
        child: _MessagePanel(
          icon: Icons.error_outline_rounded,
          title: 'Unable To Load $metalLabel Grades',
          message: errorMessage ?? 'Refresh the valuation desk and try again.',
          action: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _GradeHero(metalLabel: metalLabel, snapshot: snapshot),
          ),
        ),
        if (snapshot.grades.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: _MessagePanel(
                icon: Icons.layers_clear_rounded,
                title: 'No $metalLabel Movement Found',
                message:
                    'Add stock or create sales bills. Grade-wise valuation cards will appear automatically.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            sliver: SliverToBoxAdapter(
              child: _GradeGrid(
                metalLabel: metalLabel,
                grades: snapshot.grades,
              ),
            ),
          ),
      ],
    );
  }
}

class _GradeHero extends StatelessWidget {
  final String metalLabel;
  final MetalValuationGradeSnapshot snapshot;

  const _GradeHero({
    required this.metalLabel,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _GradeTone.forMetal(metalLabel);
    final isSilver = metalLabel.toLowerCase() == 'silver';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tone.gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: tone.accent.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final metrics = [
            _HeroMetricData('Groups', '${snapshot.gradeCount}'),
            _HeroMetricData(
                'Available Wt', formatGram(snapshot.availableNetWeight)),
            _HeroMetricData('Sold Wt', formatGram(snapshot.soldNetWeight)),
            _HeroMetricData('Margin', formatPercent(snapshot.marginPercent)),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MetalValuationMetalImage(
                    metalType: metalLabel,
                    borderColor: Colors.white,
                    fallbackColor: tone.accent,
                    size: 56,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSilver
                              ? '$metalLabel Movement Items'
                              : '$metalLabel Movement Grades',
                          style: MetalValuationText.sectionTitle.copyWith(
                            color: tone.text,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isSilver
                              ? 'Sold and live valuation grouped by silver item movement.'
                              : 'Sold and live valuation grouped by purity grade movement.',
                          style: MetalValuationText.body.copyWith(
                            color: tone.text.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: compact
                          ? (constraints.maxWidth - 10) / 2
                          : (constraints.maxWidth - 30) / 4,
                      child: _HeroMetric(metric: metric, tone: tone),
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

class _GradeGrid extends StatelessWidget {
  final String metalLabel;
  final List<MetalValuationGradeRow> grades;

  const _GradeGrid({
    required this.metalLabel,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _GradeTone.forMetal(metalLabel);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1240
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 760
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final grade in grades)
              SizedBox(
                width: width,
                child: _GradeCard(grade: grade, tone: tone),
              ),
          ],
        );
      },
    );
  }
}

class _GradeCard extends StatelessWidget {
  final MetalValuationGradeRow grade;
  final _GradeTone tone;

  const _GradeCard({
    required this.grade,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final active = grade.soldUnits > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  active ? Icons.trending_up_rounded : Icons.inventory_rounded,
                  color: tone.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titleCase(grade.gradeLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.sectionTitle.copyWith(
                    fontSize: 19,
                  ),
                ),
              ),
              _GradeStatusPill(label: grade.statusLabel, active: active),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GradeMetricBand(
                  label: 'Available',
                  value: formatGram(grade.availableNetWeight),
                  helper: '${grade.availableUnits} units',
                  color: MetalValuationColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradeMetricBand(
                  label: 'Sold',
                  value: formatGram(grade.soldNetWeight),
                  helper: '${grade.soldUnits} units',
                  color: active
                      ? MetalValuationColors.red
                      : MetalValuationColors.softInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GradeFact(
                  label: 'Available Cost',
                  value: formatMoney(grade.availableCost),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradeFact(
                  label: 'Sold Cost',
                  value: formatMoney(grade.soldCost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GradeFact(
                  label: 'Sale Value',
                  value: formatMoney(grade.saleValue),
                  valueColor: tone.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradeFact(
                  label: 'Profit',
                  value: formatMoney(grade.profit),
                  valueColor: grade.profit >= 0
                      ? MetalValuationColors.green
                      : MetalValuationColors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradeFact(
                  label: 'Margin',
                  value: formatPercent(grade.marginPercent),
                  valueColor: grade.marginPercent >= 0
                      ? MetalValuationColors.green
                      : MetalValuationColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeMetricBand extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _GradeMetricBand({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.label.copyWith(
              color: MetalValuationColors.mutedInk,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _GradeFact({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MetalValuationColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.body.copyWith(
              color: valueColor ?? MetalValuationColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeStatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _GradeStatusPill({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? MetalValuationColors.goldDark : MetalValuationColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: MetalValuationText.label.copyWith(color: color),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final _HeroMetricData metric;
  final _GradeTone tone;

  const _HeroMetric({
    required this.metric,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: MetalValuationText.label),
          const SizedBox(height: 5),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              color: tone.text,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricData {
  final String label;
  final String value;

  const _HeroMetricData(this.label, this.value);
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MetalValuationColors.goldDark, size: 36),
          const SizedBox(height: 12),
          Text(title, style: MetalValuationText.sectionTitle),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: MetalValuationText.body.copyWith(
              color: MetalValuationColors.mutedInk,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _GradeTone {
  final List<Color> gradient;
  final Color accent;
  final Color text;

  const _GradeTone({
    required this.gradient,
    required this.accent,
    required this.text,
  });

  static _GradeTone forMetal(String metalType) {
    switch (metalType.trim().toLowerCase()) {
      case 'silver':
        return const _GradeTone(
          gradient: [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
          accent: Color(0xFF607D8B),
          text: Color(0xFF1F2937),
        );
      case 'platinum':
        return const _GradeTone(
          gradient: [Color(0xFFF8FAFC), Color(0xFFE5E7EB)],
          accent: Color(0xFF475569),
          text: Color(0xFF111827),
        );
      default:
        return const _GradeTone(
          gradient: [Color(0xFFFFF4BF), Color(0xFFE0B11F)],
          accent: Color(0xFFB8860B),
          text: Color(0xFF3B2A08),
        );
    }
  }
}
