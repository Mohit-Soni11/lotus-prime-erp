part of 'return_reversal_customer_details_card.dart';

enum _SourceHistoryCategory {
  sales('SALES', 'No sales invoice', Icons.receipt_long_rounded),
  booking('BOOKING', 'No booking record', Icons.bookmark_added_rounded),
  purchase('PURCHASE', 'No purchase voucher', Icons.scale_rounded);

  final String label;
  final String emptyText;
  final IconData icon;

  const _SourceHistoryCategory(this.label, this.emptyText, this.icon);
}

class _SourceHistoryStrip extends StatefulWidget {
  final ReturnReversalController controller;

  const _SourceHistoryStrip({required this.controller});

  @override
  State<_SourceHistoryStrip> createState() => _SourceHistoryStripState();
}

class _SourceHistoryStripState extends State<_SourceHistoryStrip> {
  static const double _documentPillWidth = 252;
  static const double _documentPillHeight = 74;
  static const double _documentPillGap = 8;

  late final FocusNode _historyFocusNode;
  late final ScrollController _documentScrollController;
  _SourceHistoryCategory _activeCategory = _SourceHistoryCategory.sales;

  @override
  void initState() {
    super.initState();
    _historyFocusNode = FocusNode(debugLabel: 'ReturnReversalSourceHistory');
    _documentScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _historyFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _historyFocusNode.dispose();
    _documentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.controller.state.lookupResult;
    final visibleCategories = _visibleCategories;
    final activeCategory = _activeCategoryFor(visibleCategories, result);
    final documents = _documentsFor(result, activeCategory);
    final activeColor = _colorFor(activeCategory);
    final canNavigate = documents.isNotEmpty;

    return Focus(
      autofocus: true,
      focusNode: _historyFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SalesPosColors.bodyBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SalesPosColors.bodyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in visibleCategories) ...[
                    _HistoryCategoryPill(
                      category: category,
                      count: _countFor(result, category),
                      selected: activeCategory == category,
                      color: _colorFor(category),
                      onTap: _selectCategory,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: documents.isEmpty
                  ? _EmptyHistoryLine(
                      key: ValueKey(activeCategory.emptyText),
                      color: activeColor,
                      message: activeCategory.emptyText,
                    )
                  : Row(
                      key: ValueKey(activeCategory),
                      children: [
                        _HistoryArrowButton(
                          enabled: canNavigate,
                          icon: Icons.chevron_left_rounded,
                          color: activeColor,
                          onTap: () => _moveSelection(documents, -1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _documentScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final document in documents) ...[
                                  _SourceDocumentPill(
                                    document: document,
                                    selected: widget
                                            .controller
                                            .state
                                            .selectedSourceDocument
                                            ?.documentNo ==
                                        document.documentNo,
                                    width: _pillWidthFor(document),
                                    onTap: () {
                                      _historyFocusNode.requestFocus();
                                      widget.controller
                                          .selectSourceDocument(document);
                                      _ensureDocumentVisible(
                                        documents,
                                        document,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HistoryArrowButton(
                          enabled: canNavigate,
                          icon: Icons.chevron_right_rounded,
                          color: activeColor,
                          onTap: () => _moveSelection(documents, 1),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(_SourceHistoryCategory category) {
    _historyFocusNode.requestFocus();
    if (_activeCategory == category || !_visibleCategories.contains(category)) {
      return;
    }
    setState(() => _activeCategory = category);
  }

  void _moveSelection(
    List<ReturnReversalSourceDocument> documents,
    int direction,
  ) {
    if (documents.isEmpty) {
      return;
    }

    final selectedNumber =
        widget.controller.state.selectedSourceDocument?.documentNo;
    final currentIndex = documents.indexWhere(
      (document) => document.documentNo == selectedNumber,
    );
    final fallbackIndex = direction > 0 ? 0 : documents.length - 1;
    final nextIndex = currentIndex == -1
        ? fallbackIndex
        : (currentIndex + direction).clamp(0, documents.length - 1);

    _historyFocusNode.requestFocus();
    widget.controller.selectSourceDocument(documents[nextIndex]);
    _ensureDocumentVisible(documents, documents[nextIndex]);
  }

  void _ensureDocumentVisible(
    List<ReturnReversalSourceDocument> documents,
    ReturnReversalSourceDocument document,
  ) {
    if (!_documentScrollController.hasClients) {
      return;
    }
    final index = documents.indexWhere(
      (entry) =>
          entry.type == document.type &&
          entry.documentNo == document.documentNo,
    );
    if (index == -1) {
      return;
    }

    var leadingOffset = 0.0;
    for (var i = 0; i < index; i += 1) {
      leadingOffset += _pillWidthFor(documents[i]) + _documentPillGap;
    }
    final trailingOffset = leadingOffset + _pillWidthFor(document);
    final position = _documentScrollController.position;
    final visibleStart = position.pixels;
    final visibleEnd = visibleStart + position.viewportDimension;
    var targetOffset = visibleStart;

    if (leadingOffset < visibleStart) {
      targetOffset = leadingOffset;
    } else if (trailingOffset > visibleEnd) {
      targetOffset = trailingOffset - position.viewportDimension;
    } else {
      return;
    }

    _documentScrollController.animateTo(
      targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  double _pillWidthFor(ReturnReversalSourceDocument document) {
    return _documentPillWidth;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final documents = _documentsFor(
      widget.controller.state.lookupResult,
      _activeCategoryFor(
        _visibleCategories,
        widget.controller.state.lookupResult,
      ),
    );
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(documents, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveSelection(documents, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirmSelection(documents);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _confirmSelection(List<ReturnReversalSourceDocument> documents) {
    if (documents.isEmpty) {
      return;
    }

    final selectedNumber =
        widget.controller.state.selectedSourceDocument?.documentNo;
    final currentDocument =
        documents.cast<ReturnReversalSourceDocument?>().firstWhere(
              (document) => document?.documentNo == selectedNumber,
              orElse: () => documents.first,
            );
    widget.controller.selectSourceDocument(currentDocument!);
    _historyFocusNode.requestFocus();
  }

  List<ReturnReversalSourceDocument> _documentsFor(
    ReturnReversalLookupResult result,
    _SourceHistoryCategory category,
  ) {
    return switch (category) {
      _SourceHistoryCategory.sales => result.salesInvoices,
      _SourceHistoryCategory.booking => result.advanceBookings,
      _SourceHistoryCategory.purchase => result.customerPurchases,
    };
  }

  List<_SourceHistoryCategory> get _visibleCategories {
    return widget.controller.state.operationType ==
            ReturnReversalOperationType.salesReturn
        ? const [
            _SourceHistoryCategory.sales,
            _SourceHistoryCategory.purchase,
          ]
        : const [_SourceHistoryCategory.booking];
  }

  _SourceHistoryCategory _activeCategoryFor(
    List<_SourceHistoryCategory> visibleCategories,
    ReturnReversalLookupResult result,
  ) {
    if (visibleCategories.contains(_activeCategory) &&
        _documentsFor(result, _activeCategory).isNotEmpty) {
      return _activeCategory;
    }
    final selectedCategory =
        _categoryForSource(widget.controller.state.selectedSourceDocument);
    if (selectedCategory != null &&
        visibleCategories.contains(selectedCategory)) {
      return selectedCategory;
    }
    if (visibleCategories.contains(_activeCategory)) {
      return _activeCategory;
    }
    return visibleCategories.first;
  }

  _SourceHistoryCategory? _categoryForSource(
    ReturnReversalSourceDocument? document,
  ) {
    return switch (document?.type) {
      ReturnReversalSourceDocumentType.salesInvoice =>
        _SourceHistoryCategory.sales,
      ReturnReversalSourceDocumentType.advanceBooking =>
        _SourceHistoryCategory.booking,
      ReturnReversalSourceDocumentType.customerPurchase =>
        _SourceHistoryCategory.purchase,
      null => null,
    };
  }

  int _countFor(
    ReturnReversalLookupResult result,
    _SourceHistoryCategory category,
  ) {
    return switch (category) {
      _SourceHistoryCategory.sales => result.salesInvoices.length,
      _SourceHistoryCategory.booking => result.advanceBookings.length,
      _SourceHistoryCategory.purchase => result.customerPurchases.length,
    };
  }

  Color _colorFor(_SourceHistoryCategory category) {
    return switch (category) {
      _SourceHistoryCategory.sales => SalesPosColors.success,
      _SourceHistoryCategory.booking => SalesPosColors.brandGold,
      _SourceHistoryCategory.purchase => SalesPosColors.brandSilver,
    };
  }
}

class _HistoryCategoryPill extends StatelessWidget {
  final _SourceHistoryCategory category;
  final int count;
  final bool selected;
  final Color color;
  final ValueChanged<_SourceHistoryCategory> onTap;

  const _HistoryCategoryPill({
    required this.category,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(category),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.13) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.30),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(category.icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                '${category.label}  $count',
                style: TextStyle(
                  color: color,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryArrowButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HistoryArrowButton({
    required this.enabled,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 42,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.34)
                  : SalesPosColors.bodyBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled
                ? color
                : SalesPosColors.textDark.withValues(alpha: 0.52),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryLine extends StatelessWidget {
  final Color color;
  final String message;

  const _EmptyHistoryLine({
    super.key,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SalesPosColors.textDark,
          fontSize: SalesPosStyles.fontLabel,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
