part of 'silver_purity_step.dart';

class _HeroBanner extends StatelessWidget {
  final SilverStockController ctrl;

  const _HeroBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final selected = ctrl.purityDisplay.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7EEF2), Color(0xFF8FA5B2)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F3A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'lib/logo/silver and platinum .jpeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.toll_rounded,
                color: Color(0xFF1A2F3A),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silver Stock Intake',
                  style: GoogleFonts.manrope(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A2F3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a fixed grade batch or capture one supplier invoice with mixed silver companies and purities.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: const Color(0xFF1A2F3A).withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F3A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              selected.isEmpty
                  ? 'INTAKE OPEN'
                  : _professionalGradeName(selected),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A2F3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _professionalGradeName(String grade) {
    final normalized = grade.trim().toUpperCase();
    if (normalized.contains('SILVER') &&
        !RegExp(r'^(999|925|800|700|600)\b').hasMatch(normalized)) {
      return normalized;
    }
    if (normalized.contains('99.9') || normalized.contains('999')) {
      return '999 FINE';
    }
    if (normalized.contains('92.5') || normalized.contains('925')) {
      return '925 STERLING';
    }
    if (normalized.contains('80') || normalized.contains('800')) {
      return '800 PREMIUM';
    }
    if (normalized.contains('70') || normalized.contains('700')) {
      return '700 UTILITY';
    }
    if (normalized.contains('60')) {
      return '600 LIGHTWEIGHT';
    }
    return grade.toUpperCase();
  }
}

class _PurityCard extends StatelessWidget {
  final _SilverPurityOption preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PurityCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: preset.accent.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? preset.accent.withValues(alpha: 0.10)
                : SilverStockColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? preset.accent : SilverStockColors.borderLight,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: preset.accent.withValues(alpha: 0.13),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBadge(icon: preset.icon, color: preset.accent),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: preset.accent,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                preset.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.value,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: preset.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                  color: SilverStockColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateSilverGradeButton extends StatelessWidget {
  final bool expanded;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateSilverGradeButton({
    required this.expanded,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(expanded ? Icons.close_rounded : icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: SilverStockColors.textDark,
        side: BorderSide(
          color: expanded
              ? SilverStockColors.brandSilver
              : SilverStockColors.cardBorder,
          width: expanded ? 1.4 : 1,
        ),
        backgroundColor: expanded
            ? SilverStockColors.brandSilver.withValues(alpha: 0.08)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MixedSilverInvoiceButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _MixedSilverInvoiceButton({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone =
        selected ? SilverStockColors.brandSilver : SilverStockColors.textDark;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        selected ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
      ),
      label: const Text('Mixed Silver Supplier Invoice'),
      style: OutlinedButton.styleFrom(
        foregroundColor: tone,
        side: BorderSide(
          color: selected
              ? SilverStockColors.brandSilver
              : SilverStockColors.cardBorder,
          width: selected ? 1.4 : 1,
        ),
        backgroundColor: selected
            ? SilverStockColors.brandSilver.withValues(alpha: 0.10)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CustomSilverPurityPanel extends StatelessWidget {
  final TextEditingController purityCtrl;
  final String? errorText;
  final VoidCallback onCreate;

  const _CustomSilverPurityPanel({
    required this.purityCtrl,
    required this.errorText,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return _BuilderPanel(
      icon: Icons.percent_rounded,
      title: 'Create Custom Silver Purity',
      subtitle:
          'Use this when the supplier bill or article grade does not match a preset purity.',
      errorText: errorText,
      children: [
        _SilverPanelField(
          controller: purityCtrl,
          label: 'Purity Percentage',
          hint: 'Example: 76.50',
          suffix: '%',
          icon: Icons.percent_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Purity Grade'),
            style: _primaryButtonStyle(),
          ),
        ),
      ],
    );
  }
}

class _BuilderPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? errorText;
  final List<Widget> children;

  const _BuilderPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.errorText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.brandSilverBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon, color: SilverStockColors.brandSilver),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: SilverStockColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: SilverStockColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
          if (errorText != null && errorText!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SilverStockColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SilverPanelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SilverPanelField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: SilverStockStyles.inputText.copyWith(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: SilverStockColors.brandSilver, size: 18),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: SilverStockColors.textDark,
        ),
        hintStyle: SilverStockStyles.fieldHint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _panelInputBorder(SilverStockColors.borderLight),
        enabledBorder: _panelInputBorder(SilverStockColors.borderLight),
        focusedBorder: _panelInputBorder(
          SilverStockColors.brandSilver,
          width: 1.5,
        ),
      ),
    );
  }
}

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: SilverStockColors.shellBg,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    textStyle: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w900,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

OutlineInputBorder _panelInputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}
