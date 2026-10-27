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
}
