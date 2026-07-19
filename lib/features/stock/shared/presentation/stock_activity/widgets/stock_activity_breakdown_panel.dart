part of '../stock_activity_screen.dart';

class _MovementBreakdownPanel extends StatelessWidget {
  final List<StockActivityBreakdownSummary> summaries;
  final String selectedMetal;

  const _MovementBreakdownPanel({
    required this.summaries,
    required this.selectedMetal,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSummaries = summaries
        .where(
          (summary) =>
              selectedMetal == 'All' ||
              summary.metal.toLowerCase() == selectedMetal.toLowerCase(),
        )
        .where((summary) => summary.hasMovement)
        .toList(growable: false);

    return _ActivitySurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _SectionIcon(
                  Icons.splitscreen_rounded, InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Movement Breakdown', style: _titleText(18)),
                    const SizedBox(height: 2),
                    Text(
                      selectedMetal == 'All'
                          ? 'Gold by grade, silver by item type and other metals by item group.'
                          : '$selectedMetal movement arranged by the right business grouping.',
                      style: _mutedText(),
                    ),
                  ],
                ),
              ),
              _SoftBadge('${visibleSummaries.length} groups'),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleSummaries.isEmpty)
            const _EmptyMovementBreakdownState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1480
                    ? 3
                    : constraints.maxWidth >= 980
                        ? 2
                        : 1;
                const spacing = 14.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final summary in visibleSummaries)
                      SizedBox(
                        width: width,
                        child: _MovementBreakdownCard(summary: summary),
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

class _MovementBreakdownCard extends StatelessWidget {
  final StockActivityBreakdownSummary summary;

  const _MovementBreakdownCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(summary.metal);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _metalBackground(summary.metal),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(_breakdownIcon(summary), color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCase(summary.groupLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleText(16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${summary.metal} ${summary.groupKind} movement',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _mutedText(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BreakdownMetric(
                    width: width,
                    label: 'Inward',
                    value: '${summary.inwardQuantity} pcs',
                    detail: _weight(summary.inwardWeight),
                    accent: InvColors.success,
                  ),
                  _BreakdownMetric(
                    width: width,
                    label: 'Outward',
                    value: '${summary.outwardQuantity} pcs',
                    detail: _weight(summary.outwardWeight),
                    accent: InvColors.danger,
                  ),
                  _BreakdownMetric(
                    width: width,
                    label: 'Restored',
                    value: '${summary.restoredQuantity} pcs',
                    detail: _weight(summary.restoredWeight),
                    accent: const Color(0xFF2563EB),
                  ),
                  _BreakdownMetric(
                    width: width,
                    label: 'Net Out',
                    value: '${summary.netOutwardQuantity} pcs',
                    detail: _weight(summary.netOutwardWeight),
                    accent: accent,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _BreakdownFooter(summary: summary),
        ],
      ),
    );
  }
}

class _BreakdownMetric extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String detail;
  final Color accent;

  const _BreakdownMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _labelText().copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _valueText(15).copyWith(color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _mutedText(),
          ),
        ],
      ),
    );
  }
}

class _BreakdownFooter extends StatelessWidget {
  final StockActivityBreakdownSummary summary;

  const _BreakdownFooter({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterFact(
              label: summary.groupKind == 'Grade' ? 'Item Types' : 'Grades',
              value: summary.groupKind == 'Grade'
                  ? '${summary.itemTypeCount}'
                  : '${summary.gradeCount}',
            ),
          ),
          const _MiniDivider(),
          Expanded(
            child: _FooterFact(
              label: 'Companies',
              value: '${summary.companyCount}',
            ),
          ),
          const _MiniDivider(),
          Expanded(
            child: _FooterFact(
              label: 'Movements',
              value: '${summary.totalMovementQuantity} pcs',
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterFact extends StatelessWidget {
  final String label;
  final String value;

  const _FooterFact({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelText().copyWith(fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _valueText(12.5),
        ),
      ],
    );
  }
}

class _MiniDivider extends StatelessWidget {
  const _MiniDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE8DDC9),
    );
  }
}

class _EmptyMovementBreakdownState extends StatelessWidget {
  const _EmptyMovementBreakdownState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        children: [
          const _SectionIcon(Icons.inventory_2_outlined, InvColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Breakdown Found', style: _titleText(15)),
                const SizedBox(height: 3),
                Text(
                  'Grade and item-type movement cards will appear once matching activity is available.',
                  style: _mutedText(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _breakdownIcon(StockActivityBreakdownSummary summary) {
  if (summary.groupKind == 'Grade') return Icons.verified_rounded;
  if (summary.metal.toLowerCase() == 'silver') return Icons.category_rounded;
  return Icons.inventory_2_rounded;
}

String _titleCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Stock Group';
  return text.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
