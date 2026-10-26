part of 'customer_profile_screen.dart';

extension _ProfileRecordActions on _CustomerProfileScreenState {
  void _showBillActions(CustomerBillModel bill) {
    _showRecordActionSheet(
      title: 'Sales Bill ${bill.billNo}',
      subtitle: bill.hasLinkedDocuments
          ? 'Original invoice is locked. Linked return documents are tracked below.'
          : bill.isFromAdvanceOrder
              ? 'Converted from ${bill.advanceSourceLabel}. Edit, preview, or print.'
              : 'Edit the sale, preview the invoice, or print a clean copy.',
      linkedDocuments: bill.linkedDocuments,
      actions: [
        if (bill.hasLinkedDocuments)
          CustomerProfileRecordAction(
            icon: Icons.lock_open_rounded,
            title: 'View Original Invoice',
            subtitle:
                'Open the locked posted bill with every original item line.',
            color: CustomerProfileColors.historyText,
            onTap: () {
              _previewBillPdf(
                bill.id,
                mode: SalesInvoicePdfMode.postedOriginal,
              );
            },
          )
        else
          CustomerProfileRecordAction(
            icon: Icons.edit_note_rounded,
            title: 'Edit Sales Bill',
            subtitle:
                'Continue in the sales workspace with this bill selected.',
            color: CustomerProfileColors.editText,
            onTap: () {
              if (widget.onEditBill != null) {
                widget.onEditBill!(bill.id);
              } else {
                _showInfoFeedback('Sales editing is not configured yet.');
              }
            },
          ),
        CustomerProfileRecordAction(
          icon: Icons.visibility_rounded,
          title: bill.hasLinkedDocuments ? 'View Updated PDF' : 'View Invoice',
          subtitle: bill.hasLinkedDocuments
              ? 'Open the latest statement after posted returns.'
              : 'Open the complete printable invoice preview.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewBillPdf(
              bill.id,
              mode: bill.hasLinkedDocuments
                  ? SalesInvoicePdfMode.currentStatement
                  : SalesInvoicePdfMode.postedOriginal,
            );
          },
        ),
        CustomerProfileRecordAction(
          icon: Icons.print_rounded,
          title:
              bill.hasLinkedDocuments ? 'Print Updated PDF' : 'Print Invoice',
          subtitle: bill.hasLinkedDocuments
              ? 'Print the current return-adjusted statement.'
              : 'Send the finished invoice directly to the printer.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printBillPdf(
              bill.id,
              mode: bill.hasLinkedDocuments
                  ? SalesInvoicePdfMode.currentStatement
                  : SalesInvoicePdfMode.postedOriginal,
            );
          },
        ),
        if (bill.dueAmount > 0.5)
          CustomerProfileRecordAction(
            icon: Icons.payments_rounded,
            title: 'Collect Due',
            subtitle: 'Open due collection with this invoice selected.',
            color: CustomerProfileColors.duesAmount,
            onTap: () {
              if (widget.onCollectDue != null) {
                widget.onCollectDue!(widget.customerId, bill.billNo);
              } else {
                _showInfoFeedback('Due collection is not configured yet.');
              }
            },
          ),
      ],
    );
  }

  void _showGirviActions(CustomerLoanModel loan) {
    _showRecordActionSheet(
      title: 'Girvi Ticket ${loan.loanNo}',
      subtitle: 'View or print this pledged-loan receipt.',
      actions: [
        CustomerProfileRecordAction(
          icon: Icons.receipt_long_rounded,
          title: 'View Girvi Receipt',
          subtitle: 'Open the receipt as a clean PDF preview only.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewGirviInvoice(loan.id);
          },
        ),
        CustomerProfileRecordAction(
          icon: Icons.print_rounded,
          title: 'Print Girvi Receipt',
          subtitle: 'Print the professional pledge receipt.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printGirviInvoice(loan.id);
          },
        ),
      ],
    );
  }

  void _showAdvanceActions(CustomerAdvanceOrderModel order) {
    _showRecordActionSheet(
      title: 'Advance Order ${order.orderNo}',
      subtitle: 'Edit, preview, or print this advance booking record.',
      actions: [
        CustomerProfileRecordAction(
          icon: Icons.edit_note_rounded,
          title: 'Edit Advance Order',
          subtitle:
              'Continue in the advance workspace with this order selected.',
          color: CustomerProfileColors.editText,
          onTap: () {
            if (widget.onEditAdvance != null) {
              widget.onEditAdvance!(order.id);
            } else {
              _showInfoFeedback('Advance editing is not configured yet.');
            }
          },
        ),
        CustomerProfileRecordAction(
          icon: Icons.visibility_rounded,
          title: 'View Advance Receipt',
          subtitle: 'Open the complete printable booking preview.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewAdvancePdf(order);
          },
        ),
        CustomerProfileRecordAction(
          icon: Icons.print_rounded,
          title: 'Print Advance Receipt',
          subtitle: 'Send the advance receipt directly to the printer.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printAdvancePdf(order);
          },
        ),
        if (order.isPending || order.isReady)
          CustomerProfileRecordAction(
            icon: Icons.point_of_sale_rounded,
            title: 'Convert to Sale',
            subtitle: 'Carry this booking into the sales workspace.',
            color: CustomerProfileColors.advanceConvertBtn,
            onTap: () {
              _logic.triggerConvertAdvanceToSale(order.id);
            },
          ),
      ],
    );
  }

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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                  fontSize: 13,
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
                          fontSize: 13,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                        fontSize: 13,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
