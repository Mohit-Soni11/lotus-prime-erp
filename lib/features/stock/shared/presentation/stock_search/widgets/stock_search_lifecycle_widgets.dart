part of '../stock_search_screen.dart';

class _StockLifecycleActionSection extends StatefulWidget {
  final StockSearchResult item;
  final VoidCallback? onChanged;

  const _StockLifecycleActionSection({
    required this.item,
    this.onChanged,
  });

  @override
  State<_StockLifecycleActionSection> createState() =>
      _StockLifecycleActionSectionState();
}

class _StockLifecycleActionSectionState
    extends State<_StockLifecycleActionSection> {
  late final StockLifecycleController _controller;
  late final StockSaleRestoreController _saleRestoreController;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _controller = StockLifecycleController(AppDatabase());
    _saleRestoreController = StockSaleRestoreController(AppDatabase());
  }

  @override
  Widget build(BuildContext context) {
    final actions = _controller.actionsFor(widget.item);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                icon: Icons.admin_panel_settings_rounded,
                accent: InvColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Status Control',
                      style: InvStyles.sectionTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Every status change requires a reason and is stored in the unit audit trail.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.item.isSold)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _UnitMovementMessage(
                  icon: Icons.lock_rounded,
                  title: 'Sold Stock Is Locked',
                  message:
                      'Use controlled restore only when this sale stock needs to return into available inventory.',
                ),
                const SizedBox(height: 10),
                _LifecycleActionButton(
                  action: const StockLifecycleAction(
                    label: 'Restore To Inventory',
                    targetStatus: 'Available',
                    reasonHint:
                        'Enter sale return number, customer note or restore reason.',
                  ),
                  busy: _isWorking,
                  onTap: _confirmAndRestoreSale,
                ),
              ],
            )
          else if (actions.isEmpty)
            const _UnitMovementMessage(
              icon: Icons.info_outline_rounded,
              title: 'No Status Action Available',
              message: 'This stock unit does not allow a direct status change.',
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  _LifecycleActionButton(
                    action: action,
                    busy: _isWorking,
                    onTap: () => _confirmAndApply(action),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndApply(StockLifecycleAction action) async {
    final reason = await _showLifecycleReasonDialog(
      context,
      action: action,
      item: widget.item,
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _isWorking = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _controller.applyAction(
        item: widget.item,
        action: action,
        reason: reason,
      );
      widget.onChanged?.call();
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Stock status updated to ${action.targetStatus}.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: InvColors.shellPanelBg,
          ),
        );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      _showActionNotice(context, 'Status update failed: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmAndRestoreSale() async {
    const action = StockLifecycleAction(
      label: 'Restore To Inventory',
      targetStatus: 'Available',
      reasonHint: 'Enter sale return number, customer note or restore reason.',
    );
    final reason = await _showLifecycleReasonDialog(
      context,
      action: action,
      item: widget.item,
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _isWorking = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _saleRestoreController.restoreToInventory(
        item: widget.item,
        reason: reason,
      );
      widget.onChanged?.call();
      if (!mounted) return;
      final source = result.sourceNumber.trim();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              source.isEmpty
                  ? 'Stock restored to inventory.'
                  : 'Stock restored from sale $source.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: InvColors.shellPanelBg,
          ),
        );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      _showActionNotice(context, 'Sale restore failed: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }
}

class _LifecycleActionButton extends StatelessWidget {
  final StockLifecycleAction action;
  final bool busy;
  final VoidCallback onTap;

  const _LifecycleActionButton({
    required this.action,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = action.danger ? InvColors.danger : InvColors.brandGold;
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(13),
      child: Opacity(
        opacity: busy ? 0.55 : 1,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: action.danger ? const Color(0xFFFFF7F7) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.danger
                    ? Icons.warning_amber_rounded
                    : Icons.task_alt_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                action.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: action.danger ? InvColors.danger : InvColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _showLifecycleReasonDialog(
  BuildContext context, {
  required StockLifecycleAction action,
  required StockSearchResult item,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          action.label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: InvColors.textDark,
          ),
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.displayName} will move from ${item.status} to ${action.targetStatus}.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: InvColors.textBody,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                minLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: InvColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: action.reasonHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF7EF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: InvColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: InvColors.brandGold, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.length < 3) return;
              Navigator.of(context).pop(reason);
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action.danger ? InvColors.danger : InvColors.brandGold,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
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
                final batchCode = item.inventoryBatchCode;
                final path = Uri(
                  path: RoutePaths.stockInventory,
                  queryParameters: {
                    'metal': item.metalType,
                    if (batchCode.isNotEmpty) 'batch': batchCode,
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
    'Batch Code: ${item.inventoryBatchCode}',
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
