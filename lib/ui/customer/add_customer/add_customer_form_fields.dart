part of 'add_customer_screen.dart';

extension _CustomerFormFields on _AddCustomerScreenState {
  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required void Function(String) onChanged,
    FocusNode? focus,
    FocusNode? next,
    String hint = '',
    bool required = false,
    bool enabled = true,
    String? error,
    Widget? suffix,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    final isFocused =
        focus != null && _logic.activeField == _activeFieldFor(focus);
    final hasError = error != null;
    final hasValue = ctrl.text.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: AddCustomerColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ]),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: maxLines > 1 ? null : 54,
        decoration: BoxDecoration(
          color: enabled
              ? (isFocused
                  ? AddCustomerColors.inputBgFocus
                  : AddCustomerColors.inputBg)
              : const Color(0xFFF3F2EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AddCustomerColors.error
                : isFocused
                    ? AddCustomerColors.inputBorderFocus
                    : hasValue
                        ? Colors.black54
                        : AddCustomerColors.inputBorder,
            width: isFocused || hasValue ? 1.5 : 1,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color:
                          AddCustomerColors.brandGold.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : hasError
                  ? [
                      BoxShadow(
                          color:
                              AddCustomerColors.error.withValues(alpha: 0.08),
                          blurRadius: 6)
                    ]
                  : [],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: maxLines > 1 ? 54 : double.infinity,
            decoration: BoxDecoration(
              color: isFocused
                  ? AddCustomerColors.brandGold.withValues(alpha: 0.12)
                  : hasError
                      ? AddCustomerColors.error.withValues(alpha: 0.08)
                      : hasValue
                          ? Colors.black.withValues(alpha: 0.03)
                          : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: Border(
                  right: BorderSide(
                      color: isFocused
                          ? AddCustomerColors.brandGold.withValues(alpha: 0.3)
                          : AddCustomerColors.inputBorder,
                      width: 1)),
            ),
            child: Center(
                child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon,
                  key: ValueKey('$isFocused$hasError'),
                  size: 20,
                  color: isFocused
                      ? AddCustomerColors.brandGold
                      : hasError
                          ? AddCustomerColors.error
                          : Colors.black87),
            )),
          ),
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(prefix,
                  style: AddCustomerStyles.fieldText.copyWith(
                      color: Colors.black87, fontWeight: FontWeight.w700)),
            ),
          Expanded(
              child: TextFormField(
            controller: ctrl,
            focusNode: focus,
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textCapitalization: capitalization,
            onChanged: onChanged,
            style: AddCustomerStyles.fieldText,
            textInputAction:
                next != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (next != null) {
                FocusScope.of(context).requestFocus(next);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AddCustomerStyles.fieldHint,
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: maxLines > 1 ? 14 : 0),
            ),
          )),
          if (suffix != null) ...[suffix, const SizedBox(width: 12)],
        ]),
      ),
      if (hasError) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(AddCustomerIcons.errorIcon,
              color: AddCustomerColors.error, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(error,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AddCustomerColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ],
    ]);
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final fmt = value != null ? DateFormat('dd MMM yyyy').format(value) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: fmt != null
                ? AddCustomerColors.brandGold.withValues(alpha: 0.05)
                : AddCustomerColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fmt != null
                    ? AddCustomerColors.brandGold.withValues(alpha: 0.4)
                    : AddCustomerColors.inputBorder,
                width: fmt != null ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: fmt != null
                    ? AddCustomerColors.brandGold.withValues(alpha: 0.10)
                    : const Color(0xFFF0EDE8),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11)),
                border: const Border(
                    right: BorderSide(color: AddCustomerColors.inputBorder)),
              ),
              child: Icon(icon,
                  size: 20,
                  color: fmt != null
                      ? AddCustomerColors.brandGold
                      : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(fmt ?? 'Select date',
                    style: fmt != null
                        ? AddCustomerStyles.fieldText
                        : AddCustomerStyles.fieldHint)),
            if (fmt != null)
              IconButton(
                tooltip: 'Clear date',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            else
              const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 20, color: Colors.black87)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required String hint,
    bool nullable = false,
  }) {
    final hasValue = value != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: hasValue
              ? AddCustomerColors.brandGold.withValues(alpha: 0.04)
              : AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? AddCustomerColors.brandGold.withValues(alpha: 0.4)
                  : AddCustomerColors.inputBorder,
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: hasValue
                  ? AddCustomerColors.brandGold.withValues(alpha: 0.10)
                  : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: const Border(
                  right: BorderSide(color: AddCustomerColors.inputBorder)),
            ),
            child: Icon(icon,
                size: 20,
                color: hasValue ? AddCustomerColors.brandGold : Colors.black87),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54, size: 22),
                style: AddCustomerStyles.fieldText,
                hint: Text(hint, style: AddCustomerStyles.fieldHint),
                items: [
                  if (nullable)
                    DropdownMenuItem<T>(
                        value: null,
                        child: Text(hint, style: AddCustomerStyles.fieldHint)),
                  ...items.map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item),
                          style: AddCustomerStyles.fieldText))),
                ],
                onChanged: onChanged,
              ),
            ),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildSimpleDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final hasValue = value != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: hasValue
              ? AddCustomerColors.brandGold.withValues(alpha: 0.04)
              : AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? AddCustomerColors.brandGold.withValues(alpha: 0.4)
                  : AddCustomerColors.inputBorder,
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: hasValue
                  ? AddCustomerColors.brandGold.withValues(alpha: 0.10)
                  : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: const Border(
                  right: BorderSide(color: AddCustomerColors.inputBorder)),
            ),
            child: Icon(icon,
                size: 20,
                color: hasValue ? AddCustomerColors.brandGold : Colors.black87),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54, size: 22),
                style: AddCustomerStyles.fieldText,
                items: items
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: AddCustomerStyles.fieldText)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required String? filePath,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required Color accentColor,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: filePath != null
                ? accentColor.withValues(alpha: 0.05)
                : AddCustomerColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: filePath != null
                    ? accentColor.withValues(alpha: 0.4)
                    : AddCustomerColors.inputBorder,
                width: filePath != null ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: filePath != null
                    ? accentColor.withValues(alpha: 0.10)
                    : const Color(0xFFF0EDE8),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11)),
                border: const Border(
                    right: BorderSide(color: AddCustomerColors.inputBorder)),
              ),
              child: Icon(filePath != null ? Icons.file_present_rounded : icon,
                  size: 20,
                  color: filePath != null ? accentColor : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    filePath != null
                        ? filePath.split(RegExp(r'[/\\]')).last
                        : 'Tap to upload document',
                    style: filePath != null
                        ? AddCustomerStyles.fieldText
                            .copyWith(color: accentColor)
                        : AddCustomerStyles.fieldHint,
                    overflow: TextOverflow.ellipsis)),
            if (filePath != null)
              GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.close_rounded,
                          color: AddCustomerColors.error, size: 20))),
            if (filePath == null)
              const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.upload_rounded,
                      color: Colors.black87, size: 20)),
          ]),
        ),
      ),
    ]);
  }
}
