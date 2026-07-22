part of '../stock_activity_screen.dart';

class _DateRangeChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DateRangeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DateRangeChip> createState() => _DateRangeChipState();
}

class _DateRangeChipState extends State<_DateRangeChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final color = active ? InvColors.brandGold : InvColors.textMuted;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? InvColors.brandGold
                : _hovered
                    ? InvColors.brandGoldLight
                    : const Color(0xFFFBFAF7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? InvColors.brandGold
                  : InvColors.brandGold.withValues(alpha: 0.25),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: InvColors.brandGold.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 15,
                color: active ? Colors.white : color,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : InvColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetalMovementCard extends StatelessWidget {
  final StockMetalActivitySummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _MetalMovementCard({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(summary.metal);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _metalBackground(summary.metal),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.28),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.24)),
                    ),
                    child: Icon(_metalIcon(summary.metal),
                        color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${summary.metal} Movement',
                            style: _titleText(17)),
                        const SizedBox(height: 3),
                        Text(
                          selected
                              ? 'Timeline focused on this metal'
                              : 'Click to focus movement timeline',
                          style: _mutedText(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: accent,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetalMovementCell(
                      label: 'Inward',
                      value: '${summary.inwardQuantity} pcs',
                      detail: _weight(summary.inwardWeight),
                      accent: InvColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetalMovementCell(
                      label: 'Outward',
                      value: '${summary.outwardQuantity} pcs',
                      detail: _weight(summary.outwardWeight),
                      accent: InvColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetalMovementCell(
                      label: 'Restored',
                      value: '${summary.restoredQuantity} pcs',
                      detail: _weight(summary.restoredWeight),
                      accent: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetalMovementCell(
                      label: 'Net Out',
                      value: '${summary.netOutwardQuantity} pcs',
                      detail: _weight(summary.netOutwardWeight),
                      accent: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetalMovementCell extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color accent;

  const _MetalMovementCell({
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _labelText().copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: _valueText(16).copyWith(color: accent)),
          const SizedBox(height: 2),
          Text(detail, style: _mutedText()),
        ],
      ),
    );
  }
}

class _EmptyMetalMovementState extends StatelessWidget {
  const _EmptyMetalMovementState();

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
                Text('No Metal Movement Found', style: _titleText(15)),
                const SizedBox(height: 3),
                Text(
                  'Only metals with inward, outward or restored stock movement will appear here.',
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: _valueText(14),
      decoration: InputDecoration(
        labelText: 'Search Activity',
        hintText: 'Batch, HUID, supplier, item or invoice',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFFBFAF7),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: InvColors.brandGold, width: 1.4),
        labelStyle: _labelText(),
        hintStyle: _mutedText(),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.white,
      menuMaxHeight: 280,
      borderRadius: BorderRadius.circular(14),
      iconEnabledColor: InvColors.brandGold,
      style: _valueText(13),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: _valueText(13).copyWith(
                  color: InvColors.textDark,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFBFAF7),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: InvColors.brandGold, width: 1.4),
        labelStyle: _labelText(),
      ),
    );
  }
}

class _ActivityRecordCard extends StatelessWidget {
  final StockActivityRecord record;

  const _ActivityRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final accent = _movementAccent(record);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineMarker(
            icon: _movementIcon(record),
            color: accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.businessTitle,
                        style: _titleText(16),
                      ),
                    ),
                    _MovementBadge(record: record),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${record.itemName} • ${record.metalType} • ${record.trackingLabel}',
                  style: _bodyText(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      label: 'Source',
                      value: record.sourceLabel,
                      icon: Icons.receipt_long_rounded,
                    ),
                    if (record.batchCode.isNotEmpty)
                      _InfoPill(
                        label: 'Batch',
                        value: record.batchCode,
                        icon: Icons.inventory_rounded,
                      ),
                    if (record.supplierName.isNotEmpty)
                      _InfoPill(
                        label: 'Supplier',
                        value: record.supplierName,
                        icon: Icons.storefront_rounded,
                      ),
                    _InfoPill(
                      label: 'Quantity',
                      value: record.quantityDelta > 0
                          ? '+${record.quantityDelta}'
                          : record.quantityDelta.toString(),
                      icon: Icons.tag_rounded,
                    ),
                    _InfoPill(
                      label: 'Gross',
                      value: _signedWeight(record.grossWeightDelta),
                      icon: Icons.scale_rounded,
                    ),
                    _InfoPill(
                      label: 'Net',
                      value: _signedWeight(record.netWeightDelta),
                      icon: Icons.balance_rounded,
                    ),
                    if (record.taxType.isNotEmpty)
                      _InfoPill(
                        label: 'Tax',
                        value: record.taxType,
                        icon: Icons.percent_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 125,
            child: Text(
              _date(record.occurredAt),
              textAlign: TextAlign.right,
              style: _mutedText().copyWith(
                color: InvColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
