part of 'add_supplier_screen.dart';

Widget _addSupplierSection({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color accent,
  required int stepNumber,
  required Widget child,
}) {
  final lighterAccent = Color.lerp(accent, Colors.white, 0.24)!;
  return Container(
    decoration: AddSupplierStyles.sectionCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, lighterAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AddSupplierStyles.cardRadius),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  stepNumber.toString().padLeft(2, '0'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ],
    ),
  );
}

Widget _addSupplierField({
  required String label,
  required String hint,
  required TextEditingController ctrl,
  required FocusNode focus,
  required IconData icon,
  required ValueChanged<String> onChanged,
  String? errorText,
  TextInputType keyboard = TextInputType.text,
  TextCapitalization textCap = TextCapitalization.none,
  List<TextInputFormatter>? formatters,
  int? maxLength,
  int maxLines = 1,
  bool enabled = true,
}) {
  return Padding(
    padding: AddSupplierStyles.fieldGap,
    child: TextFormField(
      controller: ctrl,
      focusNode: focus,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboard,
      textCapitalization: textCap,
      inputFormatters: formatters,
      maxLength: maxLength,
      maxLines: maxLines,
      style: AddSupplierStyles.fieldInput,
      decoration: AddSupplierStyles.fieldDecoration(
        label: label,
        hint: hint,
        prefix: Icon(icon, color: AddSupplierColors.brandGold, size: 20),
      ).copyWith(errorText: errorText),
    ),
  );
}

Widget _addSupplierDropdown<T>({
  required String label,
  required IconData icon,
  required T? value,
  required List<T> items,
  required String Function(T item) itemLabel,
  required ValueChanged<T> onChanged,
}) {
  return Padding(
    padding: AddSupplierStyles.fieldGap,
    child: Container(
      height: AddSupplierStyles.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AddSupplierColors.inputBg,
        borderRadius: BorderRadius.circular(AddSupplierStyles.inputRadius),
        border: Border.all(color: AddSupplierColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AddSupplierColors.brandGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(label, style: AddSupplierStyles.fieldHint),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: AddSupplierStyles.fieldInput,
                items: items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (selected) {
                  if (selected != null) onChanged(selected);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _addSupplierCheckboxLine({
  required bool value,
  required String label,
  required ValueChanged<bool> onChanged,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () => onChanged(!value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: AddSupplierColors.brandGold,
          checkColor: Colors.black,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AddSupplierColors.bodyTextMuted,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

Widget _addSupplierErrorBanner(String message) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AddSupplierColors.errorBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AddSupplierColors.error.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          AddSupplierIcons.errorIcon,
          color: AddSupplierColors.error,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AddSupplierColors.error,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
