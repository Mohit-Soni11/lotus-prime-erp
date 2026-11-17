part of '../metal_rate_detail_screen.dart';

class _HeaderCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  const _HeaderCard({
    required this.profile,
    required this.accent,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final firstPurity = profile.purityPlans.isEmpty
        ? ''
        : _purityLabel(profile.purityPlans.first.label);
    final priceUnit = MetalRatePriceUnit.forMetal(profile.metal);
    String headerRate(double storedRate) {
      final formatted = _money(priceUnit.toMarket(storedRate));
      return profile.metal == MetalRateMetal.silver
          ? '$formatted / kg'
          : formatted;
    }

    final summary = Wrap(spacing: 10, runSpacing: 10, children: [
      _HeaderMetric(
          label: '$firstPurity Local Base',
          value: headerRate(profile.marketBaseRatePer10g),
          color: accent),
      _HeaderMetric(
        label: '$firstPurity Sell',
        value: headerRate(profile.primaryShopRatePer10g),
        color: MetalRateDetailStyles.greenInk,
      ),
      _HeaderMetric(
        label: 'Old Metal Buy',
        value: headerRate(profile.primaryBuyRatePer10g),
        color: MetalRateDetailStyles.orangeInk,
      ),
    ]);
    final actions = isEditing
        ? Wrap(spacing: 8, runSpacing: 8, children: [
            _HeaderButton(
                label: isSaving ? 'Saving…' : 'Save Rates',
                icon: Icons.save_rounded,
                color: MetalRateDetailStyles.greenInk,
                onPressed: isSaving ? null : onSave),
            _HeaderButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                color: MetalRateColors.textBody,
                onPressed: isSaving ? null : onCancel),
            _HeaderButton(
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                color: MetalRateDetailStyles.orangeInk,
                onPressed: isSaving ? null : onReset),
          ])
        : Tooltip(
            message: 'Click to edit rates',
            child: _HeaderButton(
              label: 'LIVE RATE',
              icon: Icons.show_chart_rounded,
              color: MetalRateDetailStyles.greenInk,
              onPressed: onEdit,
            ),
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: MetalRateDetailStyles.panel(),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 1320;
        final identity = Row(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(profile.metal.assetPath,
                width: 88,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 80,
                    color: accent,
                    child: const Icon(Icons.monetization_on_rounded,
                        color: Colors.white))),
          ),
          const SizedBox(width: 17),
          Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${profile.metal.label} Rate Master',
                    style: MetalRateDetailStyles.title),
                const SizedBox(height: 7),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded,
                      size: 15, color: MetalRateColors.textBody),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(
                    'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(profile.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body.copyWith(
                      color: MetalRateColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  )),
                ]),
              ])),
        ]);
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 16),
                summary,
                const SizedBox(height: 14),
                actions,
              ]);
        }
        return Row(children: [
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: identity),
          const SizedBox(width: 16),
          Container(width: 1, height: 66, color: MetalRateColors.cardBorder),
          const SizedBox(width: 20),
          summary,
          const Spacer(),
          const SizedBox(width: 16),
          Container(width: 1, height: 56, color: MetalRateColors.cardBorder),
          const SizedBox(width: 20),
          actions,
        ]);
      }),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('header-metric-$label'),
        constraints: const BoxConstraints(minWidth: 108, minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: MetalRateDetailStyles.tint(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: MetalRateDetailStyles.body.copyWith(
                  color: MetalRateColors.textDark,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(value,
              style: MetalRateDetailStyles.value.copyWith(fontSize: 15)),
        ]),
      );
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  const _HeaderButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}
