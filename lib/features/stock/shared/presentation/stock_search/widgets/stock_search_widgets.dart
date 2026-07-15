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
          _HeroMetric(label: 'Net Weight', value: _grams(summary.netWeight)),
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
                  width: 160,
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
                  onTap: () => _showStockDetail(context, item),
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
                        _SmallPill(label: 'Batch', value: item.batchCode),
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

void _showStockDetail(BuildContext context, StockSearchResult item) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: _StockDetailDossier(item: item),
      );
    },
  );
}

class _StockDetailDossier extends StatelessWidget {
  final StockSearchResult item;

  const _StockDetailDossier({required this.item});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 760),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: InvColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _StockDossierHeader(item: item),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DetailSection(
                              title: 'Stock Identity',
                              icon: Icons.qr_code_2_rounded,
                              children: [
                                _DetailTile(
                                  label: 'HUID / Serial',
                                  value:
                                      item.hasHuid ? item.huid : item.unitCode,
                                ),
                                _DetailTile(
                                    label: 'Unit Code', value: item.unitCode),
                                _DetailTile(
                                    label: 'Batch Code', value: item.batchCode),
                                _DetailTile(
                                    label: 'Piece No.',
                                    value: item.pieceNo.toString()),
                                _DetailTile(
                                    label: 'Status', value: item.status),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _DetailSection(
                              title: 'Item Classification',
                              icon: Icons.category_rounded,
                              children: [
                                _DetailTile(
                                    label: 'Metal',
                                    value: _clean(item.metalType)),
                                _DetailTile(
                                    label: 'Item Type',
                                    value: _clean(item.itemType)),
                                _DetailTile(
                                    label: 'Segment',
                                    value: _clean(item.segment)),
                                _DetailTile(
                                    label: 'Tracking',
                                    value: item.trackingLabel),
                                _DetailTile(
                                    label: 'Created',
                                    value: _formatDateTime(item.createdAt)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DetailSection(
                        title: 'Weight & Purity',
                        icon: Icons.scale_rounded,
                        children: [
                          _DetailTile(
                              label: 'Gross Weight',
                              value: _grams(item.grossWeight)),
                          _DetailTile(
                              label: 'Less Weight',
                              value: _grams(item.lessWeight)),
                          _DetailTile(
                              label: 'Net Weight',
                              value: _grams(item.netWeight)),
                          _DetailTile(
                              label: 'Purity',
                              value: _percent(item.purityPercent)),
                          _DetailTile(
                              label: 'Actual Fine',
                              value: _grams(item.actualFineWeight)),
                          _DetailTile(
                              label: 'Valuation Fine',
                              value: _grams(item.valuationFineWeight)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _PurchaseSection(item: item)),
                          const SizedBox(width: 14),
                          Expanded(child: _SaleSection(item: item)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _StockDossierActions(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockDossierHeader extends StatelessWidget {
  final StockSearchResult item;

  const _StockDossierHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isSold ? InvColors.danger : InvColors.success;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF4C4), Color(0xFFD8B12C)],
        ),
      ),
      child: Row(
        children: [
          _MetalAvatar(metal: item.metalType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B2106),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.metalType.toUpperCase()} • ${item.trackingLabel} • ${item.batchCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D4A15),
                  ),
                ),
              ],
            ),
          ),
          _HeaderPill(
            label: item.status.toUpperCase(),
            value:
                item.isSold ? _formatDateTime(item.soldAt) : 'Ready for sale',
            color: statusColor,
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF2B2106)),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  final StockSearchResult item;

  const _PurchaseSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Purchase Source',
      icon: Icons.receipt_long_rounded,
      children: [
        _DetailTile(label: 'Supplier', value: _clean(item.supplierName)),
        _DetailTile(label: 'Supplier Invoice', value: item.sourceInvoice),
        _DetailTile(label: 'Purchase Tax Type', value: _clean(item.taxType)),
        _DetailTile(
            label: 'Batch Date', value: _formatDateTime(item.createdAt)),
      ],
    );
  }
}

class _SaleSection extends StatelessWidget {
  final StockSearchResult item;

  const _SaleSection({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.isSold && item.soldBillNo.isEmpty) {
      return const _DetailSection(
        title: 'Sale Status',
        icon: Icons.point_of_sale_rounded,
        children: [
          _DetailTile(label: 'Sale Invoice', value: 'Not sold yet'),
          _DetailTile(label: 'Customer', value: 'Stock is currently available'),
          _DetailTile(label: 'Sale Date', value: 'Not recorded'),
          _DetailTile(label: 'Profit Snapshot', value: 'Available after sale'),
        ],
      );
    }

    return _DetailSection(
      title: 'Sale Status',
      icon: Icons.point_of_sale_rounded,
      accent: InvColors.danger,
      background: const Color(0xFFFFF7F7),
      children: [
        _DetailTile(label: 'Sale Invoice', value: _clean(item.soldBillNo)),
        _DetailTile(label: 'Customer', value: _clean(item.soldCustomerName)),
        _DetailTile(
            label: 'Sale Date',
            value: _formatDateTime(item.soldBillDate ?? item.soldAt)),
        _DetailTile(
            label: 'Bill Amount',
            value: _currencyFormat.format(item.soldBillAmount)),
        _DetailTile(
            label: 'Profit Snapshot',
            value: _currencyFormat.format(item.soldProfitAmount)),
      ],
    );
  }
}

class _StockDossierActions extends StatelessWidget {
  final StockSearchResult item;

  const _StockDossierActions({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7EF),
        border: Border(top: BorderSide(color: InvColors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _DossierActionButton(
              label: 'Copy Stock Card',
              icon: Icons.copy_rounded,
              onTap: () => _copyStockCard(context, item),
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'Preview PDF',
              icon: Icons.visibility_rounded,
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => _StockCardPdfPreviewScreen(item: item),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'Print Card',
              icon: Icons.print_rounded,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                try {
                  await _printStockCard(item);
                } catch (error) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Print failed: $error'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                }
              },
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'Export PDF',
              icon: Icons.picture_as_pdf_rounded,
              primary: true,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                try {
                  await _exportStockCard(item);
                } catch (error) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $error'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                }
              },
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'View Supplier',
              icon: Icons.storefront_rounded,
              enabled: item.supplierId != null && item.supplierId! > 0,
              onTap: () {
                final router = GoRouter.of(context);
                final path = RoutePaths.supplierProfileFor(item.supplierId!);
                Navigator.of(context).pop();
                router.push(path);
              },
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'Open Inventory',
              icon: Icons.inventory_2_rounded,
              onTap: () {
                final router = GoRouter.of(context);
                final path = Uri(
                  path: RoutePaths.stockInventory,
                  queryParameters: {
                    'metal': item.metalType,
                    'batch': item.batchCode,
                  },
                ).toString();
                Navigator.of(context).pop();
                router.push(path);
              },
            ),
            const SizedBox(width: 10),
            _DossierActionButton(
              label: 'Stock Activity',
              icon: Icons.timeline_rounded,
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(RoutePaths.stockActivity);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color accent;
  final Color background;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accent = InvColors.brandGold,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: icon, accent: accent),
              const SizedBox(width: 10),
              Text(title, style: InvStyles.sectionTitle.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  InvStyles.itemFieldLabel.copyWith(color: InvColors.textBody)),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'Not recorded' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: InvStyles.itemFieldValue.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2B2106),
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  const _DossierActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? InvColors.brandGold : Colors.white;
    final fg = primary ? Colors.white : InvColors.textDark;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primary ? InvColors.brandGold : InvColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _copyStockCard(
    BuildContext context, StockSearchResult item) async {
  final lines = [
    'Stock Card',
    'Item: ${item.displayName}',
    'Status: ${item.status}',
    'Metal: ${item.metalType}',
    'HUID / Serial: ${item.hasHuid ? item.huid : item.unitCode}',
    'Unit Code: ${item.unitCode}',
    'Batch Code: ${item.batchCode}',
    'Supplier: ${_clean(item.supplierName)}',
    'Supplier Invoice: ${item.sourceInvoice}',
    'Gross Weight: ${_grams(item.grossWeight)}',
    'Net Weight: ${_grams(item.netWeight)}',
    'Purity: ${_percent(item.purityPercent)}',
    'Actual Fine: ${_grams(item.actualFineWeight)}',
    'Valuation Fine: ${_grams(item.valuationFineWeight)}',
    if (item.soldBillNo.trim().isNotEmpty) 'Sale Invoice: ${item.soldBillNo}',
    if (item.soldCustomerName.trim().isNotEmpty)
      'Customer: ${item.soldCustomerName}',
  ];
  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
  if (!context.mounted) return;
  _showActionNotice(context, 'Stock card copied.');
}

void _showActionNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: InvColors.shellPanelBg,
      ),
    );
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
  return '${_dateFormat.format(value)} • ${_timeFormat.format(value)}';
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
