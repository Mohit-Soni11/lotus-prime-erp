part of 'due_collection_entry_screen.dart';

class _CollectionPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;
  final bool embedded;
  final bool inset;

  const _CollectionPanel({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
    this.embedded = false,
    this.inset = true,
  });

  @override
  Widget build(BuildContext context) {
    final bill = ctrl.selectedBill;
    final content = Container(
      margin: EdgeInsets.all(embedded || !inset ? 0 : 14),
      decoration: DueCollectionEntryStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: DueCollectionEntryColors.tableHeader,
            child: const Row(
              children: [
                Icon(DueCollectionEntryIcons.amount,
                    size: 19, color: DueCollectionEntryColors.brandGold),
                SizedBox(width: 8),
                Text(DueCollectionEntryStrings.collectionForm,
                    style: DueCollectionEntryStyles.sectionTitle),
              ],
            ),
          ),
          Expanded(
            child: bill == null
                ? const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: _NoSelectedBill(),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _CollectionForm(ctrl: ctrl, bill: bill),
                        ),
                      ),
                      _StickySaveFooter(
                        ctrl: ctrl,
                        onSave: onSave,
                        onSaveAndPrint: onSaveAndPrint,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
    if (embedded) return SizedBox(height: 760, child: content);
    return content;
  }
}

class _NoSelectedBill extends StatelessWidget {
  const _NoSelectedBill();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(DueCollectionEntryIcons.receipt,
                size: 46, color: DueCollectionEntryColors.textMuted),
            SizedBox(height: 12),
            Text('Select bill', style: DueCollectionEntryStyles.sectionTitle),
            SizedBox(height: 5),
            Text('Collection form will appear here.',
                style: DueCollectionEntryStyles.muted),
          ],
        ),
      ),
    );
  }
}

class _CollectionForm extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;
  const _CollectionForm({required this.ctrl, required this.bill});

  @override
  Widget build(BuildContext context) {
    final settlementValidation = ctrl.settlementValidationMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillSummaryBox(bill: bill),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackFields = constraints.maxWidth < 520;
            final amountInput = _AmountInput(
              label: 'Collection Amount',
              controller: ctrl.amountCtrl,
              icon: DueCollectionEntryIcons.amount,
              autofocusColor: DueCollectionEntryColors.brandGold,
              textStyle: DueCollectionEntryStyles.amount.copyWith(fontSize: 20),
            );
            final discountInput = _AmountInput(
              label: 'Discount / Waiver',
              controller: ctrl.discountCtrl,
              icon: DueCollectionEntryIcons.discount,
              autofocusColor: DueCollectionEntryColors.warning,
              textStyle: DueCollectionEntryStyles.amount.copyWith(
                  fontSize: 18, color: DueCollectionEntryColors.warning),
            );
            if (stackFields) {
              return Column(
                children: [
                  amountInput,
                  const SizedBox(height: 10),
                  discountInput,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 6, child: amountInput),
                const SizedBox(width: 10),
                Expanded(flex: 5, child: discountInput),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.fullDue,
                    onTap: ctrl.setFullDueAmount)),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.halfDue,
                    onTap: ctrl.setHalfDueAmount)),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: 'Clear Disc.', onTap: ctrl.clearDiscount)),
          ],
        ),
        if (settlementValidation != null) ...[
          const SizedBox(height: 10),
          _MessageBox(message: settlementValidation, isError: true),
        ],
        const SizedBox(height: 16),
        const Text('Payment Mode', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: DueCollectionPaymentMode.values
              .map((mode) => _ModeChip(
                  mode: mode,
                  selected: ctrl.paymentMode == mode,
                  onTap: () => ctrl.setPaymentMode(mode)))
              .toList(),
        ),
        if (ctrl.requiresBankAccount) ...[
          const SizedBox(height: 14),
          const Text('Bank Account', style: DueCollectionEntryStyles.label),
          const SizedBox(height: 7),
          _BankAccountDropdown(ctrl: ctrl),
          if (ctrl.needsUpiSetup) ...[
            const SizedBox(height: 8),
            const _MessageBox(
              message:
                  'Selected account has no UPI ID. Click Save to set UPI details first.',
              isError: true,
            ),
          ],
        ],
        const SizedBox(height: 14),
        _PromiseDateField(ctrl: ctrl),
        const SizedBox(height: 14),
        const Text('Notes', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl.notesCtrl,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Optional narration',
            hintStyle: DueCollectionEntryStyles.muted,
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: DueCollectionEntryColors.brandGold, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettlementPreview(ctrl: ctrl, bill: bill),
        if (ctrl.needsPromiseDate && ctrl.promiseDate == null) ...[
          const SizedBox(height: 10),
          const _MessageBox(
              message: 'Select next promise date for remaining due.',
              isError: true),
        ],
        if (ctrl.lastReceiptNo != null) ...[
          const SizedBox(height: 12),
          _ReceiptReadyBox(
            receiptNo: ctrl.lastReceiptNo!,
            billNo: bill.billNo,
            amount: ctrl.lastCollectedAmount,
            discount: ctrl.lastDiscountAmount,
            balance: ctrl.lastBalanceDue,
            mode: ctrl.lastPaymentModeLabel ?? ctrl.paymentMode.label,
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color autofocusColor;
  final TextStyle textStyle;

  const _AmountInput({
    required this.label,
    required this.controller,
    required this.icon,
    required this.autofocusColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          style: textStyle,
          decoration: InputDecoration(
            isDense: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
            prefixIcon: Icon(icon, color: autofocusColor),
            hintText: '0.00',
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: autofocusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseDateField extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _PromiseDateField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final required = ctrl.needsPromiseDate;
    final selected = ctrl.promiseDate;
    final color = required && selected == null
        ? DueCollectionEntryColors.warning
        : DueCollectionEntryColors.brandGold;
    final bg = required
        ? DueCollectionEntryColors.warningBg
        : DueCollectionEntryColors.panelSoft;
    final label = required ? 'Next Promise Date Required' : 'Next Promise Date';
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: required || selected != null ? 1 : 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: DueCollectionEntryStyles.label.copyWith(color: color)),
              const Spacer(),
              if (required || selected != null) ...[
                _TinyPromiseButton(
                    label: '7D', onTap: () => ctrl.setQuickPromiseDays(7)),
                const SizedBox(width: 6),
                _TinyPromiseButton(
                    label: '15D', onTap: () => ctrl.setQuickPromiseDays(15)),
                const SizedBox(width: 6),
                _TinyPromiseButton(
                    label: '30D', onTap: () => ctrl.setQuickPromiseDays(30)),
              ],
            ],
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selected ?? now.add(const Duration(days: 7)),
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) ctrl.setPromiseDate(picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: DueCollectionEntryStyles.flatPanel(color: bg),
              child: Row(
                children: [
                  Icon(DueCollectionEntryIcons.calendar,
                      size: 18, color: color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      selected == null
                          ? (required
                              ? 'Set follow-up for remaining balance'
                              : 'Optional for partial follow-up')
                          : DueCollectionEntryController.formatDate(selected),
                      style: DueCollectionEntryStyles.rowTitle.copyWith(
                          color: selected == null
                              ? DueCollectionEntryColors.textMuted
                              : DueCollectionEntryColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected != null)
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: () => ctrl.setPromiseDate(null),
                      icon: const Icon(DueCollectionEntryIcons.clear, size: 17),
                      color: DueCollectionEntryColors.textMuted,
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: DueCollectionEntryColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPromiseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TinyPromiseButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: DueCollectionEntryColors.bodyBorder),
        ),
        child: Text(label, style: DueCollectionEntryStyles.rowSub),
      ),
    );
  }
}
