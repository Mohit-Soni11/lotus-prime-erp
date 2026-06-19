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
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1,
            color: SalesPosColors.bodyBorder,
          ),
          itemBuilder: (context, index) {
            final item = suggestions[index];
            return InkWell(
              onTap: () => onSelected(item),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: SalesPosColors.brandGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.bodyTextMain,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.displaySubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.bodyTextMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: SalesPosColors.bodyBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: SalesPosColors.bodyBorder,
                        ),
                      ),
                      child: Text(
                        item.sku,
                        style: const TextStyle(
                          color: SalesPosColors.bodyTextMain,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
