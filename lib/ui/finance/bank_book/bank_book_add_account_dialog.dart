// =============================================================================
// FILE        : bank_book_add_account_dialog.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI
// DESCRIPTION : Dialog to add a new bank account to the ERP.
//               Fields: Account Name, Bank Name, Account Number, IFSC,
//               Branch, Holder Name, UPI ID, Account Type, Opening Balance.
//               Validates required fields before saving.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class BankBookAddAccountDialog extends StatefulWidget {
  final BankBookController ctrl;
  const BankBookAddAccountDialog({super.key, required this.ctrl});

  @override
  State<BankBookAddAccountDialog> createState() =>
      _BankBookAddAccountDialogState();
}

class _BankBookAddAccountDialogState extends State<BankBookAddAccountDialog>
    with SingleTickerProviderStateMixin {
  // â”€â”€ Animation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // â”€â”€ Form Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _accountNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController();

  BankAccountType _accountType = BankAccountType.current;
  bool _isPrimary = false;
  bool _isSaving = false;

  // â”€â”€ Validation errors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String? _nameError;
  String? _bankError;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _accountNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _holderNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _openingBalCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = _accountNameCtrl.text.trim().isEmpty
          ? 'Account name is required'
          : null;
      _bankError =
          _bankNameCtrl.text.trim().isEmpty ? 'Bank name is required' : null;
      _numberError = _accountNumberCtrl.text.trim().isEmpty
          ? 'Account number is required'
          : null;
      if (_nameError != null || _bankError != null || _numberError != null) {
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final success = await widget.ctrl.addAccount(
      accountName: _accountNameCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      accountType: _accountType,
      holderName: _holderNameCtrl.text.trim().isEmpty
          ? null
          : _holderNameCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().isEmpty
          ? null
          : _ifscCtrl.text.trim().toUpperCase(),
      branchName:
          _branchCtrl.text.trim().isEmpty ? null : _branchCtrl.text.trim(),
      upiId: _upiIdCtrl.text.trim().isEmpty ? null : _upiIdCtrl.text.trim(),
      openingBalance: double.tryParse(_openingBalCtrl.text.trim()) ?? 0.0,
      isPrimary: _isPrimary,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: 'Bank account added successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: BankBookColors.bodyPanel,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _header(),

                // â”€â”€ Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: _form(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        color: BankBookColors.shellPanel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BankBookColors.brandGoldLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(BankBookIcons.addAccount,
              size: 16, color: BankBookColors.brandGold),
        ),
        const SizedBox(width: 12),
        Text(BankBookStrings.addAccount,
            style: BankBookStyles.appBarTitle
                .copyWith(fontSize: 16, letterSpacing: 0.5)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: BankBookColors.shellBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close_rounded,
                size: 16, color: BankBookColors.shellMuted),
          ),
        ),
      ]),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Row 1: Account Name + Bank Name
        Row(children: [
          Expanded(
              child: _field(
            label: BankBookStrings.accountName,
            ctrl: _accountNameCtrl,
            hint: BankBookStrings.accountNameHint,
            icon: BankBookIcons.bankAccount,
            errorText: _nameError,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _field(
            label: BankBookStrings.bankName,
            ctrl: _bankNameCtrl,
            hint: BankBookStrings.bankNameHint,
            icon: BankBookIcons.moduleIcon,
            errorText: _bankError,
          )),
        ]),
        const SizedBox(height: 16),

        // Row 2: Account Number + IFSC
        Row(children: [
          Expanded(
              child: _field(
            label: BankBookStrings.accountNumber,
            ctrl: _accountNumberCtrl,
            hint: 'XXXX XXXX XXXX',
            icon: Icons.tag_rounded,
            errorText: _numberError,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _field(
            label: BankBookStrings.ifscCode,
            ctrl: _ifscCtrl,
            hint: 'e.g. SBIN0001234',
            icon: Icons.code_rounded,
            textCapitalization: TextCapitalization.characters,
          )),
        ]),
        const SizedBox(height: 16),

        // Row 3: Holder Name + Branch
        Row(children: [
          Expanded(
              child: _field(
            label: BankBookStrings.holderName,
            ctrl: _holderNameCtrl,
            hint: 'As per bank records',
            icon: Icons.person_outline_rounded,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _field(
            label: BankBookStrings.branchName,
            ctrl: _branchCtrl,
            hint: 'e.g. Main Branch, Mumbai',
            icon: Icons.location_on_outlined,
          )),
        ]),
        const SizedBox(height: 16),

        // Row 4: UPI ID + Opening Balance
        Row(children: [
          Expanded(
              child: _field(
            label: BankBookStrings.upiId,
            ctrl: _upiIdCtrl,
            hint: 'e.g. shop@upi',
            icon: BankBookIcons.upi,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _field(
            label: BankBookStrings.openingBal,
            ctrl: _openingBalCtrl,
            hint: BankBookStrings.openingBalHint,
            icon: BankBookIcons.openingBalance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: 'â‚¹  ',
          )),
        ]),
        const SizedBox(height: 16),

        // Account Type
        _label(BankBookStrings.accountType),
        const SizedBox(height: 8),
        _AccountTypeSelector(
          selected: _accountType,
          onChanged: (t) => setState(() => _accountType = t),
        ),
        const SizedBox(height: 16),

        // Set as Primary Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BankBookColors.brandGoldLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: BankBookColors.brandGold.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(BankBookIcons.primaryStar,
                color: BankBookColors.brandGold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(BankBookStrings.setPrimary,
                      style: BankBookStyles.labelPrimary),
                  Text('Shown first in account list',
                      style: BankBookStyles.labelMuted),
                ],
              ),
            ),
            Switch(
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
              activeThumbColor: BankBookColors.brandGold,
              activeTrackColor: BankBookColors.brandGold.withValues(alpha: 0.3),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BankBookColors.brandGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF111827),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(BankBookStrings.saveAccount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    )),
          ),
        ),

        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(BankBookStrings.cancel,
                style: TextStyle(color: BankBookColors.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: BankBookStyles.labelSecondary
            .copyWith(fontWeight: FontWeight.w600));
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: BankBookStyles.labelPrimary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: BankBookStyles.labelMuted,
            prefixText: prefixText,
            prefixIcon:
                Icon(icon, size: 16, color: BankBookColors.textSecondary),
            errorText: errorText,
            filled: true,
            fillColor: BankBookColors.toggleInactiveBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BankBookColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: BankBookColors.brandGold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BankBookColors.debitAccent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Account Type Selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AccountTypeSelector extends StatelessWidget {
  final BankAccountType selected;
  final ValueChanged<BankAccountType> onChanged;

  const _AccountTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BankAccountType.values.map((type) {
        final isActive = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? BankBookColors.brandGold.withValues(alpha: 0.15)
                  : BankBookColors.toggleInactiveBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? BankBookColors.brandGold
                    : BankBookColors.bodyBorder,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Text(type.displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? BankBookColors.brandGold
                      : BankBookColors.textSecondary,
                )),
          ),
        );
      }).toList(),
    );
  }
}
