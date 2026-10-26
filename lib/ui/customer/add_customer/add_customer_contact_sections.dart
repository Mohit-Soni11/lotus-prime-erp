part of 'add_customer_screen.dart';

extension _CustomerContactSections on _AddCustomerScreenState {
  Widget _buildPersonalSection() {
    final isCorp = _logic.form.isCorporate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: CustomerEntityChip(
          icon: Icons.person_rounded,
          label: 'Individual',
          subtitle: 'Personal customer',
          isSelected: !isCorp,
          activeColor: const Color(0xFF4F46E5),
          onTap: () => _logic.setEntityType(CustomerEntityType.individual),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: CustomerEntityChip(
          icon: Icons.business_rounded,
          label: 'Corporate',
          subtitle: 'Company / B2B',
          isSelected: isCorp,
          activeColor: const Color(0xFFD97706),
          onTap: () => _logic.setEntityType(CustomerEntityType.corporate),
        )),
      ]),
      const SizedBox(height: 20),
      if (isCorp) ...[
        _field(
            label: 'Company Name',
            required: true,
            icon: Icons.business_rounded,
            ctrl: _companyCtrl,
            focus: _companyFocus,
            next: _contactFocus,
            hint: 'Enter company / firm name',
            onChanged: _logic.onCompanyNameChanged,
            capitalization: TextCapitalization.words),
        const SizedBox(height: 14),
        _field(
            label: 'Contact Person Name',
            icon: AddCustomerIcons.name,
            ctrl: _contactCtrl,
            focus: _contactFocus,
            next: _mobileFocus,
            hint: 'Owner / Manager name',
            onChanged: _logic.onContactPersonChanged,
            capitalization: TextCapitalization.words),
      ] else ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _field(
                  label: 'First Name',
                  required: true,
                  icon: AddCustomerIcons.name,
                  ctrl: _firstNameCtrl,
                  focus: _firstNameFocus,
                  next: _lastNameFocus,
                  hint: 'First name',
                  error: _logic.form.firstNameError,
                  onChanged: _logic.onFirstNameChanged,
                  capitalization: TextCapitalization.words)),
          const SizedBox(width: 14),
          Expanded(
              child: _field(
                  label: 'Last Name',
                  icon: Icons.person_rounded,
                  ctrl: _lastNameCtrl,
                  focus: _lastNameFocus,
                  next: _mobileFocus,
                  hint: 'Last name',
                  onChanged: _logic.onLastNameChanged,
                  capitalization: TextCapitalization.words)),
        ]),
      ],
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDateField(
                label: 'Date of Birth',
                icon: Icons.cake_rounded,
                value: _logic.form.dateOfBirth,
                onTap: () => _pickDate(context,
                    onPicked: _logic.setDateOfBirth,
                    lastDate: DateTime.now()))),
        const SizedBox(width: 14),
        Expanded(
            child: _buildDropdown<Gender>(
                label: 'Gender',
                icon: Icons.people_alt_rounded,
                value: _logic.form.gender,
                items: Gender.values,
                itemLabel: (g) => g.label,
                onChanged: _logic.setGender,
                hint: 'Select gender',
                nullable: true)),
      ]),
      const SizedBox(height: 14),
      _buildDateField(
          label: 'Anniversary Date (Optional)',
          icon: Icons.favorite_rounded,
          value: _logic.form.anniversaryDate,
          onTap: () => _pickDate(context,
              onPicked: _logic.setAnniversaryDate, lastDate: DateTime.now())),
    ]);
  }
  // SECTION 2: CONTACT

  Widget _buildContactSection() {
    final sameWa = _logic.form.sameAsWhatsApp;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: AddCustomerStrings.lblMobile,
        icon: AddCustomerIcons.mobile,
        ctrl: _mobileCtrl,
        focus: _mobileFocus,
        hint: AddCustomerStrings.hintMobile,
        error: _logic.form.mobileError,
        onChanged: (v) {
          _logic.onMobileChanged(v);
          if (sameWa) _whatsappCtrl.text = v;
        },
        keyboardType: TextInputType.number,
        maxLength: 10,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        suffix:
            (_logic.form.mobile.length == 10 && _logic.form.mobileError == null)
                ? const Icon(AddCustomerIcons.successIcon,
                    color: AddCustomerColors.success, size: 20)
                : null,
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () {
          _logic.setSameAsWhatsApp(!sameWa);
          if (!sameWa) {
            _whatsappCtrl.text = _mobileCtrl.text;
          } else {
            _whatsappCtrl.clear();
          }
        },
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: sameWa ? const Color(0xFF059669) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: sameWa
                      ? const Color(0xFF059669)
                      : AddCustomerColors.inputBorder,
                  width: 1.5),
            ),
            child: sameWa
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text('Same as WhatsApp',
              style:
                  AddCustomerStyles.fieldLabel.copyWith(color: Colors.black87)),
          const SizedBox(width: 6),
          const FaIcon(FontAwesomeIcons.whatsapp,
              size: 18, color: Color(0xFF25D366)),
        ]),
      ),
      const SizedBox(height: 14),
      _field(
          label: AddCustomerStrings.lblWhatsapp,
          icon: AddCustomerIcons.whatsapp,
          ctrl: _whatsappCtrl,
          focus: _whatsappFocus,
          next: _emailFocus,
          hint: AddCustomerStrings.hintWhatsapp,
          onChanged: _logic.onWhatsappChanged,
          enabled: !sameWa,
          keyboardType: TextInputType.number,
          maxLength: 10,
          formatters: [FilteringTextInputFormatter.digitsOnly]),
      const SizedBox(height: 14),
      _field(
          label: 'Email Address',
          icon: Icons.email_outlined,
          ctrl: _emailCtrl,
          focus: _emailFocus,
          next: _altFocus,
          hint: 'customer@email.com',
          error: _logic.form.emailError,
          onChanged: _logic.onEmailChanged,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 14),
      _field(
          label: 'Alternate Contact No.',
          icon: Icons.phone_outlined,
          ctrl: _altContactCtrl,
          focus: _altFocus,
          hint: 'Secondary number (optional)',
          onChanged: _logic.onAlternateContactChanged,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          formatters: [FilteringTextInputFormatter.digitsOnly]),
    ]);
  }
  // SECTION 3: KYC
}
