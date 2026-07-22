// ==========================================
// FILE: pos_stock_lookup_field.dart
// TYPE: Reusable UI Component
// DESCRIPTION: Shared stock suggestion field used by POS item description and
//              HUID lookup inputs.
// ==========================================

import 'package:flutter/material.dart';

import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'shared_pos_components.dart';

class PosStockLookupField extends StatefulWidget {
  final Listenable listenable;
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Future<void> Function(String query) onSearch;
  final List<PosStockLookupModel> Function() getSuggestions;
  final ValueChanged<PosStockLookupModel> onSelected;
  final VoidCallback onClearSuggestions;
  final double overlayWidth;

  const PosStockLookupField({
    super.key,
    required this.listenable,
    required this.controller,
    required this.hint,
    required this.onSearch,
    required this.getSuggestions,
    required this.onSelected,
    required this.onClearSuggestions,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.overlayWidth = 300,
  });

  @override
  State<PosStockLookupField> createState() => _PosStockLookupFieldState();
}

class _PosStockLookupFieldState extends State<PosStockLookupField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  bool _muteSearch = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.listenable.addListener(_onSuggestionStateChanged);
  }

  @override
  void didUpdateWidget(covariant PosStockLookupField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onSuggestionStateChanged);
      widget.listenable.addListener(_onSuggestionStateChanged);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    widget.listenable.removeListener(_onSuggestionStateChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_muteSearch) {
      return;
    }
    widget.onSearch(widget.controller.text);
  }

  void _onSuggestionStateChanged() {
    if (!mounted) {
      return;
    }

    final suggestions = widget.getSuggestions();
    if (suggestions.isEmpty || widget.controller.text.trim().isEmpty) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay() {
    if (!mounted) {
      return;
    }

    final overlay = Overlay.of(context);
    final suggestions = widget.getSuggestions();
    if (suggestions.isEmpty) {
      _removeOverlay();
      return;
    }

    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (context) => Positioned(
        width: widget.overlayWidth,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 42),
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * -6),
                    child: child,
                  ),
                );
              },
              child: _StockSuggestionDropdown(
                suggestions: suggestions,
                onSelected: (selection) {
                  _muteSearch = true;
                  widget.onSelected(selection);
                  widget.onClearSuggestions();
                  _removeOverlay();
                  Future.microtask(() => _muteSearch = false);
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: PosAtomicTextField(
        controller: widget.controller,
        hint: widget.hint,
        focusNode: widget.focusNode,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

class _StockSuggestionDropdown extends StatelessWidget {
  final List<PosStockLookupModel> suggestions;
  final ValueChanged<PosStockLookupModel> onSelected;

  const _StockSuggestionDropdown({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 318),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SuggestionHeader(count: suggestions.length),
            const _SuggestionColumnHeader(),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: SalesPosColors.bodyBorder,
                ),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return _SuggestionRow(
                    item: item,
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionHeader extends StatelessWidget {
  final int count;

  const _SuggestionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        border: Border(
          bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 15,
            color: SalesPosColors.brandGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Matching stock',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$count found',
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.brandGold,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionColumnHeader extends StatelessWidget {
  const _SuggestionColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = SalesPosStyles.caption.copyWith(
      color: SalesPosColors.bodyTextMuted.withValues(alpha: 0.72),
      fontSize: 10,
      fontWeight: FontWeight.w900,
    );
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: SalesPosColors.bodyBg,
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Text('ITEM NAME', maxLines: 1, style: style),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 10,
            child: Text('HUID', maxLines: 1, style: style),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: Text(
              'WEIGHT',
              maxLines: 1,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: SalesPosColors.brandGold.withValues(alpha: 0.08),
      splashColor: SalesPosColors.brandGold.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _metalColor(item),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SalesPosStyles.bodyText.copyWith(
                            color: SalesPosColors.bodyTextMain,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _itemMeta(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SalesPosStyles.caption.copyWith(
                            color: SalesPosColors.bodyTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 10,
              child: _HuidPill(text: _huidValue(item)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 68,
              child: Text(
                '${_formatWeight(item.grossWeight)} g',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: SalesPosStyles.bodyText.copyWith(
                  color: SalesPosColors.bodyTextMain,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _huidValue(PosStockLookupModel item) {
    if (item.huids.isNotEmpty) {
      return item.huids.join(', ');
    }
    final huid = item.huid?.trim() ?? '';
    if (huid.isNotEmpty) {
      return huid;
    }
    return item.sku.trim().isEmpty ? '-' : item.sku.trim();
  }

  static String _itemMeta(PosStockLookupModel item) {
    final type = item.categoryLabel.trim();
    final segment = item.segmentLabel.trim();
    final company = item.companyName.trim();
    final details = <String>[
      if (type.isNotEmpty) 'Type: $type',
      if (company.isNotEmpty) 'Company: $company',
      if (segment.isNotEmpty) segment,
      if (item.quantity > 1) '${item.quantity} pcs',
    ];
    if (details.isEmpty) {
      return item.sku;
    }
    return details.join('  |  ');
  }

  static String _formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static Color _metalColor(PosStockLookupModel item) {
    switch (item.metal) {
      case MetalType.gold:
        return SalesPosColors.brandGold;
      case MetalType.silver:
        return SalesPosColors.brandSilver;
      case MetalType.platinum:
        return SalesPosColors.brandPlatinum;
      case MetalType.diamond:
        return SalesPosColors.brandDiamond;
    }
  }
}

class _HuidPill extends StatelessWidget {
  final String text;

  const _HuidPill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 13,
            color: SalesPosColors.brandGold.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
