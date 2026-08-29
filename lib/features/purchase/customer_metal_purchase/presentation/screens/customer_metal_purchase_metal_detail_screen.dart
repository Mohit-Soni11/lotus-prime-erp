import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_entry_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_summary_strip.dart';
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

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(widget.metal);

    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        title: '${widget.metal.label} Customer Metal Settlement',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final summary = widget.controller.summaryForMetal(widget.metal);
            final entries = widget.controller.entriesForMetal(
              widget.metal,
              view: _view,
            );
            final selectedEntries = widget.controller
                .entriesForMetal(widget.metal)
                .where((entry) => _selectedEntryKeys.contains(_entryKey(entry)))
                .toList(growable: false);

            _selectedEntryKeys.removeWhere(
              (key) => !widget.controller
                  .entriesForMetal(widget.metal)
                  .any((entry) => _entryKey(entry) == key),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  CustomerMetalPurchaseSummaryStrip(
                    summary: summary,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  _DetailActionBar(
                    accent: accent,
                    view: _view,
                    selectedCount: selectedEntries.length,
                    onViewChanged: (view) {
                      setState(() {
                        _view = view;
                        if (view != CustomerMetalPurchaseEntryView.available) {
                          _selectedEntryKeys.clear();
                        }
                      });
                    },
                    onCreateMeltingBatch: selectedEntries.isEmpty
                        ? null
                        : () => _confirmMeltingBatch(selectedEntries),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    CustomerMetalPurchaseEmptyState(
                      message:
                          'No ${widget.metal.label.toLowerCase()} ${_view.label.toLowerCase()} records found.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return CustomerMetalPurchaseEntryCard(
                          entry: entry,
                          accent: accent,
                          isSelected: _selectedEntryKeys.contains(
                            _entryKey(entry),
                          ),
                          onSelectionChanged: entry.isAvailable
                              ? (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedEntryKeys.add(_entryKey(entry));
                                    } else {
                                      _selectedEntryKeys
                                          .remove(_entryKey(entry));
                                    }
                                  });
                                }
                              : null,
                          onCustomerPressed: entry.customerId == null
                              ? null
                              : () => _openCustomerProfile(
                                    context,
                                    entry.customerId!,
                                  ),
                          onReferencePressed: () => _openSourceDocument(
                            context,
                            entry,
                          ),
                          onReturnPressed: () => _confirmReturn(
                            context,
                            entry,
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
        return AlertDialog(
          title: const Text('Create Melting Batch'),
          content: Text(
            'Transfer ${selectedEntries.length} selected ${widget.metal.label.toLowerCase()} item(s) to melting?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create Batch'),
            ),
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Melting batch $batchNo created.')),
    );
  }

  Future<void> _confirmReturn(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) async {
    if (!entry.isAvailable) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return Customer Metal'),
          content: Text(
            'Mark ${entry.referenceNo} as returned to ${entry.customerName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm Return'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await widget.controller.markReturned(entry);
    if (!context.mounted) {
      return;
    }

    setState(() => _selectedEntryKeys.remove(_entryKey(entry)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.referenceNo} marked as returned.')),
    );
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

class _DetailActionBar extends StatelessWidget {
  final Color accent;
  final CustomerMetalPurchaseEntryView view;
  final int selectedCount;
  final ValueChanged<CustomerMetalPurchaseEntryView> onViewChanged;
  final VoidCallback? onCreateMeltingBatch;

  const _DetailActionBar({
    required this.accent,
    required this.view,
    required this.selectedCount,
    required this.onViewChanged,
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
          FilledButton.icon(
            onPressed: onCreateMeltingBatch,
            icon: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: Text(
              selectedCount == 0
                  ? 'Create Melting Batch'
                  : 'Create Melting Batch ($selectedCount)',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF1F1F1),
              disabledForegroundColor: Colors.black.withValues(alpha: 0.45),
              minimumSize: const Size(190, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
