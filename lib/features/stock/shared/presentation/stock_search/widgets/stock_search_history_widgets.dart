part of '../stock_search_screen.dart';

class _UnitMovementHistorySection extends StatefulWidget {
  final StockSearchResult item;

  const _UnitMovementHistorySection({required this.item});

  @override
  State<_UnitMovementHistorySection> createState() =>
      _UnitMovementHistorySectionState();
}

class _UnitMovementHistorySectionState
    extends State<_UnitMovementHistorySection> {
  late final Future<List<StockUnitHistoryEvent>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture =
        StockUnitHistoryController(AppDatabase()).loadFor(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvColors.brandGold.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                icon: Icons.account_tree_rounded,
                accent: InvColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unit Movement History',
                  style: InvStyles.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              _LifecycleBadge(status: widget.item.status),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<StockUnitHistoryEvent>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _UnitMovementLoadingState();
              }
              if (snapshot.hasError) {
                return const _UnitMovementMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Movement History Unavailable',
                  message: 'This unit history could not be loaded right now.',
                );
              }
              final events = snapshot.data ?? const <StockUnitHistoryEvent>[];
              if (events.isEmpty) {
                return const _UnitMovementMessage(
                  icon: Icons.timeline_rounded,
                  title: 'No Movement Recorded',
                  message:
                      'This unit has no linked intake or sale movement yet.',
                );
              }
              return Column(
                children: [
                  for (int index = 0; index < events.length; index++) ...[
                    _UnitMovementTimelineRow(
                      event: events[index],
                      isLast: index == events.length - 1,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LifecycleBadge extends StatelessWidget {
  final String status;

  const _LifecycleBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _stockLifecycleLabel(status);
    final color = _stockLifecycleColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _UnitMovementTimelineRow extends StatelessWidget {
  final StockUnitHistoryEvent event;
  final bool isLast;

  const _UnitMovementTimelineRow({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = _movementColor(event);
    final icon = _movementIcon(event);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: InvColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: InvColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.businessStatus,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: InvColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(event.occurredAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MovementMetricChip(
                      label: 'Source',
                      value: event.sourceLabel,
                      icon: Icons.receipt_long_rounded,
                    ),
                    _MovementMetricChip(
                      label: event.isSale ? 'Customer' : 'Supplier',
                      value: event.partyLabel,
                      icon: event.isSale
                          ? Icons.person_rounded
                          : Icons.storefront_rounded,
                    ),
                    _MovementMetricChip(
                      label: 'Quantity',
                      value: _signedQuantity(event.quantityDelta),
                      icon: Icons.numbers_rounded,
                    ),
                    _MovementMetricChip(
                      label: 'Net Weight',
                      value: _signedWeight(event.netWeightDelta),
                      icon: Icons.scale_rounded,
                    ),
                    _MovementMetricChip(
                      label: 'Fine Weight',
                      value: _signedWeight(event.fineWeightDelta),
                      icon: Icons.verified_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MovementMetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: InvColors.brandGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitMovementLoadingState extends StatelessWidget {
  const _UnitMovementLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 86,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: InvColors.brandGold,
          ),
        ),
      ),
    );
  }
}

class _UnitMovementMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _UnitMovementMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: InvColors.brandGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
