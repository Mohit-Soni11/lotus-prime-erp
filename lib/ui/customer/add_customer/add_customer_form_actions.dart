part of 'add_customer_screen.dart';

extension _CustomerFormActions on _AddCustomerScreenState {
  // ACTIONS

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomerImageSourceSheet(),
    );
    if (src == null) return;
    final file =
        await _imgPick.pickImage(source: src, imageQuality: 75, maxWidth: 600);
    if (file != null) _logic.setProfileImagePath(file.path);
  }

  Future<void> _pickIdDoc() async {
    final file =
        await _imgPick.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) _logic.setIdProofDocPath(file.path);
  }

  Future<void> _pickDate(BuildContext ctx,
      {required void Function(DateTime) onPicked,
      DateTime? selectedDate,
      DateTime? firstDate,
      DateTime? lastDate}) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AddCustomerColors.brandGold,
            onPrimary: Colors.black,
            surface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final ok = await _logic.saveCustomer();
    if (!mounted) return;
    if (ok) {
      _showFeedback(
        _isEditMode
            ? AddCustomerStrings.updateSuccessMsg
            : AddCustomerStrings.successMsg,
        isSuccess: true,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final onSaved = widget.onSaved;
      if (onSaved != null) {
        onSaved();
      } else {
        widget.onBack?.call();
      }
    } else if (_logic.saveState == SaveState.duplicate) {
      _showFeedback(AddCustomerStrings.duplicateMsg, isSuccess: false);
    } else if (_logic.saveState == SaveState.validationError) {
      _showFeedback('Please correct the highlighted fields.', isSuccess: false);
    } else {
      _showFeedback(AddCustomerStrings.errorMsg, isSuccess: false);
    }
  }

  void _handleClear() {
    if (_isEditMode) {
      _logic.resetForm();
      _populateControllers(_logic.form);
      _refreshFormUi(() {});
      FocusScope.of(context).unfocus();
      return;
    }

    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _companyCtrl,
      _contactCtrl,
      _mobileCtrl,
      _emailCtrl,
      _altContactCtrl,
      _panCtrl,
      _idProofNoCtrl,
      _gstCtrl,
      _addr1Ctrl,
      _addr2Ctrl,
      _stateProvinceCtrl,
      _cityCtrl,
      _pincodeCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
    _whatsappCtrl.clear();
    _refreshFormUi(() {
      _selectedCountry = 'India';
      _selectedState = null;
    });
    _logic.resetForm();
    FocusScope.of(context).unfocus();
  }

  void _showFeedback(String msg, {required bool isSuccess}) {
    AppFeedback.show(
      context,
      type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  void _changeCountry(String? country) {
    _refreshFormUi(() {
      _selectedCountry = country;
      _selectedState = null;
      _stateProvinceCtrl.clear();
    });
    if (country != null) _logic.setCountry(country);
  }

  void _changeIndianState(IndiaState state) {
    _refreshFormUi(() => _selectedState = state.label);
    _logic.setState_(state.label);
  }
}
