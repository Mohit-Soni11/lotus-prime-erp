import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

class ReturnReversalCustomerDetailsCard extends StatefulWidget {
  final ReturnReversalController controller;

  const ReturnReversalCustomerDetailsCard({
    super.key,
    required this.controller,
  });

  @override
  State<ReturnReversalCustomerDetailsCard> createState() =>
      _ReturnReversalCustomerDetailsCardState();
}

class _ReturnReversalCustomerDetailsCardState
    extends State<ReturnReversalCustomerDetailsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationType = widget.controller.state.operationType;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SalesPosColors.customerCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: SalesPosColors.shadowDark,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CustomerCardHeader(
                controller: widget.controller,
                operationType: operationType,
              ),
              const SizedBox(height: 16),
              _GoldDivider(),
              const SizedBox(height: 16),
              _CustomerInputGrid(
                controller: widget.controller,
                operationType: operationType,
              ),
              if (widget.controller.state.lookupMessage != null) ...[
                const SizedBox(height: 14),
                _LookupMessageBar(
                  message: widget.controller.state.lookupMessage!,
                ),
              ],
              if (widget.controller.state.lookupResult.hasDocuments) ...[
                const SizedBox(height: 14),
                _SourceHistoryStrip(controller: widget.controller),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCardHeader extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalOperationType operationType;

  const _CustomerCardHeader({
    required this.controller,
    required this.operationType,
  });

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Find customer by mobile, name, invoice, or purchase number'
        : 'Find customer by mobile, name, or booking number';
  }

  String get _badge {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'RETURN SOURCE'
        : 'CANCEL SOURCE';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                SalesPosColors.goldGradientStart,
                SalesPosColors.brandGold,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: SalesPosColors.brandGold.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            SalesPosIcons.profile,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CUSTOMER DETAILS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyText.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SearchRecordsButton(controller: controller),
        const SizedBox(width: 10),
        _CustomerSourceBadge(label: _badge),
      ],
    );
  }
}

class _SearchRecordsButton extends StatelessWidget {
  final ReturnReversalController controller;

  const _SearchRecordsButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: state.isSearching ? null : () => controller.searchRecords(),
        icon: state.isSearching
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.manage_search_rounded, size: 18),
        label: Text(state.isSearching ? 'Searching' : 'Search Records'),
        style: FilledButton.styleFrom(
          backgroundColor: SalesPosColors.textDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              SalesPosColors.textDark.withValues(alpha: 0.84),
          disabledForegroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _CustomerSourceBadge extends StatelessWidget {
  final String label;

  const _CustomerSourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: SalesPosColors.brandGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.bold,
              color: SalesPosColors.goldHoverDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.50),
            SalesPosColors.brandGold.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _LookupMessageBar extends StatelessWidget {
  final String message;

  const _LookupMessageBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.warning.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: SalesPosColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.textDark,
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  static const double _compactDocumentPillWidth = 192;
  static const double _statusDocumentPillWidth = 276;
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
    return document.reversalStatus.trim().isEmpty
        ? _compactDocumentPillWidth
        : _statusDocumentPillWidth;
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
            mainAxisSize: MainAxisSize.min,
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

class _SourceDocumentPill extends StatelessWidget {
  final ReturnReversalSourceDocument document;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  const _SourceDocumentPill({
    required this.document,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (document.type) {
      ReturnReversalSourceDocumentType.salesInvoice => SalesPosColors.success,
      ReturnReversalSourceDocumentType.advanceBooking =>
        SalesPosColors.brandGold,
      ReturnReversalSourceDocumentType.customerPurchase =>
        SalesPosColors.brandSilver,
    };
    final hasDue = document.dueAmount > 0.009;
    final hasReversalStatus = document.reversalStatus.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.13) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color
                  : hasDue
                      ? SalesPosColors.danger.withValues(alpha: 0.55)
                      : SalesPosColors.bodyBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(document.type), size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.documentNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.textDark,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (hasDue) ...[
                          const SizedBox(width: 6),
                          const _DueDot(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            document.type.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: SalesPosStyles.fontCaption,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (hasDue) ...[
                          const SizedBox(width: 7),
                          _DueAmountChip(amount: document.dueAmount),
                        ],
                        if (hasReversalStatus) ...[
                          const SizedBox(width: 7),
                          _DocumentStatusChip(
                            label: document.reversalStatus,
                            full: document.isFullyReversed,
                          ),
                        ],
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

  IconData _iconFor(ReturnReversalSourceDocumentType type) {
    return switch (type) {
      ReturnReversalSourceDocumentType.salesInvoice =>
        Icons.receipt_long_rounded,
      ReturnReversalSourceDocumentType.advanceBooking =>
        Icons.bookmark_added_rounded,
      ReturnReversalSourceDocumentType.customerPurchase => Icons.scale_rounded,
    };
  }
}

class _DocumentStatusChip extends StatelessWidget {
  final String label;
  final bool full;

  const _DocumentStatusChip({
    required this.label,
    required this.full,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toUpperCase();
    final color = full ? SalesPosColors.success : SalesPosColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        normalized,
        style: const TextStyle(
          color: SalesPosColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DueDot extends StatelessWidget {
  const _DueDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: SalesPosColors.danger,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: SalesPosColors.danger.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _DueAmountChip extends StatelessWidget {
  final double amount;

  const _DueAmountChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.danger.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        'DUE ${_formatCompactCurrency(amount)}',
        style: const TextStyle(
          color: SalesPosColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _formatCompactCurrency(double value) {
  final rounded = value.round().abs();
  if (rounded >= 100000) {
    return '${(rounded / 100000).toStringAsFixed(1)}L';
  }
  if (rounded >= 1000) {
    return '${(rounded / 1000).toStringAsFixed(1)}K';
  }
  return rounded.toString();
}

class _CustomerInputGrid extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalOperationType operationType;

  const _CustomerInputGrid({
    required this.controller,
    required this.operationType,
  });

  String get _sourceNumberLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'SOURCE NUMBER'
        : 'BOOKING NUMBER';
  }

  String get _sourceNumberHint {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Invoice or purchase no.'
        : 'Enter booking no.';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _mobileInput()),
                  const SizedBox(width: 12),
                  Expanded(child: _nameInput()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sourceDocumentInput()),
                  const SizedBox(width: 12),
                  Expanded(child: _addressInput()),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 2, child: _mobileInput()),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _nameInput()),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _sourceDocumentInput()),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _addressInput()),
          ],
        );
      },
    );
  }

  Widget _mobileInput() {
    return _CustomerDetailInput(
      label: 'MOBILE',
      hint: '10-digit',
      controller: controller.customerMobileCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      icon: SalesPosIcons.mobilePhone,
    );
  }

  Widget _nameInput() {
    return _CustomerDetailInput(
      label: 'CUSTOMER NAME',
      hint: 'Enter full name',
      controller: controller.customerNameCtrl,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
      ],
      icon: SalesPosIcons.customerName,
    );
  }

  Widget _sourceDocumentInput() {
    return _CustomerDetailInput(
      label: _sourceNumberLabel,
      hint: _sourceNumberHint,
      controller: controller.sourceDocumentNumberCtrl,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\/]')),
        LengthLimitingTextInputFormatter(32),
      ],
      icon: SalesPosIcons.invoiceOutline,
    );
  }

  Widget _addressInput() {
    return _CustomerDetailInput(
      label: 'ADDRESS',
      hint: 'Customer address',
      controller: controller.customerAddressCtrl,
      icon: SalesPosIcons.cityLocation,
    );
  }
}

class _CustomerDetailInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final IconData icon;

  const _CustomerDetailInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: SalesPosColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SalesPosColors.textDark,
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: SalesPosStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: SalesPosColors.textDark.withValues(alpha: 0.82),
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w800,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: SalesPosColors.textDark,
              ),
              filled: true,
              fillColor: SalesPosColors.formInputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: SalesPosColors.brandGold,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
