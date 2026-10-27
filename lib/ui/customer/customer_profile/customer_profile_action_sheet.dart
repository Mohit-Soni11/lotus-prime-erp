part of 'customer_profile_screen.dart';

extension _ProfileActionSheet on _CustomerProfileScreenState {
  void _showRecordActionSheet({
    required String title,
    required String subtitle,
    required List<CustomerProfileRecordAction> actions,
    List<CustomerLinkedDocumentModel> linkedDocuments = const [],
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CustomerProfileColors.bodyBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
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
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.brandGold.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.manage_search_rounded,
                      color: CustomerProfileColors.brandGold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: CustomerProfileColors.bodyTextMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (linkedDocuments.isNotEmpty) ...[
                _linkedDocumentsPanel(linkedDocuments, sheetContext),
                const SizedBox(height: 14),
              ],
              ...actions.map(
                (action) => _recordActionTile(action, sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linkedDocumentsPanel(
    List<CustomerLinkedDocumentModel> linkedDocuments,
    BuildContext sheetContext,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerProfileColors.historyBg.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerProfileColors.historyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: 17,
                color: CustomerProfileColors.historyText,
              ),
              SizedBox(width: 7),
              Text(
                'Linked Documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CustomerProfileColors.bodyTextMain,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...linkedDocuments.map(
            (document) => _linkedDocumentTile(document, sheetContext),
          ),
        ],
      ),
    );
  }

  Widget _linkedDocumentTile(
    CustomerLinkedDocumentModel document,
    BuildContext sheetContext,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            await Navigator.of(sheetContext).maybePop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _previewLinkedDocumentPdf(document);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CustomerProfileColors.bodyBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.clearBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_return_rounded,
                    size: 18,
                    color: CustomerProfileColors.clearText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${document.documentNo}  |  ${document.documentTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${document.formattedDate}  |  ${document.lineCountLabel}  |  Making ${document.formattedMakingReturned}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.formattedReturnValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: CustomerProfileColors.bodyTextMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomerProfileBillStatusChip(
                      label: document.statusLabel,
                      backgroundColor: CustomerProfileColors.clearBg,
                      textColor: CustomerProfileColors.clearText,
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Print linked document',
                  onPressed: () async {
                    await Navigator.of(sheetContext).maybePop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _printLinkedDocumentPdf(document);
                    });
                  },
                  icon: const Icon(
                    Icons.print_rounded,
                    size: 17,
                    color: CustomerProfileColors.historyText,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordActionTile(
    CustomerProfileRecordAction action,
    BuildContext sheetContext,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: action.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.of(sheetContext).maybePop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              action.onTap();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: action.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
