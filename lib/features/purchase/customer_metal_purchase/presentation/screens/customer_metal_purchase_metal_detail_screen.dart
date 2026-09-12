import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_summary_strip.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/melting_checkout/customer_metal_melting_checkout_table.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseMetalDetailScreen extends StatefulWidget {
  final CustomerMetalPurchaseMetal metal;
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseMetalDetailScreen({
    super.key,
    required this.metal,
    required this.controller,
  });

  @override
  State<CustomerMetalPurchaseMetalDetailScreen> createState() =>
      _CustomerMetalPurchaseMetalDetailScreenState();
}

class _CustomerMetalPurchaseMetalDetailScreenState
    extends State<CustomerMetalPurchaseMetalDetailScreen> {
  CustomerMetalPurchaseEntryView _view =
      CustomerMetalPurchaseEntryView.available;
  final Set<String> _selectedEntryKeys = {};
  List<CustomerMetalPurchaseEntry> _checkoutEntries = [];
  bool _isCheckoutLoading = true;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    _loadCheckoutEntries();
  }

  @override
  void didUpdateWidget(CustomerMetalPurchaseMetalDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.metal != widget.metal) {
      _selectedEntryKeys.clear();
      _loadCheckoutEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(widget.metal);

    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        title: '${widget.metal.label} Melting Checkout',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final summary = buildCustomerMetalPurchaseSummary(
              metal: widget.metal,
              entries: _checkoutEntries
                  .where((entry) => entry.isAvailable)
                  .toList(growable: false),
            );
            final entries = _entriesForCurrentView();
            final availableEntries = entries
                .where((entry) => entry.isAvailable)
                .toList(growable: false);
            final allVisibleSelected = availableEntries.isNotEmpty &&
                availableEntries.every(
                  (entry) => _selectedEntryKeys.contains(_entryKey(entry)),
                );
            final selectedEntries = _checkoutEntries
                .where((entry) => _selectedEntryKeys.contains(_entryKey(entry)))
                .where((entry) => entry.isAvailable)
                .toList(growable: false);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  CustomerMetalPurchaseSummaryStrip(
                    summary: summary,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  if (_isCheckoutLoading) ...[
                    LinearProgressIndicator(
                      minHeight: 3,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _DetailActionBar(
                    accent: accent,
                    view: _view,
                    selectedCount: selectedEntries.length,
                    availableCount: availableEntries.length,
                    allVisibleSelected: allVisibleSelected,
                    onViewChanged: (view) {
                      setState(() {
                        _view = view;
                        if (view != CustomerMetalPurchaseEntryView.available) {
                          _selectedEntryKeys.clear();
                        }
                      });
                    },
                    onSelectAllVisible: availableEntries.isEmpty
                        ? null
                        : () => _selectAllVisible(availableEntries),
                    onClearSelection: _selectedEntryKeys.isEmpty
                        ? null
                        : () => setState(_selectedEntryKeys.clear),
                    onCreateMeltingBatch: selectedEntries.isEmpty
                        ? null
                        : () => _confirmMeltingBatch(selectedEntries),
                  ),
                  const SizedBox(height: 16),
                  if (_checkoutError != null)
                    CustomerMetalPurchaseEmptyState(
                      message:
                          'Unable to load melting checkout records. $_checkoutError',
                    )
                  else if (_isCheckoutLoading && _checkoutEntries.isEmpty)
                    const _CheckoutLoadingState()
                  else if (entries.isEmpty)
                    CustomerMetalPurchaseEmptyState(
                      message:
                          'No ${widget.metal.label.toLowerCase()} ${_view.label.toLowerCase()} found.',
                    )
                  else
                    CustomerMetalMeltingCheckoutTable(
                      entries: entries,
                      selectedEntryKeys: _selectedEntryKeys,
                      accent: accent,
                      entryKeyBuilder: _entryKey,
                      onSelectionToggled: _toggleSelection,
                      onCustomerPressed: (entry) {
                        final customerId = entry.customerId;
                        if (customerId != null) {
                          _openCustomerProfile(context, customerId);
                        }
                      },
                      onReferencePressed: (entry) =>
                          _openSourceDocument(context, entry),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadCheckoutEntries({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        if (showLoader) {
          _isCheckoutLoading = true;
        }
        _checkoutError = null;
      });
    }

    try {
      final entries = await widget.controller.fetchMeltingCheckoutEntries(
        metal: widget.metal,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _checkoutEntries = entries;
        _isCheckoutLoading = false;
        _checkoutError = null;
        _pruneSelection(entries);
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckoutLoading = false;
        _checkoutError = exception.toString();
      });
    }
  }

  List<CustomerMetalPurchaseEntry> _entriesForCurrentView() {
    return _checkoutEntries.where((entry) {
      switch (_view) {
        case CustomerMetalPurchaseEntryView.available:
          return entry.isAvailable;
        case CustomerMetalPurchaseEntryView.transferred:
          return entry.isTransferredToMelting;
        case CustomerMetalPurchaseEntryView.returned:
          return entry.isReturned;
        case CustomerMetalPurchaseEntryView.all:
          return true;
      }
    }).toList(growable: false);
  }

  void _pruneSelection(List<CustomerMetalPurchaseEntry> entries) {
    final availableKeys = {
      for (final entry in entries)
        if (entry.isAvailable) _entryKey(entry),
    };
    _selectedEntryKeys.removeWhere((key) => !availableKeys.contains(key));
  }

  void _openCustomerProfile(BuildContext context, int customerId) {
    context.push(RoutePaths.customerProfileFor(customerId));
  }

  void _openSourceDocument(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) {
    final source = entry.source.toLowerCase();
    if (source.contains('trade') || source.contains('exchange')) {
      context.push(
        Uri(
          path: RoutePaths.salesPos,
          queryParameters: {'editBillId': '${entry.sourceDocumentId}'},
        ).toString(),
      );
      return;
    }

    context.push(
      RoutePaths.customerMetalPurchaseVoucherFor(entry.sourceDocumentId),
    );
  }

  Future<void> _confirmMeltingBatch(
    List<CustomerMetalPurchaseEntry> selectedEntries,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _LightConfirmationDialog(
          title: 'Checkout to Melting',
          message:
              'Move ${selectedEntries.length} selected ${widget.metal.label.toLowerCase()} item(s) into melting checkout. These items will be marked as melted and closed, removed from available shop metal, and will not be treated as returnable customer metal.',
          confirmLabel: 'Confirm Checkout',
          accent: _accentFor(widget.metal),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final batchNo = await widget.controller.createMeltingBatch(
      metal: widget.metal,
      selectedEntries: selectedEntries,
    );
    if (!mounted) {
      return;
    }

    setState(_selectedEntryKeys.clear);
    await _loadCheckoutEntries(showLoader: false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Melting checkout $batchNo completed.')),
    );
  }

  void _toggleSelection(CustomerMetalPurchaseEntry entry) {
    if (!entry.isAvailable) {
      return;
    }

    setState(() {
      final key = _entryKey(entry);
      if (_selectedEntryKeys.contains(key)) {
        _selectedEntryKeys.remove(key);
      } else {
        _selectedEntryKeys.add(key);
      }
    });
  }

  void _selectAllVisible(List<CustomerMetalPurchaseEntry> entries) {
    setState(() {
      for (final entry in entries) {
        _selectedEntryKeys.add(_entryKey(entry));
      }
    });
  }

  String _entryKey(CustomerMetalPurchaseEntry entry) {
    return '${entry.source}|${entry.id}';
  }

  Color _accentFor(CustomerMetalPurchaseMetal metal) {
    switch (metal) {
      case CustomerMetalPurchaseMetal.gold:
        return PurchaseEntryColors.metalGold;
      case CustomerMetalPurchaseMetal.silver:
        return PurchaseEntryColors.metalSilver;
      case CustomerMetalPurchaseMetal.diamond:
        return PurchaseEntryColors.metalDiamond;
      case CustomerMetalPurchaseMetal.platinum:
        return PurchaseEntryColors.metalPlatinum;
    }
  }
}

class _LightConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color accent;

  const _LightConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: accent.withValues(alpha: 0.30)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.45,
          letterSpacing: 0,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(150, 40),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _CheckoutLoadingState extends StatelessWidget {
  const _CheckoutLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  final Color accent;
  final CustomerMetalPurchaseEntryView view;
  final int selectedCount;
  final int availableCount;
  final bool allVisibleSelected;
  final ValueChanged<CustomerMetalPurchaseEntryView> onViewChanged;
  final VoidCallback? onSelectAllVisible;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCreateMeltingBatch;

  const _DetailActionBar({
    required this.accent,
    required this.view,
    required this.selectedCount,
    required this.availableCount,
    required this.allVisibleSelected,
    required this.onViewChanged,
    required this.onSelectAllVisible,
    required this.onClearSelection,
    required this.onCreateMeltingBatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in CustomerMetalPurchaseEntryView.values)
                _EntryViewButton(
                  label: Text(option.label),
                  selected: view == option,
                  accent: accent,
                  onPressed: () => onViewChanged(option),
                ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed:
                    allVisibleSelected ? onClearSelection : onSelectAllVisible,
                icon: Icon(
                  allVisibleSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                ),
                label: Text(
                  allVisibleSelected
                      ? 'Clear Selection'
                      : 'Select All ($availableCount)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  disabledForegroundColor: Colors.black.withValues(alpha: 0.38),
                  side: const BorderSide(color: Color(0xFFD8D2C8)),
                  minimumSize: const Size(150, 42),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onCreateMeltingBatch,
                icon: const Icon(Icons.local_fire_department_rounded, size: 18),
                label: Text(
                  selectedCount == 0
                      ? 'Checkout to Melting'
                      : 'Checkout to Melting ($selectedCount)',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF1F1F1),
                  disabledForegroundColor: Colors.black.withValues(alpha: 0.45),
                  minimumSize: const Size(190, 42),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryViewButton extends StatelessWidget {
  final Widget label;
  final bool selected;
  final Color accent;
  final VoidCallback onPressed;

  const _EntryViewButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : const Color(0xFFD8D2C8),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: textColor),
                const SizedBox(width: 7),
              ],
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
