// ==========================================
// FILE: pos_stock_lookup_field.dart
// TYPE: Reusable UI Component
// DESCRIPTION: Shared stock suggestion field used by POS item description and
//              HUID lookup inputs.
// ==========================================

import 'package:flutter/material.dart';

import '../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'shared_pos_components.dart';
import 'stock_lookup/pos_stock_suggestion_tile.dart';

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
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3D6BF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SuggestionHeader(count: suggestions.length),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return PosStockSuggestionTile(
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF3),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3D6BF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Matching Stock',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyText.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SalesPosColors.brandGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: SalesPosColors.brandGold.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              '$count ${count == 1 ? 'result' : 'results'}',
              style: SalesPosStyles.caption.copyWith(
                fontSize: 12,
                color: SalesPosColors.brandGold,
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
