part of 'add_customer_screen.dart';

extension _CustomerPreferencesSections on _AddCustomerScreenState {
  Widget _buildPreferencesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDropdown<RingSize>(
                label: 'Ring Size',
                icon: Icons.radio_button_checked_rounded,
                value: _logic.form.ringSize,
                items: RingSize.values,
                itemLabel: (r) => r.label,
                onChanged: _logic.setRingSize,
                hint: 'Select size',
                nullable: true)),
        const SizedBox(width: 14),
        Expanded(
            child: _buildDropdown<BangleSize>(
                label: 'Bangle Size',
                icon: Icons.circle_outlined,
                value: _logic.form.bangleSize,
                items: BangleSize.values,
                itemLabel: (b) => b.label,
                onChanged: _logic.setBangleSize,
                hint: 'Select size',
                nullable: true)),
      ]),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAMILY DETAILS', style: AddCustomerStyles.fieldLabel),
          Text('For birthday & anniversary wishes',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ]),
        GestureDetector(
          onTap: _logic.addFamilyMember,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDB2777).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFDB2777).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.add_rounded, color: Color(0xFFDB2777), size: 16),
              const SizedBox(width: 5),
              Text('Add Member',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ]),
          ),
        ),
      ]),
      if (_logic.form.familyMembers.isNotEmpty) ...[
        const SizedBox(height: 12),
        ..._logic.form.familyMembers.map((member) => CustomerFamilyMemberRow(
              member: member,
              onUpdate: (u) => _logic.updateFamilyMember(member.id, u),
              onRemove: () => _logic.removeFamilyMember(member.id),
              onPickDate: (cb) => _pickDate(context, onPicked: cb),
            )),
      ],
      if (_logic.form.familyMembers.isEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDB2777).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFDB2777).withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Icon(Icons.people_outline_rounded,
                color: const Color(0xFFDB2777).withValues(alpha: 0.5),
                size: 20),
            const SizedBox(width: 12),
            Text('No family members added yet',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
          ]),
        ),
      ],
    ]);
  }
  // SECTION 7: ADDITIONAL

  Widget _buildAdditionalSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildDropdown<ReferralSource>(
          label: 'Referral Source',
          icon: Icons.share_rounded,
          value: _logic.form.referralSource,
          items: ReferralSource.values,
          itemLabel: (r) => r.label,
          onChanged: _logic.setReferralSource,
          hint: 'How did customer find us?',
          nullable: true),
      const SizedBox(height: 14),
      Row(children: [
        Text('INTERNAL NOTES / REMARKS', style: AddCustomerStyles.fieldLabel),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF475569).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('Staff only - not shown on bill',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ),
      ]),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _logic.activeField == ActiveField.notes
                ? AddCustomerColors.brandGold
                : AddCustomerColors.inputBorder,
            width: _logic.activeField == ActiveField.notes ? 2 : 1,
          ),
          boxShadow: _logic.activeField == ActiveField.notes
              ? [
                  BoxShadow(
                      color:
                          AddCustomerColors.brandGold.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: _notesCtrl,
          focusNode: _notesFocus,
          maxLines: 4,
          onChanged: _logic.onNotesChanged,
          style: AddCustomerStyles.fieldText,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AddCustomerStrings.hintNotes,
            hintStyle: AddCustomerStyles.fieldHint,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    ]);
  }
  // ACTION BUTTONS

  Widget _buildActionButtons() {
    final canSave = _logic.canSave;
    final saving = _logic.isSaving;
    return Row(children: [
      OutlinedButton.icon(
        onPressed: saving ? null : _handleClear,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          _isEditMode
              ? AddCustomerStrings.btnResetChanges
              : AddCustomerStrings.btnClear,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: canSave
              ? AddCustomerColors.saveBtnBg
              : AddCustomerColors.saveBtnDisabled,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSave
              ? [
                  BoxShadow(
                      color:
                          AddCustomerColors.saveBtnBg.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSave ? _handleSave : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black54, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(AddCustomerIcons.save,
                          size: 20,
                          color: canSave ? Colors.black87 : Colors.black54),
                      const SizedBox(width: 10),
                      Text(
                          _isEditMode
                              ? AddCustomerStrings.btnUpdate
                              : AddCustomerStrings.btnSave,
                          style: AddCustomerStyles.saveBtnText.copyWith(
                              color:
                                  canSave ? Colors.black87 : Colors.black54)),
                    ]),
            ),
          ),
        ),
      )),
    ]);
  }
  // REUSABLE HELPERS

  ActiveField _activeFieldFor(FocusNode fn) {
    if (fn == _firstNameFocus) return ActiveField.firstName;
    if (fn == _lastNameFocus) return ActiveField.lastName;
    if (fn == _companyFocus) return ActiveField.companyName;
    if (fn == _contactFocus) return ActiveField.contactPerson;
    if (fn == _mobileFocus) return ActiveField.mobile;
    if (fn == _whatsappFocus) return ActiveField.whatsapp;
    if (fn == _emailFocus) return ActiveField.email;
    if (fn == _altFocus) return ActiveField.alternateContact;
    if (fn == _panFocus) return ActiveField.panNumber;
    if (fn == _idProofNoFocus) return ActiveField.idProofNumber;
    if (fn == _gstFocus) return ActiveField.gstNumber;
    if (fn == _addr1Focus) return ActiveField.addressLine1;
    if (fn == _addr2Focus) return ActiveField.addressLine2;
    if (fn == _pincodeFocus) return ActiveField.pincode;
    if (fn == _notesFocus) return ActiveField.notes;
    return ActiveField.none;
  }
}
