part of 'add_customer_screen.dart';

extension _CustomerFormInitialization on _AddCustomerScreenState {
  void _populateControllers(AddCustomerFormModel form) {
    _firstNameCtrl.text = form.firstName;
    _lastNameCtrl.text = form.lastName;
    _companyCtrl.text = form.companyName;
    _contactCtrl.text = form.contactPersonName;
    _mobileCtrl.text = form.mobile;
    _whatsappCtrl.text = form.whatsapp;
    _emailCtrl.text = form.email;
    _altContactCtrl.text = form.alternateContact;
    _panCtrl.text = form.panNumber;
    _idProofNoCtrl.text = form.idProofNumber;
    _gstCtrl.text = form.gstNumber;
    _addr1Ctrl.text = form.addressLine1;
    _addr2Ctrl.text = form.addressLine2;
    _stateProvinceCtrl.text = form.state;
    _cityCtrl.text = form.city;
    _pincodeCtrl.text = form.pincode;
    _openBalCtrl.text = _numberText(form.openingBalance);
    _memberIdCtrl.text = form.membershipId;
    _notesCtrl.text = form.notes;
    _selectedCountry = form.country.trim().isEmpty ? 'India' : form.country;
    _selectedState = form.state.trim().isEmpty ? null : form.state;
  }

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  void _applyInitialValues() {
    final initialName = widget.initialName?.trim();
    if (initialName != null && initialName.isNotEmpty) {
      final parts = initialName.split(RegExp(r'\s+'));
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
      _firstNameCtrl.text = firstName;
      _logic.onFirstNameChanged(firstName);
      if (lastName.isNotEmpty) {
        _lastNameCtrl.text = lastName;
        _logic.onLastNameChanged(lastName);
      }
    }

    final digitsOnly = widget.initialMobile?.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly != null && digitsOnly.isNotEmpty) {
      final mobile = digitsOnly.length > 10
          ? digitsOnly.substring(digitsOnly.length - 10)
          : digitsOnly;
      _mobileCtrl.text = mobile;
      _whatsappCtrl.text = mobile;
      _logic.onMobileChanged(mobile);
      _logic.setSameAsWhatsApp(true);
    }

    final initialAddress = widget.initialAddress?.trim();
    if (initialAddress != null && initialAddress.isNotEmpty) {
      _addr1Ctrl.text = initialAddress;
      _logic.onAddressLine1Changed(initialAddress);
    }
  }

  void _attachFocusListeners() {
    void bind(FocusNode fn, ActiveField af) {
      fn.addListener(
          () => _logic.setActiveField(fn.hasFocus ? af : ActiveField.none));
    }

    bind(_firstNameFocus, ActiveField.firstName);
    bind(_lastNameFocus, ActiveField.lastName);
    bind(_companyFocus, ActiveField.companyName);
    bind(_contactFocus, ActiveField.contactPerson);
    bind(_mobileFocus, ActiveField.mobile);
    bind(_whatsappFocus, ActiveField.whatsapp);
    bind(_emailFocus, ActiveField.email);
    bind(_altFocus, ActiveField.alternateContact);
    bind(_panFocus, ActiveField.panNumber);
    bind(_idProofNoFocus, ActiveField.idProofNumber);
    bind(_gstFocus, ActiveField.gstNumber);
    bind(_addr1Focus, ActiveField.addressLine1);
    bind(_addr2Focus, ActiveField.addressLine2);
    bind(_pincodeFocus, ActiveField.pincode);
    bind(_notesFocus, ActiveField.notes);
  }
}
