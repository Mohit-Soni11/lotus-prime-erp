part of '../stock_search_screen.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('dd MMM yyyy');
final _timeFormat = DateFormat('hh:mm a');

class _SearchHero extends StatelessWidget {
  final StockSearchSummary summary;

  const _SearchHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF4C4), Color(0xFFD8B12C)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: InvColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeroIcon(icon: Icons.manage_search_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Search Center',
                  style: GoogleFonts.manrope(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B2106),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Search HUID, unit code, batch, item, supplier, invoice or weight from one professional inventory desk.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4A15),
                  ),
                ),
              ],
            ),
          ),
          _HeroMetric(
              label: 'Available', value: '${summary.availableUnits} pcs'),
          const SizedBox(width: 12),
          _HeroMetric(label: 'Total Weight', value: _grams(summary.netWeight)),
          const SizedBox(width: 12),
          _HeroMetric(
            label: 'Available Weight',
            value: _grams(summary.availableWeight),
          ),
          const SizedBox(width: 12),
          _HeroMetric(
            label: 'Sold Weight',
            value: _grams(summary.soldWeight),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterPanel extends StatelessWidget {
  final StockSearchController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _SearchFilterPanel({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InvStyles.cardDecoration,
      child: LayoutBuilder(builder: (context, constraints) {
        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: InvColors.textDark,
          ),
          decoration: _inputDecoration(
            icon: Icons.search_rounded,
            hint: 'Search HUID, item, batch, weight, supplier or invoice',
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown(
                  value: controller.statusFilter,
                  values: StockSearchController.statusFilters,
                  labelFor: StockSearchController.statusFilterLabel,
                  width: 170,
                  onChanged: controller.setStatusFilter,
                ),
                _FilterDropdown(
                  value: controller.metalFilter,
                  values: StockSearchController.metalFilters,
                  labelFor: StockSearchController.metalFilterLabel,
                  width: 160,
                  onChanged: controller.setMetalFilter,
                ),
                _FilterDropdown(
                  value: controller.trackingFilter,
                  values: StockSearchController.trackingFilters,
                  labelFor: StockSearchController.trackingFilterLabel,
                  width: 190,
                  onChanged: controller.setTrackingFilter,
                ),
                _FilterDropdown(
                  value: controller.sortMode,
                  values: StockSearchController.sortModes,
                  labelFor: (value) => value,
                  width: 170,
                  onChanged: controller.setSortMode,
                ),
                _ClearSearchButton(
                  enabled: controller.hasActiveFilters,
                  onTap: controller.clearFilters,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  final StockSearchController controller;

  const _SearchResultsPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                const _SectionIcon(icon: Icons.inventory_2_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search Results',
                          style: InvStyles.sectionTitle.copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(
                        'Live stock units with batch, supplier, value and tracking status.',
                        style: InvStyles.pageSubtitle
                            .copyWith(color: InvColors.textBody),
                      ),
                    ],
                  ),
                ),
                _ResultCount(count: controller.results.length),
              ],
            ),
          ),
          const Divider(height: 1, color: InvColors.divider),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.errorMessage != null)
            _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Search Failed',
              message: controller.errorMessage!,
            )
          else if (controller.results.isEmpty)
            const _EmptyState(
              icon: Icons.manage_search_rounded,
              title: 'No Stock Found',
              message:
                  'Try another HUID, batch, item name, supplier, invoice or weight.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: controller.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.results[index];
                return _StockSearchCard(
                  item: item,
                  onTap: () => _showStockDetail(
                    context,
                    item,
                    onChanged: controller.load,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StockSearchCard extends StatefulWidget {
  final StockSearchResult item;
  final VoidCallback onTap;

  const _StockSearchCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_StockSearchCard> createState() => _StockSearchCardState();
}

class _StockSearchCardState extends State<_StockSearchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSold = item.isSold;
    final cardAccent = isSold ? InvColors.danger : InvColors.brandGold;
    final cardBg = isSold
        ? const Color(0xFFFFF7F7)
        : _hovered
            ? const Color(0xFFFFFBEB)
            : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered || isSold ? cardAccent : InvColors.cardBorder,
              width: _hovered || isSold ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _MetalAvatar(metal: item.metalType),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: InvStyles.itemName.copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_clean(item.itemType)} • ${_clean(item.segment)} • ${item.trackingLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          InvStyles.itemSku.copyWith(color: InvColors.textBody),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallPill(
                            label: item.hasHuid ? 'HUID' : 'Unit Code',
                            value: item.hasHuid ? item.huid : item.unitCode),
                        _SmallPill(
                          label: 'Batch',
                          value: item.inventoryBatchCode,
                        ),
                        _SmallPill(
                            label: 'Supplier',
                            value: _clean(item.supplierName)),
                        if (item.isSold && item.soldBillNo.trim().isNotEmpty)
                          _SmallPill(
                              label: 'Sale Invoice',
                              value: item.soldBillNo.trim()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ResultMetric(
                  label: 'Net Weight',
                  value: _grams(item.netWeight),
                  accent: InvColors.success),
              _ResultMetric(
                  label: 'Purity',
                  value: _percent(item.purityPercent),
                  accent: InvColors.brandGold),
              _ResultMetric(
                  label: 'Actual Fine',
                  value: _grams(item.actualFineWeight),
                  accent: InvColors.success),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded,
                  color: InvColors.brandGold, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> values;
  final String Function(String value) labelFor;
  final double width;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.values,
    required this.labelFor,
    required this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: InvColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded,
                color: InvColors.brandGold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  iconEnabledColor: InvColors.brandGold,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: InvColors.textDark,
                  ),
                  selectedItemBuilder: (context) {
                    return values
                        .map(
                          (item) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              labelFor(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList();
                  },
                  items: values
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(labelFor(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearSearchButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ClearSearchButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFFF7F7) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: enabled
                  ? InvColors.danger.withValues(alpha: 0.28)
                  : InvColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                color: enabled ? InvColors.danger : InvColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: enabled ? InvColors.danger : InvColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ResultMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  InvStyles.itemFieldLabel.copyWith(color: InvColors.textBody)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: InvStyles.itemFieldValue.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6B4E00),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2B2106),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Icon(icon, color: const Color(0xFF5D4300), size: 29),
    );
  }
}

class _MetalAvatar extends StatelessWidget {
  final String metal;

  const _MetalAvatar({required this.metal});

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(metal);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Icon(_metalIcon(metal), color: color, size: 25),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final String value;

  const _SmallPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 11, color: InvColors.textBody),
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: InvColors.textMuted),
            ),
            TextSpan(
              text: value.isEmpty ? 'Not recorded' : value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: InvColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSold = status.toLowerCase() == 'sold';
    final color = isSold ? InvColors.danger : InvColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  final int count;

  const _ResultCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: InvColors.metalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InvColors.metalBorder),
      ),
      child: Text(
        '$count records',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: InvColors.goldChipText,
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _SectionIcon({
    required this.icon,
    this.accent = InvColors.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: accent, size: 21),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(54),
      child: Column(
        children: [
          _SectionIcon(icon: icon),
          const SizedBox(height: 14),
          Text(title, style: InvStyles.pageTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: InvStyles.pageSubtitle.copyWith(color: InvColors.textBody),
          ),
        ],
      ),
    );
  }
}

class _ShellIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ShellIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ShellIconButton> createState() => _ShellIconButtonState();
}

class _ShellIconButtonState extends State<_ShellIconButton> {
  bool _hovered = false;

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
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? InvColors.shellBg
                : InvColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered ? InvColors.brandGold : InvColors.shellBorder,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? InvColors.brandGold : InvColors.shellTextTitle,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _AppBarDivider extends StatelessWidget {
  const _AppBarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: InvColors.shellBorder);
  }
}

class _OnlineBadge extends StatelessWidget {
  final Animation<double> pulse;

  const _OnlineBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: InvColors.onlineGreen.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              return Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: InvColors.onlineGreen
                      .withValues(alpha: 0.14 + (pulse.value * 0.18)),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: InvColors.onlineGreen,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: InvColors.onlineGreen,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required IconData icon,
  required String hint,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: InvColors.textHint,
    ),
    prefixIcon: Icon(icon, color: InvColors.brandGold, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: InvColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: InvColors.brandGold, width: 1.4),
    ),
  );
}

String _grams(double value) => '${value.toStringAsFixed(3)} g';

String _percent(double value) {
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}%';
  return '${value.toStringAsFixed(2)}%';
}

String _clean(String value) {
  final cleaned = value.trim();
  return cleaned.isEmpty ? 'Not recorded' : cleaned;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not recorded';
  return '${_dateFormat.format(value)}, ${_timeFormat.format(value)}';
}

String _signedQuantity(int value) {
  if (value > 0) return '+$value pcs';
  if (value < 0) return '$value pcs';
  return '0 pcs';
}

String _signedWeight(double value) {
  if (value > 0) return '+${_grams(value)}';
  if (value < 0) return '-${_grams(value.abs())}';
  return _grams(0);
}

String _stockLifecycleLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'sold':
      return 'Sold';
    case 'reserved':
      return 'Reserved';
    case 'on hold':
    case 'hold':
      return 'On Hold';
    case 'returned':
      return 'Returned';
    case 'transferred':
      return 'Transferred';
    case 'damaged':
      return 'Damaged';
    case 'with karigar':
      return 'With Karigar';
    case 'archived':
    case 'deleted':
      return 'Archived';
    default:
      return 'Available';
  }
}

Color _stockLifecycleColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'sold':
      return InvColors.danger;
    case 'reserved':
    case 'on hold':
    case 'hold':
      return const Color(0xFFF59E0B);
    case 'returned':
    case 'transferred':
      return const Color(0xFF2563EB);
    case 'damaged':
    case 'archived':
    case 'deleted':
      return const Color(0xFF64748B);
    case 'with karigar':
      return const Color(0xFF7C3AED);
    default:
      return InvColors.success;
  }
}

Color _movementColor(StockUnitHistoryEvent event) {
  if (event.isSale) return InvColors.danger;
  if (event.isRestore) return const Color(0xFF2563EB);
  if (event.isInbound) return InvColors.success;
  return InvColors.brandGold;
}

IconData _movementIcon(StockUnitHistoryEvent event) {
  if (event.isSale) return Icons.point_of_sale_rounded;
  if (event.isRestore) return Icons.restore_rounded;
  if (event.isInbound) return Icons.add_business_rounded;
  return Icons.timeline_rounded;
}

Color _metalColor(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return const Color(0xFF64748B);
    case 'diamond':
      return const Color(0xFF0EA5E9);
    case 'platinum':
      return const Color(0xFF475569);
    default:
      return InvColors.brandGold;
  }
}

IconData _metalIcon(String metal) {
  switch (metal.toLowerCase()) {
    case 'diamond':
      return Icons.diamond_rounded;
    case 'silver':
      return Icons.circle_outlined;
    case 'platinum':
      return Icons.radio_button_checked_rounded;
    default:
      return Icons.workspace_premium_rounded;
  }
}
