part of '../../pos_invoice_preview_screen.dart';

class _InvoiceExportTarget {
  final MetalType? metal;
  final bool includeAllMetals;
  final String title;
  final String subtitle;
  final IconData icon;

  const _InvoiceExportTarget._({
    required this.metal,
    required this.includeAllMetals,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory _InvoiceExportTarget.all(List<MetalType> metals) {
    final names = metals.map((metal) => metal.displayName).join(' + ');
    return _InvoiceExportTarget._(
      metal: null,
      includeAllMetals: true,
      title: 'All Metals',
      subtitle: names.isEmpty ? 'Complete invoice PDF' : '$names in one PDF',
      icon: Icons.auto_awesome_motion_rounded,
    );
  }

  factory _InvoiceExportTarget.metal(MetalType metal) {
    return _InvoiceExportTarget._(
      metal: metal,
      includeAllMetals: false,
      title: '${metal.displayName} Invoice',
      subtitle: 'Export only ${metal.displayName.toLowerCase()} pages',
      icon: Icons.receipt_long_rounded,
    );
  }

  String get successLabel =>
      includeAllMetals ? 'All metals invoice PDF' : '$title PDF';
}

extension _PosInvoiceExportPicker on _PosInvoicePreviewScreenState {
  Future<_InvoiceExportTarget?> _showInvoiceExportTargetPicker() {
    final metals = _invCtrl.presentMetals;
    if (metals.isEmpty) return Future.value(null);

    final targets = [
      _InvoiceExportTarget.all(metals),
      ...metals.map(_InvoiceExportTarget.metal),
    ];

    return showDialog<_InvoiceExportTarget>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SalesPosColors.shellPanelBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SalesPosColors.shellBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              SalesPosColors.brandGold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SalesPosColors.brandGold
                                .withValues(alpha: 0.32),
                          ),
                        ),
                        child: const Icon(
                          Icons.file_download_rounded,
                          color: SalesPosColors.brandGold,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPORT INVOICE PDF',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SalesPosColors.shellTextMuted,
                                fontSize: SalesPosStyles.fontCaption,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose invoice scope',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SalesPosColors.shellTextTitle,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: SalesPosColors.shellTextMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: targets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final target = targets[index];
                        return _InvoiceExportTargetTile(
                          target: target,
                          isPrimary: target.includeAllMetals,
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(target),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InvoiceExportTargetTile extends StatelessWidget {
  final _InvoiceExportTarget target;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InvoiceExportTargetTile({
    required this.target,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isPrimary ? SalesPosColors.brandGold : SalesPosColors.shellTextTitle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPrimary
                ? SalesPosColors.brandGold.withValues(alpha: 0.10)
                : SalesPosColors.shellBg.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? SalesPosColors.brandGold.withValues(alpha: 0.38)
                  : SalesPosColors.shellBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                ),
                child: Icon(target.icon, color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: SalesPosStyles.fontInput,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      target.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SalesPosColors.shellTextMuted,
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.78),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
