part of '../inventory_screen.dart';

extension _InventoryDetailSections on _InventoryScreenState {
  Widget _buildPageHeader() {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(InvStrings.pageTitle, style: InvStyles.pageTitle),
              const SizedBox(height: 4),
              Text(InvStrings.pageSubtitle, style: InvStyles.pageSubtitle),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: InvColors.brandGoldLight,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: InvColors.brandGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                InvIcons.calendar,
                size: 11,
                color: InvColors.brandGold,
              ),
              const SizedBox(width: 6),
              Text(
                today,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: InvColors.brandGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SUMMARY CARDS (Opening + Closing side by side)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildSummaryCards() {
    final s = _ctrl.stats;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opening Stock
        Expanded(
          child: _SummaryCard(
            icon: InvIcons.openingStock,
            label: InvStrings.cardOpening,
            note: InvStrings.cardOpeningNote,
            accentColor: InvColors.openingAccent,
            bgColor: InvColors.openingBg,
            borderColor: InvColors.openingBorder,
            bigNumber: '${s.openingCount}',
            bigUnit: 'pcs',
            row1Label: InvStrings.lblWeight,
            row1Value: '${_wt.format(s.openingWeight)} g',
            row2Label: InvStrings.lblValue,
            row2Value: _rupee.format(s.openingValue),
          ),
        ),
        const SizedBox(width: 14),
        // Closing Stock
        Expanded(
          child: _SummaryCard(
            icon: InvIcons.closingStock,
            label: InvStrings.cardClosing,
            note: InvStrings.cardClosingNote,
            accentColor: InvColors.closingAccent,
            bgColor: InvColors.closingBg,
            borderColor: InvColors.closingBorder,
            bigNumber: '${s.closingCount}',
            bigUnit: 'pcs',
            row1Label: InvStrings.lblWeight,
            row1Value: '${_wt.format(s.closingWeight)} g',
            row2Label: InvStrings.lblValue,
            row2Value: _rupee.format(s.closingValue),
            // Delta chip
            deltaWidget: _MovementChip(added: s.todayAdded, sold: s.todaySold),
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // METAL HOLDINGS CARD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildMetalHoldingsCard() {
    final s = _ctrl.stats;
    return Container(
      decoration: InvStyles.summaryCard(
        InvColors.metalAccent,
        InvColors.metalBg,
        InvColors.metalBorder,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: InvColors.metalAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  InvIcons.metalHoldings,
                  color: InvColors.metalAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InvStrings.cardMetal,
                    style: InvStyles.sectionTitle.copyWith(
                      color: InvColors.textDark,
                    ),
                  ),
                  Text(InvStrings.cardMetalNote, style: InvStyles.cardNote),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metal chips row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (s.goldCount > 0)
                _MetalHoldingChip(
                  icon: InvIcons.catGold,
                  iconColor: InvColors.brandGold,
                  label: InvStrings.lblGold,
                  count: s.goldCount,
                  weight: s.goldWeight,
                  value: s.goldValue,
                  bg: InvColors.goldChipBg,
                  textColor: InvColors.goldChipText,
                  border: InvColors.goldChipBorder,
                  rupeeFormat: _rupee,
                  wtFormat: _wt,
                ),
              if (s.silverCount > 0)
                _MetalHoldingChip(
                  icon: InvIcons.catSilver,
                  iconColor: const Color(0xFF94A3B8),
                  label: InvStrings.lblSilver,
                  count: s.silverCount,
                  weight: s.silverWeight,
                  value: s.silverValue,
                  bg: InvColors.silverChipBg,
                  textColor: InvColors.silverChipText,
                  border: InvColors.silverChipBorder,
                  rupeeFormat: _rupee,
                  wtFormat: _wt,
                ),
              if (s.diamondCount > 0)
                _MetalHoldingChip(
                  icon: InvIcons.catDiamond,
                  iconColor: const Color(0xFF3B82F6),
                  label: InvStrings.lblDiamond,
                  count: s.diamondCount,
                  weight: 0,
                  value: s.diamondValue,
                  bg: InvColors.diamondChipBg,
                  textColor: InvColors.diamondChipText,
                  border: InvColors.diamondChipBorder,
                  rupeeFormat: _rupee,
                  wtFormat: _wt,
                  showWeight: false,
                ),
              if (s.platinumCount > 0)
                _MetalHoldingChip(
                  icon: InvIcons.catPlatinum,
                  iconColor: const Color(0xFF8B5CF6),
                  label: InvStrings.lblPlatinum,
                  count: s.platinumCount,
                  weight: s.platinumWeight,
                  value: 0,
                  bg: InvColors.platinumChipBg,
                  textColor: InvColors.platinumChipText,
                  border: InvColors.platinumChipBorder,
                  rupeeFormat: _rupee,
                  wtFormat: _wt,
                  showValue: false,
                ),
              // Empty state
              if (s.goldCount == 0 &&
                  s.silverCount == 0 &&
                  s.diamondCount == 0 &&
                  s.platinumCount == 0)
                Text(
                  'No metal holdings are available yet.',
                  style: InvStyles.cardNote,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION HEADER + CATEGORY FILTER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildMovementLedgerPanel() {
    return Container(
      decoration: InvStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: InvColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  InvIcons.movementLedger,
                  color: InvColors.brandGold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      InvStrings.secMovementLedger,
                      style: InvStyles.sectionTitle,
                    ),
                    Text(
                      InvStrings.secMovementSubtitle,
                      style: InvStyles.cardNote,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<StockMovement>>(
            stream: _ctrl.watchRecentMovements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: InvColors.brandGold,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final movements = snapshot.data ?? [];
              if (movements.isEmpty) {
                return _MovementLedgerEmptyState(
                  activeCategory: _ctrl.activeCategory,
                );
              }

              return Column(
                children: [
                  for (int index = 0; index < movements.length; index++) ...[
                    _StockMovementRow(
                      movement: movements[index],
                      wtFormat: _wt,
                    ),
                    if (index < movements.length - 1)
                      const Divider(height: 18, color: InvColors.divider),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: InvColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            InvIcons.stockList,
            color: InvColors.brandGold,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(InvStrings.secStockList, style: InvStyles.sectionTitle),
            Text(InvStrings.secListSubtitle, style: InvStyles.cardNote),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: InventoryController.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = InventoryController.categories[i];
          final isActive = _ctrl.activeCategory == cat;
          return GestureDetector(
            onTap: () {
              _selectInventoryCategory(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: isActive
                  ? InvStyles.chipActive(InvColors.shellBg)
                  : InvStyles.chipInactive,
              alignment: Alignment.center,
              child: Text(
                cat,
                style: isActive
                    ? InvStyles.chipActiveText
                    : InvStyles.chipInactiveText,
              ),
            ),
          );
        },
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // STOCK ITEMS LIST (Live StreamBuilder)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildStockList() {
    return StreamBuilder<List<StockItem>>(
      stream: _ctrl.watchItems(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildListLoading();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState();
        }
        if (_ctrl.activeCategory == StockCategory.gold.label) {
          return _buildGoldGroupedList(items);
        }
        return Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _StockItemCard(
                item: items[i],
                rupeeFormat: _rupee,
                wtFormat: _wt,
              ),
              if (i < items.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildListLoading() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: InvStyles.cardDecoration.copyWith(
            color: InvColors.cardBg.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: InvColors.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: InvColors.cardBorder),
            ),
            child: const Icon(
              InvIcons.emptyState,
              size: 40,
              color: InvColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            InvStrings.emptyTitle,
            style: InvStyles.sectionTitle.copyWith(color: InvColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            _ctrl.activeCategory == 'All'
                ? InvStrings.emptyAll
                : InvStrings.emptySubtitle,
            style: InvStyles.cardNote.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoldGroupedList(List<StockItem> items) {
    final groups = <_InventorySubCategoryGroup>[];
    final bucket = <String, List<StockItem>>{};

    for (final item in items) {
      final key =
          item.subCategory.trim().isEmpty ? 'Uncategorised' : item.subCategory;
      bucket.putIfAbsent(key, () => []).add(item);
    }

    for (final entry in bucket.entries) {
      final list = entry.value;
      final totalQty = list.fold<int>(0, (sum, item) => sum + item.quantity);
      final totalNetWeight = list.fold<double>(
        0.0,
        (sum, item) => sum + (item.netWeight * item.quantity),
      );
      final totalValue = list.fold<double>(
        0.0,
        (sum, item) =>
            sum +
            ((item.mrp > 0 ? item.mrp : item.purchasePrice) * item.quantity),
      );
      final totalFineGold = list.fold<double>(
        0.0,
        (sum, item) =>
            sum +
            (item.netWeight *
                item.quantity *
                (_parseTouchPercent(item.purity) / 100.0)),
      );

      final purityTags = list
          .map((item) => item.purity?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .take(3)
          .toList(growable: false);

      groups.add(
        _InventorySubCategoryGroup(
          subCategory: entry.key,
          items: list,
          totalQuantity: totalQty,
          totalNetWeight: totalNetWeight,
          totalFineGold: totalFineGold,
          totalValue: totalValue,
          purityTags: purityTags,
        ),
      );
    }

    groups.sort((a, b) => b.totalValue.compareTo(a.totalValue));

    return Column(
      children: [
        for (int index = 0; index < groups.length; index++) ...[
          _GoldInventoryGroupCard(
            group: groups[index],
            rupeeFormat: _rupee,
            wtFormat: _wt,
          ),
          if (index < groups.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  double _parseTouchPercent(String? purity) {
    if (purity == null || purity.trim().isEmpty) {
      return 0.0;
    }

    final text = purity.toUpperCase();
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
    if (percentMatch != null) {
      return double.tryParse(percentMatch.group(1) ?? '') ?? 0.0;
    }

    final karatMatch = RegExp(r'(\d{1,2})K').firstMatch(text);
    if (karatMatch != null) {
      final karat = double.tryParse(karatMatch.group(1) ?? '');
      if (karat != null) {
        return (karat / 24.0) * 100.0;
      }
    }

    final hallmarkMatch = RegExp(
      r'\b(999|916|925|750|585|417)\b',
    ).firstMatch(text);
    if (hallmarkMatch != null) {
      final hallmark = double.tryParse(hallmarkMatch.group(1) ?? '');
      if (hallmark != null) {
        return hallmark > 100 ? hallmark / 10.0 : hallmark;
      }
    }

    final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    if (numericMatch != null) {
      final raw = double.tryParse(numericMatch.group(1) ?? '');
      if (raw != null) {
        return raw > 100 ? raw / 10.0 : raw;
      }
    }

    return 0.0;
  }
}
