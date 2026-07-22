part of 'gold_purity_step.dart';

class _HeroBanner extends StatelessWidget {
  final GoldStockController ctrl;

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
          colors: [Color(0xFFFFF2C6), Color(0xFFD4AF37)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF3D2800).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'lib/logo/gold.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF3D2800),
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
                  'Gold Stock Intake',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3D2800),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Set the purity grade before entering item rows, wastage and supplier settlement.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: const Color(0xFF3D2800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2800).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              selected.isEmpty ? 'GRADE OPEN' : selected,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF3D2800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurityCard extends StatelessWidget {
  final GoldPurityProfile profile;
  final Color tone;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PurityCard({
    required this.profile,
    required this.tone,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: tone.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? tone.withValues(alpha: 0.10)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? tone : GoldStockColors.borderLight,
              width: isSelected ? 1.7 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.13),
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
                  _IconBadge(icon: icon, color: tone),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete custom grade',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: GoldStockColors.danger,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    )
                  else if (isSelected)
                    Icon(Icons.check_circle_rounded, size: 18, color: tone),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle(16),
              ),
              const SizedBox(height: 5),
              Text(
                profile.displayValue,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: tone,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                profile.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCustomGradeButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _CreateCustomGradeButton({
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(expanded ? Icons.close_rounded : Icons.add_rounded),
      label: Text(
          expanded ? 'Close Custom Grade Builder' : 'Create Custom Gold Grade'),
      style: OutlinedButton.styleFrom(
        foregroundColor: GoldStockColors.textDark,
        side: const BorderSide(color: GoldStockColors.cardBorder),
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

class _CustomGradePanel extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController karatCtrl;
  final TextEditingController hallmarkCtrl;
  final TextEditingController percentCtrl;
  final TextEditingController descriptionCtrl;
  final String? errorText;
  final VoidCallback onCreate;

  const _CustomGradePanel({
    required this.nameCtrl,
    required this.karatCtrl,
    required this.hallmarkCtrl,
    required this.percentCtrl,
    required this.descriptionCtrl,
    required this.errorText,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: GoldStockColors.brandGold.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Gold Grade', style: _titleStyle(17)),
          const SizedBox(height: 6),
          Text(
            'Create a reusable purity card. After creation, it appears with the system grades and can be selected for stock entry or deleted later.',
            style: _bodyStyle(13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 720;
              final fields = [
                _builderField(
                    'Grade Name', 'Example: 20KT Special Gold', nameCtrl),
                _builderField('Karat', 'Example: 20KT', karatCtrl),
                _builderField('Hallmark Code', 'Example: 833', hallmarkCtrl),
                _builderField('Purity Percent', 'Example: 83.30', percentCtrl),
              ];

              if (!twoColumn) {
                return Column(
                  children: fields
                      .map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: field,
                          ))
                      .toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: field,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _builderField(
            'Description',
            'Example: Custom order jewellery stock',
            descriptionCtrl,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: _bodyStyle(13).copyWith(color: GoldStockColors.danger),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Create Grade Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GoldStockColors.shellBg,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _builderField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _titleStyle(13)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          style: _bodyStyle(14).copyWith(fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _bodyStyle(13).copyWith(color: GoldStockColors.textBody),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            border: _fieldBorder(GoldStockColors.borderLight),
            enabledBorder: _fieldBorder(GoldStockColors.borderLight),
            focusedBorder: _fieldBorder(GoldStockColors.brandGold, width: 1.6),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
