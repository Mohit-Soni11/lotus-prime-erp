part of 'item_recovery_dialog.dart';

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({
    required this.title,
    required this.icon,
    required this.children,
    this.background = Colors.white,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: GirviColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 19, color: GirviColors.brandGold),
              const SizedBox(width: 8),
              Text(title,
                  style: _ItemRecoveryDialogState._boldText(
                      size: 15, color: GirviColors.textDark)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _RecoveryLine extends StatelessWidget {
  const _RecoveryLine(this.label, this.value,
      {this.strong = false, this.valueColor, this.labelColor});

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: _ItemRecoveryDialogState._boldText(
                    size: 12.5, color: labelColor ?? GirviColors.textDark)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: _ItemRecoveryDialogState._boldText(
                  size: strong ? 14 : 12.5,
                  color: valueColor ?? GirviColors.textDark)),
        ]),
      );
}

class _PledgedItemCard extends StatelessWidget {
  const _PledgedItemCard({required this.item, required this.index});

  final RecoveryPledgedItemDetail item;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          border: Border.all(color: GirviColors.cardBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pledged item $index',
                style: _ItemRecoveryDialogState._boldText(
                    size: 13, color: GirviColors.textDark)),
            const SizedBox(height: 5),
            _RecoveryLine('Item name', item.itemName),
            _RecoveryLine('Metal type', item.metalType),
            _RecoveryLine('Purity', item.purity),
            _RecoveryLine('Pieces', '${item.pieces}'),
            _RecoveryLine(
                'Net weight', '${item.netWeight.toStringAsFixed(3)} g'),
          ],
        ),
      );
}

class _RecoveryError extends StatelessWidget {
  const _RecoveryError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: GirviColors.dangerBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: _ItemRecoveryDialogState._boldText(
                size: 12, color: GirviColors.danger)),
      );
}

Widget _recoveryDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> entries,
  required ValueChanged<T> onChanged,
}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: _ItemRecoveryDialogState._boldText(
                size: 13, color: GirviColors.textDark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ValueKey(label),
          initialValue: value,
          isExpanded: true,
          items: entries,
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
          dropdownColor: Colors.white,
          iconEnabledColor: GirviColors.textDark,
          style: _ItemRecoveryDialogState._boldText(
              size: 14, color: GirviColors.textDark),
          decoration: _fieldDecoration('Select $label'),
        ),
      ],
    );

InputDecoration _fieldDecoration(String hint, {bool isAmount = false}) =>
    InputDecoration(
      hintText: isAmount ? null : hint,
      prefixText: isAmount ? '$hint ' : null,
      hintStyle: _ItemRecoveryDialogState._boldText(
          size: 12, color: GirviColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GirviColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GirviColors.brandGold, width: 2),
      ),
    );
