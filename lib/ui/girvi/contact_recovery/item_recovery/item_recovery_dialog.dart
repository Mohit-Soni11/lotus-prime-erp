import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/girvi/contact_recovery_model.dart';
import '../../../../models/girvi/recovery_pledged_item_detail.dart';
import '../../../../theme/girvi/girvi_theme.dart';

part 'item_recovery_sections.dart';

class ItemRecoveryResult {
  const ItemRecoveryResult({
    required this.recoveredAmount,
    required this.paymentMethod,
    required this.dispositionMethod,
    required this.bankAccountId,
    required this.note,
  });

  final double recoveredAmount;
  final RecoverySettlementPaymentMethod? paymentMethod;
  final String dispositionMethod;
  final int? bankAccountId;
  final String note;
}

class ItemRecoveryDialog extends StatefulWidget {
  const ItemRecoveryDialog({
    super.key,
    required this.item,
    required this.pledgedItems,
    required this.bankAccounts,
  });

  final ContactRecoveryCase item;
  final List<RecoveryPledgedItemDetail> pledgedItems;
  final List<RecoveryBankAccountOption> bankAccounts;

  @override
  State<ItemRecoveryDialog> createState() => _ItemRecoveryDialogState();
}

class _ItemRecoveryDialogState extends State<ItemRecoveryDialog> {
  late final TextEditingController _recoveredController;
  late final TextEditingController _noteController;
  RecoverySettlementPaymentMethod _paymentMethod =
      RecoverySettlementPaymentMethod.cash;
  String _dispositionMethod = 'MELTED';
  int? _bankAccountId;
  String? _error;

  double get _amountDue => widget.item.verifiedTotalPayable;
  bool get _isMelted => _dispositionMethod == 'MELTED';
  double get _recoveredAmount =>
      double.tryParse(_recoveredController.text.replaceAll(',', '').trim()) ??
      0;
  String get _actionLabel =>
      _isMelted ? 'Mark Melted & Close Account' : 'Record Sale & Close Account';

  @override
  void initState() {
    super.initState();
    _recoveredController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _recoveredController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = _caseDetails();
                    final recovery = _recoveryDetails();
                    if (constraints.maxWidth < 690) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          const SizedBox(height: 14),
                          recovery
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 285, child: details),
                        const SizedBox(width: 14),
                        Expanded(child: recovery),
                      ],
                    );
                  },
                ),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        decoration: const BoxDecoration(
          color: GirviColors.shellBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_rounded,
                color: GirviColors.brandGold, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete Item Recovery',
                      style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text(widget.item.loan.ticketNo,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _caseDetails() {
    final account = widget.item.account;
    final items = widget.pledgedItems.isEmpty
        ? [RecoveryPledgedItemDetail.fromLoan(widget.item.loan)]
        : widget.pledgedItems;
    return _RecoveryPanel(
      title: 'Pledge Details',
      icon: Icons.diamond_outlined,
      children: [
        Text(account.customerName,
            style: _boldText(size: 17, color: GirviColors.textDark)),
        const SizedBox(height: 10),
        _RecoveryLine('Mobile', account.customerMobile),
        _RecoveryLine(
          'Maturity date',
          widget.item.loan.maturityDate == null
              ? 'Not recorded'
              : DateFormat('dd MMM yyyy')
                  .format(widget.item.loan.maturityDate!),
        ),
        _RecoveryLine('Principal due', _money(account.principalDue)),
        _RecoveryLine('Interest due', _money(widget.item.verifiedInterestDue)),
        const SizedBox(height: 8),
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _PledgedItemCard(item: items[index], index: index + 1),
        ],
      ],
    );
  }

  Widget _recoveryDetails() => _RecoveryPanel(
        title: 'Recovery Details',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          _recoveryDropdown<String>(
            label: 'Item recovery method',
            value: _dispositionMethod,
            entries: const [
              DropdownMenuItem(value: 'MELTED', child: Text('Item melted')),
              DropdownMenuItem(value: 'SOLD', child: Text('Item sold')),
            ],
            onChanged: (value) => setState(() {
              _dispositionMethod = value;
              _error = null;
            }),
          ),
          if (!_isMelted) ...[
            const SizedBox(height: 14),
            Text('Actual sale proceeds received',
                style: _boldText(size: 13, color: GirviColors.textDark)),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('item-recovery-amount'),
              controller: _recoveredController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              onChanged: (_) => setState(() => _error = null),
              style: _boldText(size: 16, color: GirviColors.textDark),
              decoration: _fieldDecoration('Rs', isAmount: true),
            ),
            const SizedBox(height: 14),
            _recoveryDropdown<RecoverySettlementPaymentMethod>(
              label: 'Sale proceeds received by',
              value: _paymentMethod,
              entries: [
                for (final method in RecoverySettlementPaymentMethod.values)
                  DropdownMenuItem(value: method, child: Text(method.label)),
              ],
              onChanged: (value) => setState(() {
                _paymentMethod = value;
                if (!value.requiresBankAccount) _bankAccountId = null;
                _error = null;
              }),
            ),
          ],
          if (!_isMelted && _paymentMethod.requiresBankAccount) ...[
            const SizedBox(height: 12),
            _recoveryDropdown<int?>(
              label: 'Receiving bank account',
              value: _bankAccountId,
              entries: [
                for (final bank in widget.bankAccounts)
                  DropdownMenuItem(value: bank.id, child: Text(bank.label)),
              ],
              onChanged: (value) => setState(() {
                _bankAccountId = value;
                _error = null;
              }),
            ),
          ],
          const SizedBox(height: 16),
          _amountSummary(),
          const SizedBox(height: 14),
          Text(
            _isMelted
                ? 'The item will be marked melted and this account will close today. No cash receipt is recorded. The full due remains in the invoice as Recovery Due at Closure.'
                : 'Enter only the actual sale proceeds received today. Any shortfall remains recorded in this invoice as Recovery Due at Closure.',
            style: _boldText(size: 12.5, color: GirviColors.textDark),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: _boldText(size: 13, color: GirviColors.textDark),
            decoration: _fieldDecoration('Additional note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _RecoveryError(message: _error!),
          ],
        ],
      );

  Widget _amountSummary() => _RecoveryPanel(
        title: 'Recovery Summary',
        icon: Icons.receipt_long_outlined,
        background: GirviColors.bodyBg,
        children: [
          _RecoveryLine(
              'Principal due', _money(widget.item.account.principalDue)),
          _RecoveryLine(
              'Interest due', _money(widget.item.verifiedInterestDue)),
          const Divider(height: 16),
          _RecoveryLine('Total due', _money(_amountDue),
              strong: true,
              labelColor: GirviColors.danger,
              valueColor: GirviColors.danger),
        ],
      );

  Widget _actions() => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: GirviColors.cardBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: _boldText(size: 13, color: GirviColors.textDark)),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _complete,
              style: FilledButton.styleFrom(
                backgroundColor: GirviColors.danger,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(_actionLabel,
                  style: _boldText(size: 12.5, color: Colors.white)),
            ),
          ],
        ),
      );

  void _complete() {
    if (!_isMelted && (!_recoveredAmount.isFinite || _recoveredAmount <= 0)) {
      setState(() => _error = 'Enter the actual sale proceeds received.');
      return;
    }
    if (!_isMelted &&
        _paymentMethod.requiresBankAccount &&
        _bankAccountId == null) {
      setState(
          () => _error = 'Select the bank account receiving the recovery.');
      return;
    }
    Navigator.of(context).pop(ItemRecoveryResult(
      recoveredAmount: _isMelted ? 0 : _recoveredAmount,
      paymentMethod: _isMelted ? null : _paymentMethod,
      dispositionMethod: _dispositionMethod,
      bankAccountId: _bankAccountId,
      note: _noteController.text.trim(),
    ));
  }

  static TextStyle _boldText({required double size, required Color color}) =>
      GoogleFonts.inter(
          color: color, fontSize: size, fontWeight: FontWeight.w800);

  static String _money(double amount) =>
      'Rs ${NumberFormat('#,##,##0.##', 'en_IN').format(amount)}';
}
