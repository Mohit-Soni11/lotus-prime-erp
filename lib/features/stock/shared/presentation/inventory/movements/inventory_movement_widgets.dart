part of '../inventory_screen.dart';

class _MovementLedgerEmptyState extends StatelessWidget {
  final String activeCategory;

  const _MovementLedgerEmptyState({required this.activeCategory});

  @override
  Widget build(BuildContext context) {
    final scope = activeCategory == 'All' ? 'stock' : activeCategory;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: InvColors.bodyBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            InvIcons.movementLedger,
            color: InvColors.textHint,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            'No $scope movement recorded yet.',
            style: InvStyles.sectionTitle.copyWith(
              color: InvColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Purchase aur POS activity ke baad ledger yahan auto update hoga.',
            style: InvStyles.cardNote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StockMovementRow extends StatelessWidget {
  final StockMovement movement;
  final NumberFormat wtFormat;

  const _StockMovementRow({
    required this.movement,
    required this.wtFormat,
  });

  @override
  Widget build(BuildContext context) {
    final color = _movementColor(movement.movementType);
    final source = movement.sourceNumber?.trim().isNotEmpty == true
        ? movement.sourceNumber!.trim()
        : movement.sourceId;
    final occurredAt =
        DateFormat('dd MMM, hh:mm a').format(movement.occurredAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.24)),
                ),
                child: Icon(_movementIcon(movement.movementType),
                    color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            movement.itemNameSnapshot,
                            style: InvStyles.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MovementTypeChip(
                          label: _movementLabel(movement.movementType),
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movement.skuSnapshot} • $source • $occurredAt',
                      style: InvStyles.itemSku,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _signedQuantity(movement.quantityDelta),
                style: InvStyles.cardMediumNumber.copyWith(
                  color: color,
                  fontSize: 16,
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
                label: 'Gross',
                value: _signedWeight(movement.grossWeightDelta),
              ),
              _MovementMetricChip(
                label: 'Net',
                value: _signedWeight(movement.netWeightDelta),
              ),
              _MovementMetricChip(
                label: 'Fine',
                value: _signedWeight(movement.fineWeightDelta),
              ),
              _MovementMetricChip(
                label: 'Source',
                value: movement.sourceType,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _movementLabel(String type) {
    return switch (type) {
      'IN' => 'IN',
      'SALE' => 'SALE',
      'SALE_RESTORE' => 'RESTORE',
      _ => type,
    };
  }

  Color _movementColor(String type) {
    return switch (type) {
      'IN' => InvColors.success,
      'SALE' => InvColors.danger,
      'SALE_RESTORE' => InvColors.warning,
      _ => InvColors.textMuted,
    };
  }

  IconData _movementIcon(String type) {
    return switch (type) {
      'IN' => Icons.south_west_rounded,
      'SALE' => Icons.north_east_rounded,
      'SALE_RESTORE' => Icons.settings_backup_restore_rounded,
      _ => Icons.swap_horiz_rounded,
    };
  }

  String _signedQuantity(int quantity) {
    if (quantity > 0) return '+$quantity pcs';
    return '$quantity pcs';
  }

  String _signedWeight(double weight) {
    final value = wtFormat.format(weight);
    if (weight > 0) return '+$value g';
    return '$value g';
  }
}

class _MovementTypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MovementTypeChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: InvStyles.statusBadgeText(color),
      ),
    );
  }
}

class _MovementMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MovementMetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.bodyBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: InvStyles.cardNote,
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: InvStyles.cardNote.copyWith(
                color: InvColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
