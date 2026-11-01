part of 'cash_book_entry_dialog.dart';

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: CashBookStyles.labelSecondary);
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final bool autofocus;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefix,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      style: CashBookStyles.inputText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CashBookStyles.labelMuted,
        prefix: prefix,
        filled: true,
        fillColor: CashBookColors.searchBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CashBookColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CashBookColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: CashBookColors.brandGold, width: 1.5),
        ),
      ),
    );
  }
}
