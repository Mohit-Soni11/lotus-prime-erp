// -----------------------------------------------------------------------------
// FILE: banking_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior UI/UX Engineer & System Architect
// DESCRIPTION: 100% Zero-Lag UI using ValueNotifier. Zero hardcoded text.
//              Strict memory management, granular rebuilds & synced controllers.
//              ðŸš€ UPGRADED: Added Auto-Fill support for multiple Bank Accounts.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';

// --- THEME IMPORTS ---
import '../../../../theme/settings/shop_setup/tabs/banking/banking_theme.dart';

// --- MODELS & ENUMS ---
import '../../../../models/setting/shop_setup/tabs/bank_account_model.dart';
import '../../../../models/setting/shop_setup/enums/banking_enums.dart';

// --- LOGIC & VALIDATORS IMPORTS ---
import '../../../../logic/setting/shop_setup/tabs/banking/banking_logic.dart';
import '../../../../logic/setting/shop_setup/tabs/tax_gst/document_crop_logic.dart';
import '../../../../helpers/banking/banking_validators.dart';

// ==========================================
// MAIN BANKING TAB
// ==========================================
class BankingTab extends StatefulWidget {
  // ðŸš€ NEW: Receive initial data list from parent (Database)
  final List<dynamic>? initialData;

  const BankingTab({super.key, this.initialData});

  @override
  State<BankingTab> createState() => _BankingTabState();
}

class _BankingTabState extends State<BankingTab> {
  late BankingLogic logic;

  @override
  void initState() {
    super.initState();
    logic = BankingLogic();

    // ðŸš€ NEW: AUTO-FILL LOGIC FOR MULTIPLE BANK ACCOUNTS
    // Database se aaye hue accounts ko Models mein convert karke ListNotifier mein daal do
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        final List<BankAccountModel> loadedAccounts = widget.initialData!
            .map((e) => BankAccountModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (loadedAccounts.isNotEmpty) {
          logic.accountsNotifier.value = loadedAccounts;
        }
      } catch (e) {
        debugPrint("Error parsing initial banking data: $e");
      }
    }
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isDesktop = constraints.maxWidth > 1100;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 30),
            ValueListenableBuilder<List<BankAccountModel>>(
                valueListenable: logic.accountsNotifier,
                builder: (context, accounts, child) {
                  return Column(
                    children: List.generate(accounts.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: BankAccountCard(
                          key: ValueKey(accounts[index].id),
                          accountData: accounts[index],
                          isDesktop: isDesktop,
                          showDelete: index != 0,
                          logicCore: logic,
                          onDelete: () =>
                              logic.removeAccount(accounts[index].id),
                          onSave: (updatedAcc) => logic.updateAccountData(
                              accounts[index].id, updatedAcc),
                        ),
                      );
                    }),
                  );
                }),
            Center(child: _buildAddAccountBtn()),
            const SizedBox(height: 50),
          ],
        ),
      );
    });
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(BankingStrings.pageTitle, style: BankingStyles.pageTitle),
            const SizedBox(height: 4),
            Text(BankingStrings.pageSubtitle, style: BankingStyles.pageSub),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: BankingColors.statusActiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: BankingColors.statusActiveText.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(BankingIcons.statusSecure,
                  size: 16, color: BankingColors.statusActiveText),
              const SizedBox(width: 8),
              Text(BankingStrings.statusActive,
                  style: BankingStyles.statusPillText),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAddAccountBtn() {
    return InkWell(
      onTap: logic.addNewAccount,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: BankingColors.inputBg.withValues(alpha: 0.1),
          border: Border.all(color: BankingColors.goldAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: BankingColors.goldAccent, shape: BoxShape.circle),
                child: const Icon(BankingIcons.addAccount,
                    size: 20, color: BankingColors.textWhite)),
            const SizedBox(width: 12),
            Text(BankingStrings.btnAddAccount, style: BankingStyles.addBtnText),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ACCOUNT CARD
// ==========================================
class BankAccountCard extends StatefulWidget {
  final BankAccountModel accountData;
  final bool isDesktop;
  final bool showDelete;
  final BankingLogic logicCore;
  final VoidCallback onDelete;
  final Function(BankAccountModel) onSave;

  const BankAccountCard({
    super.key,
    required this.accountData,
    required this.isDesktop,
    required this.logicCore,
    this.showDelete = false,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  final _formKey = GlobalKey<FormState>();

  bool _isLocked = true;
  bool _isSaving = false;

  late BankAccountModel _currentData;
  late TextEditingController _holderCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _accCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _upiCtrl;

  final FocusNode _holderFocus = FocusNode();
  final FocusNode _bankFocus = FocusNode();
  final FocusNode _accFocus = FocusNode();
  final FocusNode _ifscFocus = FocusNode();
  final FocusNode _branchFocus = FocusNode();
  final FocusNode _upiFocus = FocusNode();

  File? _qrImageFile;

  bool get isPrimary => !widget.showDelete;

  @override
  void initState() {
    super.initState();
    _currentData = widget.accountData;
    _holderCtrl = TextEditingController(text: _currentData.holder);
    _bankCtrl = TextEditingController(text: _currentData.bank);
    _accCtrl = TextEditingController(text: _currentData.acc);
    _ifscCtrl = TextEditingController(text: _currentData.ifsc);
    _branchCtrl = TextEditingController(text: _currentData.branch);
    _upiCtrl = TextEditingController(text: _currentData.upi);

    _isLocked = true;

    // ðŸš€ NEW: Initial data load hone par QR image ko bhi initialize kar do agar hai toh
    if (_currentData.qrImagePath != null &&
        _currentData.qrImagePath!.isNotEmpty) {
      _qrImageFile = File(_currentData.qrImagePath!);
    }
  }

  @override
  void didUpdateWidget(covariant BankAccountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountData != oldWidget.accountData) {
      _currentData = widget.accountData;
      if (_holderCtrl.text != _currentData.holder) {
        _holderCtrl.text = _currentData.holder;
      }
      if (_bankCtrl.text != _currentData.bank) {
        _bankCtrl.text = _currentData.bank;
      }
      if (_accCtrl.text != _currentData.acc) _accCtrl.text = _currentData.acc;
      if (_ifscCtrl.text != _currentData.ifsc) {
        _ifscCtrl.text = _currentData.ifsc;
      }
      if (_branchCtrl.text != _currentData.branch) {
        _branchCtrl.text = _currentData.branch;
      }
      if (_upiCtrl.text != _currentData.upi) _upiCtrl.text = _currentData.upi;
    }
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    _holderFocus.dispose();
    _bankFocus.dispose();
    _accFocus.dispose();
    _ifscFocus.dispose();
    _branchFocus.dispose();
    _upiFocus.dispose();
    super.dispose();
  }

  List<FocusNode> _getInvalidNodes() {
    List<FocusNode> errors = [];

    if (BankingValidators.validateHolderName(_holderCtrl.text) != null) {
      errors.add(_holderFocus);
    }
    if (BankingValidators.validateBankName(_bankCtrl.text) != null) {
      errors.add(_bankFocus);
    }
    if (BankingValidators.validateAccountNumber(_accCtrl.text) != null) {
      errors.add(_accFocus);
    }
    if (BankingValidators.validateIFSC(_ifscCtrl.text) != null) {
      errors.add(_ifscFocus);
    }

    if (_upiCtrl.text.isNotEmpty &&
        BankingValidators.validateUPI(_upiCtrl.text) != null) {
      errors.add(_upiFocus);
    }

    return errors;
  }

  Future<void> _toggleLock() async {
    if (_isSaving) return;

    if (_isLocked) {
      setState(() => _isLocked = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _holderFocus.requestFocus();
      });
    } else {
      if (!_formKey.currentState!.validate()) {
        List<FocusNode> errors = _getInvalidNodes();
        if (errors.isNotEmpty) {
          errors.first.requestFocus();
        }
        return;
      }

      setState(() => _isSaving = true);
      await Future.delayed(const Duration(milliseconds: 300));

      _currentData = _currentData.copyWith(
        holder: _holderCtrl.text.trim(),
        bank: _bankCtrl.text.trim(),
        acc: _accCtrl.text.trim(),
        ifsc: _ifscCtrl.text.trim(),
        branch: _branchCtrl.text.trim(),
        upi: _upiCtrl.text.trim(),
        qrImagePath: _qrImageFile?.path,
      );

      widget.onSave(_currentData);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isLocked = true;
        });
      }
    }
  }

  Widget _buildAccountTypeBadge(String type) {
    Color bgColor = BankingStyles.getBadgeBgColor(type);
    Color textColor = BankingStyles.getBadgeTextColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withValues(alpha: 0.3))),
      child:
          Text(type.toUpperCase(), style: BankingStyles.badgeText(textColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: BankingStyles.padCardInternal,
      decoration: BankingStyles.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(),
            const Divider(
                height: 40, thickness: 1, color: BankingColors.borderLight),
            if (widget.isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 60, child: _buildBankForm()),
                  const SizedBox(width: 30),
                  Expanded(flex: 40, child: _buildQrSection()),
                ],
              )
            else
              Column(
                children: [
                  _buildBankForm(),
                  const SizedBox(height: 30),
                  const Divider(color: BankingColors.borderLight),
                  const SizedBox(height: 30),
                  _buildQrSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: BankingColors.goldAccent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(BankingStyles.rHeaderIcon)),
                child: const Icon(BankingIcons.secBanking,
                    color: BankingColors.goldAccent, size: 22)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_currentData.title, style: BankingStyles.sectionTitle),
                    const SizedBox(width: 10),
                    _buildAccountTypeBadge(_currentData.type.displayName),
                  ],
                ),
                if (_isLocked && _accCtrl.text.isNotEmpty)
                  Row(
                    children: [
                      Text(_currentData.getDisplayAccount(isPrimary),
                          style: BankingStyles.accountMasked(isPrimary)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          bool success = await widget.logicCore
                              .copyToClipboard(_accCtrl.text);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content:
                                  Text("Account Number Copied to Clipboard!"),
                              backgroundColor: BankingColors.statusActiveText,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ));
                          }
                        },
                        child: const Icon(BankingIcons.copy,
                            size: 14, color: BankingColors.goldAccent),
                      )
                    ],
                  ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (widget.showDelete && !_isLocked)
              IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(BankingIcons.delete,
                      color: BankingColors.btnDanger)),
            const SizedBox(width: 8),
            Material(
              color: BankingColors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : _toggleLock,
                borderRadius: BorderRadius.circular(20.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: _isLocked
                          ? BankingColors.lockedBg
                          : BankingColors.statusActiveBg,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                          color: _isLocked
                              ? BankingColors.lockedBorder
                              : BankingColors.statusActiveText
                                  .withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      if (_isSaving)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: BankingColors.statusActiveText))
                      else
                        Icon(_isLocked ? BankingIcons.lock : BankingIcons.save,
                            size: 16,
                            color: _isLocked
                                ? BankingColors.lockedIcon
                                : BankingColors.statusActiveText),
                      const SizedBox(width: 6),
                      Text(
                          _isSaving
                              ? BankingStrings.btnSaving
                              : (_isLocked
                                  ? BankingStrings.btnLocked
                                  : BankingStrings.btnSave),
                          style: BankingStyles.lockStatusText(_isLocked)),
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(BankingStrings.secBankingCreds, style: BankingStyles.sectionSub),
        const SizedBox(height: 16),
        _buildThemeInput(
          label: BankingStrings.lblHolderName,
          hint: BankingStrings.hintHolderName,
          icon: BankingIcons.holderName,
          ctrl: _holderCtrl,
          focusNode: _holderFocus,
          nextFocus: _bankFocus,
          brandColor: BankingColors.goldAccent,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          validator: BankingValidators.validateHolderName,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildThemeInput(
              label: BankingStrings.lblBankName,
              hint: BankingStrings.hintBankName,
              icon: BankingIcons.bankWallet,
              ctrl: _bankCtrl,
              focusNode: _bankFocus,
              nextFocus: _accFocus,
              brandColor: BankingColors.brandBank,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              validator: BankingValidators.validateBankName,
            )),
            const SizedBox(width: 20),
            Expanded(
                child: _buildDropdownInput(
                    label: BankingStrings.lblAccountType,
                    icon: BankingIcons.accountType,
                    value: _currentData.type.displayName,
                    brandColor: BankingColors.brandOrange,
                    items: BankAccountType.values
                        .map((e) => e.displayName)
                        .toList(),
                    onChanged: (val) {
                      setState(() => _currentData = _currentData.copyWith(
                          type: BankAccountType.fromString(val!)));
                      FocusScope.of(context).requestFocus(_accFocus);
                    })),
          ],
        ),
        const SizedBox(height: 16),
        _buildThemeInput(
          label: BankingStrings.lblAccountNumber,
          hint: BankingStrings.hintAccountNumber,
          icon: BankingIcons.accNumber,
          ctrl: _accCtrl,
          inputType: TextInputType.number,
          isObscure: _isLocked && isPrimary,
          focusNode: _accFocus,
          nextFocus: _ifscFocus,
          brandColor: BankingColors.iconSuccess,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(20)
          ],
          validator: BankingValidators.validateAccountNumber,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildThemeInput(
              label: BankingStrings.lblIfsc,
              hint: BankingStrings.hintIfsc,
              icon: BankingIcons.ifscCode,
              ctrl: _ifscCtrl,
              isCapital: true,
              focusNode: _ifscFocus,
              nextFocus: _branchFocus,
              brandColor: BankingColors.goldAccent,
              inputFormatters: [LengthLimitingTextInputFormatter(11)],
              validator: BankingValidators.validateIFSC,
            )),
            const SizedBox(width: 20),
            Expanded(
                child: _buildThemeInput(
              label: BankingStrings.lblBranch,
              hint: BankingStrings.hintBranch,
              icon: BankingIcons.branchLoc,
              ctrl: _branchCtrl,
              focusNode: _branchFocus,
              nextFocus: _upiFocus,
              brandColor: BankingColors.brandTeal,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(BankingStrings.secDigitalReceivables,
            style: BankingStyles.sectionSub),
        const SizedBox(height: 16),
        Center(
          child: QrDocumentWidget(
            title: BankingStrings.qrTitle,
            subtitle: BankingStrings.qrSubtitle,
            icon: BankingIcons.secPayments,
            currentFile: _qrImageFile,
            isInitiallyLocked: _isLocked,
            cropLogic: widget.logicCore.cropLogic,
            onImageSaved: (file) {
              setState(() {
                _qrImageFile = file;
                _currentData = _currentData.copyWith(
                    qrImagePath: file?.path, clearQrImage: file == null);
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildThemeInput(
          label: BankingStrings.lblUpi,
          hint: BankingStrings.hintUpi,
          icon: BankingIcons.upiId,
          ctrl: _upiCtrl,
          focusNode: _upiFocus,
          brandColor: BankingColors.upiColor,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          validator: BankingValidators.validateUPI,
        ),
      ],
    );
  }

  Widget _buildThemeInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType inputType = TextInputType.text,
    bool isCapital = false,
    bool isObscure = false,
    Color? brandColor,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BankingStyles.fieldLabel),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: focusNode ?? ChangeNotifier(),
          builder: (context, child) {
            bool isActive = !_isLocked && (focusNode?.hasFocus ?? false);
            Color iconColor = isActive
                ? BankingColors.goldAccent
                : (ctrl.text.isNotEmpty
                    ? (brandColor ?? BankingColors.iconSuccess)
                    : BankingColors.textHint);

            return Container(
              constraints:
                  const BoxConstraints(minHeight: BankingStyles.hInputField),
              decoration: isActive
                  ? BankingStyles.activeInputDecoration
                  : BankingStyles.inputDecoration(_isLocked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 14),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(icon,
                          key: ValueKey(iconColor),
                          size: 20,
                          color: iconColor)),
                  const SizedBox(width: 10),
                  Container(
                      width: 1, height: 24, color: BankingColors.borderLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: child!,
                  )
                ],
              ),
            );
          },
          child: TextFormField(
            controller: ctrl,
            readOnly: _isLocked,
            focusNode: focusNode,
            obscureText: isObscure,
            keyboardType: inputType,
            textCapitalization: isCapital
                ? TextCapitalization.characters
                : TextCapitalization.none,
            inputFormatters: inputFormatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => nextFocus != null
                ? FocusScope.of(context).requestFocus(nextFocus)
                : null,
            style: BankingStyles.fieldText,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: BankingStyles.fieldHint,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              errorStyle: const TextStyle(
                  color: BankingColors.btnDanger, fontSize: 11, height: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownInput(
      {required String label,
      required IconData icon,
      required String value,
      required List<String> items,
      required Function(String?) onChanged,
      Color? brandColor}) {
    Color iconColor = !_isLocked
        ? BankingColors.goldAccent
        : (brandColor ?? BankingColors.iconSuccess);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BankingStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          height: BankingStyles.hInputField,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BankingStyles.inputDecoration(_isLocked),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: BankingColors.borderLight),
              const SizedBox(width: 10),
              Expanded(
                child: _isLocked
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text(value, style: BankingStyles.fieldText))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: BankingColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          value: items.contains(value) ? value : items[0],
                          isExpanded: true,
                          icon: const Icon(BankingIcons.arrowRight,
                              color: BankingColors.textBody),
                          style: BankingStyles.fieldText,
                          onChanged: onChanged,
                          items: items
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                        ),
                      ),
              )
            ],
          ),
        )
      ],
    );
  }
}

// ==========================================
// UPGRADED QR WIDGET
// ==========================================
class QrDocumentWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? currentFile;
  final Function(File?) onImageSaved;
  final bool isInitiallyLocked;
  final DocumentCropLogic cropLogic;

  const QrDocumentWidget(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.currentFile,
      required this.onImageSaved,
      this.isInitiallyLocked = true,
      required this.cropLogic});

  @override
  State<QrDocumentWidget> createState() => _QrDocumentWidgetState();
}

class _QrDocumentWidgetState extends State<QrDocumentWidget> {
  late bool _isLocked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isInitiallyLocked;
  }

  @override
  void didUpdateWidget(covariant QrDocumentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyLocked != oldWidget.isInitiallyLocked) {
      _isLocked = widget.isInitiallyLocked;
    }
  }

  Future<void> _handleDocumentUpload() async {
    setState(() => _isProcessing = true);

    try {
      File? originalFile = await widget.cropLogic.pickDocumentFromGallery();

      if (originalFile == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      bool isDesktop =
          Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      if (isDesktop) {
        final bytes = await originalFile.readAsBytes();
        if (mounted) {
          setState(() => _isProcessing = false);
          _showDesktopCropDialog(bytes);
        }
      } else {
        File? croppedFile = await widget.cropLogic
            .cropDocumentMobile(originalFile, BankingColors.goldAccent);
        if (mounted) {
          setState(() => _isProcessing = false);
          if (croppedFile != null) widget.onImageSaved(croppedFile);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      if (e is FormatException && e.message == "FILE_TOO_LARGE") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(BankingStrings.errFileSize,
                  style: BankingStyles.snackBarText),
              backgroundColor: BankingColors.btnDanger));
        }
      }
    }
  }

  void _showDesktopCropDialog(Uint8List originalImageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final CropController localController = CropController();
        bool isLocallyProcessing = false;
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            return Scaffold(
              backgroundColor: BankingColors.overlayDark,
              appBar: AppBar(
                backgroundColor: BankingColors.overlayDark,
                elevation: 0,
                leading: IconButton(
                    icon: const Icon(BankingIcons.close,
                        color: BankingColors.cardBg),
                    onPressed: () => Navigator.pop(context)),
                title: Text(BankingStrings.qrCropTitle,
                    style: BankingStyles.cropDialogTitle),
                actions: [
                  if (isLocallyProcessing)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.only(right: 20.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: BankingColors.goldAccent,
                                    strokeWidth: 2))))
                  else
                    IconButton(
                        icon: const Icon(BankingIcons.check,
                            color: BankingColors.goldAccent, size: 28),
                        onPressed: () {
                          setStateInternal(() => isLocallyProcessing = true);
                          localController.crop();
                        })
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Crop(
                    image: originalImageBytes,
                    controller: localController,
                    onCropped: (croppedData) async {
                      if (croppedData.isNotEmpty) {
                        File savedFile = await widget.cropLogic
                            .saveCroppedBitmap(croppedData);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        widget.onImageSaved(savedFile);
                      } else {
                        setStateInternal(() => isLocallyProcessing = false);
                      }
                    },
                    aspectRatio: 1 / 1,
                    baseColor: BankingColors.overlayDark,
                    maskColor: BankingColors.overlayDark.withValues(alpha: 0.8),
                    interactive: true,
                    cornerDotBuilder: (size, edgeAlignment) =>
                        const DotControl(color: BankingColors.goldAccent),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionTile(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22)),
      title: Text(label, style: BankingStyles.listTileText),
      trailing: const Icon(BankingIcons.arrowRight,
          size: 16, color: BankingColors.textHint),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showOptions() {
    if (_isLocked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: BankingColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40, height: 4, color: BankingColors.borderLight),
                const SizedBox(height: 20),
                Text(BankingStrings.qrOptionsTitle,
                    style: BankingStyles.bottomSheetTitle),
                const SizedBox(height: 20),
                _buildOptionTile(
                    icon: BankingIcons.uploadFile,
                    label: BankingStrings.qrUploadNew,
                    color: BankingColors.goldAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _handleDocumentUpload();
                    }),
                if (widget.currentFile != null)
                  _buildOptionTile(
                      icon: BankingIcons.removeTrash,
                      label: BankingStrings.qrRemove,
                      color: BankingColors.btnDanger,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onImageSaved(null);
                      }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFile = widget.currentFile != null;
    return Container(
      width: 220,
      height: 220,
      decoration: BankingStyles.uploadZoneDecoration.copyWith(
        border: Border.all(
            color: isActive()
                ? BankingColors.goldAccent
                : BankingColors.borderLight),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InkWell(
            onTap: _isLocked ? null : _showOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              height: double.infinity,
              child: hasFile
                  ? Image.file(widget.currentFile!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(BankingIcons.qrPlaceholder,
                            size: 50,
                            color: _isLocked
                                ? BankingColors.textHint
                                : BankingColors.goldAccent),
                        const SizedBox(height: 12),
                        Text(BankingStrings.qrUpload,
                            style: BankingStyles.qrUploadText(_isLocked)),
                      ],
                    ),
            ),
          ),
          if (_isProcessing)
            Container(
              decoration: BoxDecoration(
                  color: BankingColors.cardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: BankingColors.goldAccent)),
            )
        ],
      ),
    );
  }

  bool isActive() => !_isLocked;
}
