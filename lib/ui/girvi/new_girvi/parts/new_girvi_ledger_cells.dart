part of '../new_girvi_screen.dart';

class _TotalItemValueHighlight extends StatelessWidget {
  const _TotalItemValueHighlight({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: hasValue
            ? GirviColors.success.withValues(alpha: 0.08)
            : GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue
              ? GirviColors.success.withValues(alpha: 0.32)
              : GirviColors.cardBorder,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasValue
                  ? GirviColors.success.withValues(alpha: 0.14)
                  : GirviColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue
                    ? GirviColors.success.withValues(alpha: 0.24)
                    : GirviColors.cardBorder,
              ),
            ),
            child: Icon(
              GirviIcons.valuation,
              color: hasValue ? GirviColors.success : GirviColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Pledged Valuation',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatSmartMoney(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color:
                        hasValue ? GirviColors.success : GirviColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (hasValue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: GirviColors.success.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'READY',
                style: GoogleFonts.inter(
                  color: GirviColors.success,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LedgerSectionCard extends StatelessWidget {
  const _LedgerSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.055),
              border: const Border(
                bottom: BorderSide(color: GirviColors.divider),
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GirviStyles.sectionTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GirviStyles.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LedgerColumn {
  const _LedgerColumn(this.label, this.width);
  final String label;
  final double width;
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({required this.columns, required this.scale});

  final List<_LedgerColumn> columns;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4EE),
        border: Border(
          bottom: BorderSide(color: GirviColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            SizedBox(
              width: columns[i].width * scale,
              child: Text(
                columns[i].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textBody,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerAddButton extends StatelessWidget {
  const _LedgerAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GirviColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: GirviColors.success.withValues(alpha: 0.34),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: GirviColors.success, size: 17),
            const SizedBox(width: 6),
            Text(
              'ADD NEW ITEM',
              style: GoogleFonts.inter(
                color: GirviColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: GirviColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'F2',
                style: GoogleFonts.inter(
                  color: GirviColors.success,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerSerialCell extends StatelessWidget {
  const _LedgerSerialCell({required this.serialNo, required this.width});

  final int serialNo;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GirviColors.brandGoldLight,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: GirviColors.brandGold.withValues(alpha: 0.3)),
        ),
        child: Text(
          serialNo.toString().padLeft(2, '0'),
          style: GoogleFonts.manrope(
            color: GirviColors.brandDeep,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LedgerTextCell extends StatelessWidget {
  const _LedgerTextCell({
    required this.width,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textAlign = TextAlign.left,
    this.prefixText,
    this.suffixText,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final String? prefixText;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textAlign: textAlign,
        textAlignVertical: TextAlignVertical.center,
        style: GirviStyles.fieldInput.copyWith(
          color: GirviColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          suffixText: suffixText,
          hintStyle: GirviStyles.fieldHint.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: GirviColors.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: GirviColors.cardBorder, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: GirviColors.cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: GirviColors.brandGold, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _LedgerDropdownCell<T> extends StatelessWidget {
  const _LedgerDropdownCell({
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
    this.accent,
  });

  final double width;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? GirviColors.textDark;
    return SizedBox(
      width: width,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: accent?.withValues(alpha: 0.10) ?? GirviColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent?.withValues(alpha: 0.36) ?? GirviColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            icon: Icon(
              GirviIcons.expandDown,
              color: color,
              size: 16,
            ),
            style: GirviStyles.fieldInput.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerPurityCell extends StatelessWidget {
  const _LedgerPurityCell({
    required this.width,
    required this.item,
  });

  final double width;
  final _PledgedItemDraft item;

  @override
  Widget build(BuildContext context) {
    final options = _purityOptionsForMetal(item.metalType);
    return SizedBox(
      width: width,
      height: 38,
      child: Container(
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.cardBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 22,
                  child: TextFormField(
                    controller: item.customPurityCtrl,
                    focusNode: item.customPurityFocus,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: GirviStyles.fieldInput.copyWith(
                      color: GirviColors.brandDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Custom',
                      hintStyle: GirviStyles.fieldHint.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    validator: (value) {
                      if (item.purity == MetalPurity.other &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Required';
                      }
                      return null;
                    },
                    onChanged: item.setPurityText,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              height: 38,
              child: PopupMenuButton<MetalPurity>(
                tooltip: 'Select purity',
                icon: const Icon(
                  GirviIcons.expandDown,
                  color: GirviColors.textMuted,
                  size: 18,
                ),
                color: GirviColors.cardBg,
                position: PopupMenuPosition.under,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: GirviColors.cardBorder),
                ),
                onSelected: (purity) {
                  item.setPurity(purity);
                  if (purity == MetalPurity.other) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      item.customPurityFocus.requestFocus();
                    });
                  }
                },
                itemBuilder: (context) => options.map(
                  (purity) {
                    final label = purity == MetalPurity.other
                        ? 'Custom'
                        : purity.shortLabel;
                    return PopupMenuItem<MetalPurity>(
                      value: purity,
                      height: 36,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: purity == MetalPurity.other
                              ? GirviColors.textBody
                              : GirviColors.brandDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerReadOnlyCell extends StatelessWidget {
  const _LedgerReadOnlyCell({
    required this.width,
    required this.value,
    required this.color,
  });

  final double width;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 38,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LedgerItemNameCell extends StatelessWidget {
  const _LedgerItemNameCell({
    required this.width,
    required this.title,
    required this.subtitle,
  });

  final double width;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
