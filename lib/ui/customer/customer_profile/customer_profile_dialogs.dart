part of 'customer_profile_screen.dart';

extension _ProfileDialogs on _CustomerProfileScreenState {
  Future<void> _openCustomerEditor(CustomerProfileModel profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (editorContext) => AddCustomerScreen(
          customerId: profile.id,
          onBack: () => Navigator.of(editorContext).pop(false),
          onSaved: () => Navigator.of(editorContext).pop(true),
        ),
      ),
    );

    if (updated == true && mounted) {
      await _logic.refresh();
    }
  }

  // ignore: unused_element
  void _showEditDialog(CustomerProfileModel p) {
    // Pre-fill all controllers
    _editNameCtrl.text = p.name;
    _editMobileCtrl.text = p.mobile;
    _editWhatsappCtrl.text = p.whatsapp;
    _editCityCtrl.text = p.city;
    _editTypeValue = p.type;
    // Other fields default empty (not in model currently)
    _editEmailCtrl.text = "";
    _editAddressCtrl.text = "";
    _editStateCtrl.text = "";
    _editPincodeCtrl.text = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: CustomerProfileColors.bodyPanelBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.editBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CustomerProfileIcons.edit,
                    color: CustomerProfileColors.editText,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  CustomerProfileStrings.editTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: CustomerProfileColors.bodyTextMain,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_logic.editError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CustomerProfileColors.deleteBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _logic.editError!,
                          style: const TextStyle(
                            color: CustomerProfileColors.deleteText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _editSectionLabel("Personal Info"),
                    const SizedBox(height: 8),
                    _editField(
                      ctrl: _editNameCtrl,
                      label: "Full Name *",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 10),

                    // Customer Type toggle
                    Row(
                      children: [
                        const Text(
                          "Customer Type:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomerProfileTypeToggle(
                          value: _editTypeValue,
                          onChanged: (v) =>
                              setDialogState(() => _editTypeValue = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _editSectionLabel("Contact Details"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                            ctrl: _editMobileCtrl,
                            label: "Mobile *",
                            icon: CustomerProfileIcons.phone,
                            isNumber: true,
                            maxLength: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editWhatsappCtrl,
                            label: "WhatsApp",
                            icon: CustomerProfileIcons.whatsapp,
                            isNumber: true,
                            maxLength: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _editField(
                      ctrl: _editEmailCtrl,
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    _editSectionLabel("Address"),
                    const SizedBox(height: 8),
                    _editField(
                      ctrl: _editAddressCtrl,
                      label: "Address Line",
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                            ctrl: _editCityCtrl,
                            label: "City / Area",
                            icon: CustomerProfileIcons.city,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editStateCtrl,
                            label: "State",
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editPincodeCtrl,
                            label: "Pincode",
                            icon: Icons.pin_drop_outlined,
                            isNumber: true,
                            maxLength: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () {
                  _logic.cancelEditMode();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  CustomerProfileStrings.editCancel,
                  style: TextStyle(
                    color: CustomerProfileColors.bodyTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _logic.savingEdit
                    ? null
                    : () async {
                        final dialogNavigator = Navigator.of(ctx);
                        final ok = await _logic.saveEdit(
                          name: _editNameCtrl.text,
                          mobile: _editMobileCtrl.text,
                          city: _editCityCtrl.text,
                          type: _editTypeValue,
                          whatsapp: _editWhatsappCtrl.text,
                          email: _editEmailCtrl.text,
                          address: _editAddressCtrl.text,
                          state: _editStateCtrl.text,
                          pincode: _editPincodeCtrl.text,
                        );
                        if (ok && mounted) {
                          dialogNavigator.pop();
                          AppFeedback.success(
                            context,
                            message: CustomerProfileStrings.editSuccess,
                          );
                        } else {
                          setDialogState(() {});
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerProfileColors.brandGold,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _logic.savingEdit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        CustomerProfileStrings.editSave,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _editSectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CustomerProfileColors.bodyTextMuted,
          letterSpacing: 1.2,
        ),
      );

  Widget _editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerProfileColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ]
            : null,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: CustomerProfileColors.bodyTextMain,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: CustomerProfileColors.bodyTextMuted,
            fontSize: 13,
          ),
          prefixIcon:
              Icon(icon, size: 18, color: CustomerProfileColors.bodyTextMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // Due limit edit
  Widget _buildDueLimitEdit(CustomerProfileModel p) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: CustomerProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CustomerProfileColors.brandGold, width: 1.5),
            ),
            child: TextField(
              controller: _dueLimitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CustomerProfileColors.bodyTextMain,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
                hintText: CustomerProfileStrings.hintDueLimit,
                hintStyle:
                    TextStyle(color: CustomerProfileColors.bodyTextMuted),
                prefixIcon: Icon(CustomerProfileIcons.amount,
                    color: CustomerProfileColors.brandGold, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final val = double.tryParse(_dueLimitCtrl.text);
            if (val == null || val < 0) return;
            final ok = await _logic.saveDueLimit(val);
            if (ok && mounted) {
              AppFeedback.show(
                context,
                type: AppFeedbackType.success,
                message: CustomerProfileStrings.savedLimit,
              );
            }
          },
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: CustomerProfileColors.brandGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _logic.savingDueLimit
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    ),
                  )
                : const Icon(CustomerProfileIcons.saveLimit,
                    color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  // DELETE DIALOG
  void _showDeleteDialog(CustomerProfileModel p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: CustomerProfileColors.bodyPanelBg,
        icon: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: CustomerProfileColors.deleteBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(CustomerProfileIcons.warningIcon,
              color: CustomerProfileColors.deleteText, size: 28),
        ),
        title: const Text(
          CustomerProfileStrings.deleteTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CustomerProfileColors.bodyTextMain,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          CustomerProfileStrings.deleteMsg,
          style: TextStyle(
            color: CustomerProfileColors.bodyTextMuted,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: CustomerProfileColors.bodyTextMuted,
              side: const BorderSide(color: CustomerProfileColors.bodyBorder),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(CustomerProfileStrings.deleteCancel,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              final dialogNavigator = Navigator.of(dialogContext);
              dialogNavigator.pop();
              await Future<void>.delayed(Duration.zero);
              if (!mounted) return;
              final ok = await _logic.deleteCustomer();
              if (!ok && mounted) {
                AppFeedback.show(
                  context,
                  type: AppFeedbackType.error,
                  message:
                      _logic.deleteError ?? CustomerProfileStrings.deleteError,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerProfileColors.deleteText,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(CustomerProfileStrings.deleteConfirm,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // SHARED HELPERS
}
