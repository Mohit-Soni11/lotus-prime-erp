// =============================================================================
// FILE        : inventory_screen.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / Screen
// DESCRIPTION : Production Inventory Ledger screen.
//               Design matches Customer List header exactly:
//               - Dark shell AppBar with Gold Gradient module icon
//               - Pill-shaped Animated System Online Radar
//               - Cream body background (0xFFF9F6F0)
//               - Staggered entry animations
//               - Icons properly extracted to InvIcons
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/stock/inventory_controller.dart';
//import '../../../models/stock/inventory/inventory_stats_model.dart';
import '../../../models/stock/stock_enums/stock_enums.dart';
import '../../../theme/stock/inventory/inventory_theme.dart';

// =============================================================================
// MASTER SCREEN
// =============================================================================

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const InventoryScreen({super.key, this.onBack});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late final InventoryController _ctrl;
  final AppDatabase _db = AppDatabase();

  // ── Section entry animations ────────────────────────────────
  static const int _sectionCount = 5;
  late final List<AnimationController> _sectionAnim;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  // ── Currency formatter ───────────────────────────────────────
  final _rupee = NumberFormat('₹##,##,##0', 'en_IN');
  final _wt = NumberFormat('##0.00', 'en_IN');

  @override
  void initState() {
    super.initState();
    _ctrl = InventoryController(_db);
    _ctrl.addListener(_rebuild);

    // Staggered entry animations
    _sectionAnim = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _sectionFade = _sectionAnim
        .map((ac) => CurvedAnimation(parent: ac, curve: Curves.easeInOut))
        .toList();
    _sectionSlide = _sectionAnim
        .map(
          (ac) => Tween<Offset>(
            begin: const Offset(0, 0.10),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: ac, curve: Curves.easeOutCubic)),
        )
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 90), () {
        if (mounted) _sectionAnim[i].forward();
      });
    }

    _ctrl.loadStats();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_rebuild)
      ..dispose();
    for (final a in _sectionAnim) a.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionFade[index],
      child: SlideTransition(position: _sectionSlide[index], child: child),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      body: _ctrl.isLoading && _ctrl.stats.openingCount == 0
          ? _buildLoadingState()
          : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: InvColors.brandGold,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text('Loading inventory data...', style: InvStyles.pageSubtitle),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Header ──────────────────────────────────
                _animated(0, _buildPageHeader()),
                const SizedBox(height: 24),

                // ── Summary Cards Row ────────────────────────────
                _animated(1, _buildSummaryCards()),
                const SizedBox(height: 20),

                // ── Metal Holdings Card ───────────────────────────
                _animated(2, _buildMetalHoldingsCard()),
                const SizedBox(height: 24),

                // ── Section Label + Filter ────────────────────────
                _animated(3, _buildSectionHeader()),
                const SizedBox(height: 12),
                _animated(3, _buildCategoryFilter()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Stock Items List ─────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: SliverToBoxAdapter(child: _animated(4, _buildStockList())),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PAGE HEADER
  // ════════════════════════════════════════════════════════════════

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
            border: Border.all(color: InvColors.brandGold.withOpacity(0.3)),
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

  // ════════════════════════════════════════════════════════════════
  // SUMMARY CARDS (Opening + Closing side by side)
  // ════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════
  // METAL HOLDINGS CARD
  // ════════════════════════════════════════════════════════════════

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
                  color: InvColors.metalAccent.withOpacity(0.15),
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

  // ════════════════════════════════════════════════════════════════
  // SECTION HEADER + CATEGORY FILTER
  // ════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: InvColors.brandGold.withOpacity(0.12),
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
              _ctrl.setCategory(cat);
              setState(() {});
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

  // ════════════════════════════════════════════════════════════════
  // STOCK ITEMS LIST (Live StreamBuilder)
  // ════════════════════════════════════════════════════════════════

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
            color: InvColors.cardBg.withOpacity(0.5),
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
        (sum, item) => sum + item.netWeight,
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
            sum + (item.netWeight * (_parseTouchPercent(item.purity) / 100.0)),
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

class _InventorySubCategoryGroup {
  final String subCategory;
  final List<StockItem> items;
  final int totalQuantity;
  final double totalNetWeight;
  final double totalFineGold;
  final double totalValue;
  final List<String> purityTags;

  const _InventorySubCategoryGroup({
    required this.subCategory,
    required this.items,
    required this.totalQuantity,
    required this.totalNetWeight,
    required this.totalFineGold,
    required this.totalValue,
    required this.purityTags,
  });
}

class _GoldInventoryGroupCard extends StatelessWidget {
  final _InventorySubCategoryGroup group;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;

  const _GoldInventoryGroupCard({
    required this.group,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.cardDecoration.copyWith(
        border: Border.all(
          color: InvColors.brandGold.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InvColors.brandGold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InvColors.brandGold.withOpacity(0.22),
                    ),
                  ),
                  child: const Icon(
                    InvIcons.catGold,
                    color: InvColors.brandGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.subCategory.toUpperCase(),
                        style: InvStyles.sectionTitle.copyWith(
                          color: InvColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.items.length} stock line${group.items.length == 1 ? '' : 's'} combined in one gold ledger card.',
                        style: InvStyles.cardNote,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: InvColors.brandGoldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InvColors.brandGold.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'COMBINED VALUE',
                        style: InvStyles.cardNote.copyWith(
                          color: InvColors.brandGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rupeeFormat.format(group.totalValue),
                        style: InvStyles.cardSubValue.copyWith(
                          color: InvColors.brandGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _groupMetric(
                  'Pieces',
                  '${group.totalQuantity} pcs',
                  InvColors.brandGold,
                ),
                _groupMetric(
                  'Net Weight',
                  '${wtFormat.format(group.totalNetWeight)} g',
                  InvColors.closingAccent,
                ),
                _groupMetric(
                  'Fine Gold',
                  '${wtFormat.format(group.totalFineGold)} g',
                  InvColors.openingAccent,
                ),
                if (group.purityTags.isNotEmpty)
                  _groupMetric(
                    'Purity Mix',
                    group.purityTags.join(' • '),
                    InvColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int index = 0; index < group.items.length; index++) ...[
                  _GoldInventoryMiniRow(
                    item: group.items[index],
                    rupeeFormat: rupeeFormat,
                    wtFormat: wtFormat,
                  ),
                  if (index < group.items.length - 1)
                    const Divider(height: 18, color: InvColors.cardBorder),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupMetric(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: InvStyles.cardNote.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: InvStyles.cardSubValue.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldInventoryMiniRow extends StatelessWidget {
  final StockItem item;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;

  const _GoldInventoryMiniRow({
    required this.item,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: InvStyles.itemName.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  'SKU ${item.sku}',
                  if ((item.purity ?? '').isNotEmpty) item.purity!,
                  if ((item.huid ?? '').isNotEmpty) 'HUID ${item.huid}',
                ].join('  •  '),
                style: InvStyles.itemSku,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${wtFormat.format(item.netWeight)} g',
          style: InvStyles.itemFieldValue,
        ),
        const SizedBox(width: 16),
        Text(
          rupeeFormat.format(item.mrp > 0 ? item.mrp : item.purchasePrice),
          style: InvStyles.itemMrp.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

// =============================================================================
// SUMMARY CARD WIDGET
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String note;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String bigNumber;
  final String bigUnit;
  final String row1Label;
  final String row1Value;
  final String row2Label;
  final String row2Value;
  final Widget? deltaWidget;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.note,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.bigNumber,
    required this.bigUnit,
    required this.row1Label,
    required this.row1Value,
    required this.row2Label,
    required this.row2Value,
    this.deltaWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.summaryCard(accentColor, bgColor, borderColor),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: InvStyles.cardLabel.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      note,
                      style: InvStyles.cardNote,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bigNumber,
                style: InvStyles.cardBigNumber.copyWith(color: accentColor),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  bigUnit,
                  style: InvStyles.cardNote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats rows
          _StatRow(label: row1Label, value: row1Value),
          const SizedBox(height: 4),
          _StatRow(label: row2Label, value: row2Value),

          if (deltaWidget != null) ...[
            const SizedBox(height: 10),
            deltaWidget!,
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: InvStyles.cardNote),
        Text(
          value,
          style: InvStyles.cardSubValue.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// =============================================================================
// MOVEMENT CHIP (today's +/- on closing card)
// =============================================================================

class _MovementChip extends StatelessWidget {
  final int added;
  final int sold;
  const _MovementChip({required this.added, required this.sold});

  @override
  Widget build(BuildContext context) {
    if (added == 0 && sold == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (added > 0)
          _chip('+$added added today', InvColors.success, InvColors.successBg),
        if (added > 0 && sold > 0) const SizedBox(width: 6),
        if (sold > 0)
          _chip('-$sold sold today', InvColors.danger, InvColors.dangerBg),
      ],
    );
  }

  Widget _chip(String text, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

// =============================================================================
// METAL HOLDING CHIP
// =============================================================================

class _MetalHoldingChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final double weight;
  final double value;
  final Color bg;
  final Color textColor;
  final Color border;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;
  final bool showWeight;
  final bool showValue;

  const _MetalHoldingChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.weight,
    required this.value,
    required this.bg,
    required this.textColor,
    required this.border,
    required this.rupeeFormat,
    required this.wtFormat,
    this.showWeight = true,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: InvStyles.metalChip(bg, border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: InvStyles.metalChipText(
                  textColor,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count pcs',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (showWeight && weight > 0)
            Text(
              '${wtFormat.format(weight)} g',
              style: InvStyles.metalChipText(
                textColor,
              ).copyWith(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          if (showValue && value > 0)
            Text(
              rupeeFormat.format(value),
              style: InvStyles.metalChipText(
                textColor,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// STOCK ITEM CARD
// =============================================================================

class _StockItemCard extends StatefulWidget {
  final StockItem item;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;
  const _StockItemCard({
    required this.item,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  State<_StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends State<_StockItemCard> {
  bool _hovered = false;

  (Color, Color, Color) _statusColors(String status) {
    if (status == StockStatus.available.label)
      return (
        InvColors.statusAvailBg,
        InvColors.statusAvailText,
        InvColors.closingAccent,
      );
    if (status == StockStatus.sold.label)
      return (
        InvColors.statusSoldBg,
        InvColors.statusSoldText,
        InvColors.danger,
      );
    if (status == StockStatus.onOrder.label)
      return (
        InvColors.statusOrderBg,
        InvColors.statusOrderText,
        InvColors.warning,
      );
    return (
      InvColors.statusKarigarBg,
      InvColors.statusKarigarText,
      InvColors.openingAccent,
    );
  }

  Color _categoryAccent(String cat) {
    if (cat == StockCategory.gold.label) return InvColors.brandGold;
    if (cat == StockCategory.silver.label) return const Color(0xFF94A3B8);
    if (cat == StockCategory.diamond.label) return const Color(0xFF3B82F6);
    if (cat == StockCategory.platinum.label) return const Color(0xFF8B5CF6);
    return InvColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final (statusBg, statusText, _) = _statusColors(item.status);
    final accent = _categoryAccent(item.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? InvColors.cardBg : InvColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? accent.withOpacity(0.5) : InvColors.cardBorder,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _hovered ? accent.withOpacity(0.10) : InvColors.shadowLight,
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: InvStyles.itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: item.status,
                          bg: statusBg,
                          textColor: statusText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // SKU + category
                    Row(
                      children: [
                        Text(
                          '${InvStrings.lblSku}: ${item.sku}',
                          style: InvStyles.itemSku,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: InvStyles.itemSku.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.purity != null &&
                            (item.purity ?? '').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('• ${item.purity}', style: InvStyles.itemSku),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          label: 'Gross',
                          value: '${widget.wtFormat.format(item.grossWeight)}g',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Net',
                          value: '${widget.wtFormat.format(item.netWeight)}g',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Qty', value: '${item.quantity} pcs'),
                        const Spacer(),
                        // MRP
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('MRP', style: InvStyles.itemFieldLabel),
                            Text(
                              widget.rupeeFormat.format(item.mrp),
                              style: InvStyles.itemMrp,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    if (cat == StockCategory.gold.label) return InvIcons.catGold;
    if (cat == StockCategory.silver.label) return InvIcons.catSilver;
    if (cat == StockCategory.diamond.label) return InvIcons.catDiamond;
    if (cat == StockCategory.platinum.label) return InvIcons.catPlatinum;
    if (cat == StockCategory.antique.label) return InvIcons.catAntique;
    return InvIcons.catDefault;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: InvStyles.itemFieldLabel),
        Text(value, style: InvStyles.itemFieldValue),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: InvStyles.statusBadge(bg, textColor),
      child: Text(label, style: InvStyles.statusBadgeText(textColor)),
    );
  }
}

// =============================================================================
// APP BAR — Premium Design Match
// =============================================================================

class _InventoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const _InventoryAppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<_InventoryAppBar> createState() => _InventoryAppBarState();
}

class _InventoryAppBarState extends State<_InventoryAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Animated Back Button ──────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),

            // ── 2. Vertical Divider ──────────────────────────────────────────
            _buildVerticalDivider(),
            const SizedBox(width: 18),

            // ── 3. Premium Gradient Module Icon ──────────────────────────────
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [InvColors.goldGradientStart, InvColors.brandGold],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: InvColors.brandGold.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                InvIcons.moduleIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // ── 4. Main Title ────────────────────────────────────────────────
            Text(
              InvStrings.screenTitle,
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),

            // Spacer pushes the radar widget to the right end
            const Spacer(),

            // ── 5. Premium Radar Widget ──────────────────────────────────────
            _RadarWidget(blinkCtrl: _blinkCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            InvColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BACK BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? InvColors.shellBg
                  : InvColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? InvColors.brandGold : InvColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: InvColors.brandGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              InvIcons.backArrow,
              color:
                  _isHovered ? InvColors.brandGold : InvColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR / ONLINE WIDGET (Pill shape added)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: InvColors.onlineGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildWave(blinkCtrl, 0.0),
                _buildWave(blinkCtrl, 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: InvColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: InvColors.onlineGreen,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            InvStrings.systemOnline,
            style: GoogleFonts.inter(
              color: InvColors.onlineGreen,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWave(AnimationController ctrl, double delay) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final val = (ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + (val * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: InvColors.onlineGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
