import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverPurityStep extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverPurityStep({super.key, required this.ctrl});

  @override
  State<SilverPurityStep> createState() => _SilverPurityStepState();
}

class _SilverPurityStepState extends State<SilverPurityStep>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _customCtrl;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const List<_SilverPurityOption> _presets = [
    _SilverPurityOption(
      label: 'Fine Silver',
      value: '99.99%',
      detail: 'Highest purity stock',
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFF526677),
    ),
    _SilverPurityOption(
      label: 'Sterling',
      value: '92.50%',
      detail: 'Standard sterling articles',
      icon: Icons.verified_rounded,
      accent: Color(0xFF0F8A72),
    ),
    _SilverPurityOption(
      label: 'Idols',
      value: '80.00%',
      detail: 'High-purity crafted pieces',
      icon: Icons.temple_hindu_rounded,
      accent: Color(0xFF8B5CF6),
    ),
    _SilverPurityOption(
      label: 'Utensils',
      value: '70.00%',
      detail: 'Tableware and utility stock',
      icon: Icons.soup_kitchen_rounded,
      accent: Color(0xFF2563EB),
    ),
    _SilverPurityOption(
      label: 'Jewellery',
      value: '60.00%',
      detail: 'Low-purity daily wear',
      icon: Icons.diamond_rounded,
      accent: Color(0xFFB7791F),
    ),
    _SilverPurityOption(
      label: 'Custom',
      value: 'Custom',
      detail: 'Enter any purity percentage',
      icon: Icons.edit_rounded,
      accent: Color(0xFF64748B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController(
      text: widget.ctrl.isCustomPurity ? widget.ctrl.purityDisplay : '',
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant SilverPurityStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ctrl.isCustomPurity &&
        _customCtrl.text != widget.ctrl.purityDisplay) {
      _customCtrl.text = widget.ctrl.purityDisplay;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final mainPanel = _buildMainPanel();
              final sidePanel = _buildSidePanel();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: mainPanel),
                    const SizedBox(width: 18),
                    SizedBox(width: 330, child: sidePanel),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mainPanel,
                  const SizedBox(height: 18),
                  sidePanel,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainPanel() {
    final ctrl = widget.ctrl;

    return Container(
      decoration:
          SilverStockStyles.cardWithAccent(SilverStockColors.brandSilver),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBanner(ctrl: ctrl),
          const SizedBox(height: 24),
          Text(
            'Select Stock Grade',
            style: SilverStockStyles.pageTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the base purity for this silver batch. Item rows can still add wastage, and the final purity is used for billing and stock classification.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: SilverStockColors.textBody,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 960
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * 12)) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presets.map((preset) {
                  final isCustom = preset.value == 'Custom';
                  final isSelected = isCustom
                      ? ctrl.isCustomPurity
                      : ctrl.purityDisplay == preset.value;

                  return SizedBox(
                    width: itemWidth,
                    child: _PurityCard(
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () {
                        ctrl.setPurity(preset.value);
                        if (isCustom) {
                          _customCtrl.clear();
                        }
                        setState(() {});
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (ctrl.isCustomPurity) ...[
            const SizedBox(height: 20),
            Text('Custom Purity', style: SilverStockStyles.inputLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _customCtrl,
              onChanged: ctrl.setCustomPurity,
              style: SilverStockStyles.inputText,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter purity percentage, e.g. 76.50%',
                hintStyle: SilverStockStyles.fieldHint,
                prefixIcon: const Icon(
                  Icons.percent_rounded,
                  color: SilverStockColors.brandSilver,
                  size: 18,
                ),
                suffixText: '%',
                filled: true,
                fillColor: SilverStockColors.inputBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: _inputBorder(SilverStockColors.borderLight),
                enabledBorder: _inputBorder(SilverStockColors.borderLight),
                focusedBorder: _inputBorder(
                  SilverStockColors.brandSilver,
                  width: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: ctrl.canProceedFromPurity ? ctrl.nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SilverStockColors.shellBg,
                  disabledBackgroundColor: SilverStockColors.inputBgLocked,
                  foregroundColor: Colors.white,
                  elevation: ctrl.canProceedFromPurity ? 2 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Continue to Item Entry',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) {
              if (ctrl.canProceedFromPurity) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Select a stock grade to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    final ctrl = widget.ctrl;

    return Container(
      decoration: SilverStockStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(
                icon: Icons.inventory_2_rounded,
                color: SilverStockColors.brandSilver,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Silver Stock Summary',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SilverStockColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Available inventory grouped by business grade with total fine weight.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              color: SilverStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) {
              if (ctrl.isLoadingStockSummary) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SilverStockColors.brandSilver,
                      ),
                    ),
                  ),
                );
              }

              final groups = _stockGroups(ctrl.purityStockSummary);
              if (groups.every((group) => group.fineWeight <= 0)) {
                return _EmptyStockState();
              }

              return Column(
                children: groups
                    .where((group) => group.fineWeight > 0)
                    .map((group) => _StockGroupRow(group: group))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: SilverStockColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Classification Rules',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.brandSilver,
            ),
          ),
          const SizedBox(height: 10),
          _guideline('Sterling: total purity close to 92.50%.'),
          _guideline('Jewellery: total purity up to 60.00%.'),
          _guideline('Utensils and idols: total purity above 60.00%.'),
          _guideline('Other grades stay grouped separately for review.'),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _guideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SilverStockColors.brandSilver,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.5,
                color: SilverStockColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_StockGroup> _stockGroups(Map<String, double> summary) {
    final groups = <_StockGroup>[
      const _StockGroup(
        label: 'Fine Silver',
        description: '99.99% grade',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFF526677),
      ),
      const _StockGroup(
        label: 'Sterling',
        description: '92.50% grade',
        icon: Icons.verified_rounded,
        color: Color(0xFF0F8A72),
      ),
      const _StockGroup(
        label: 'Idols',
        description: 'Above 75.00% fine',
        icon: Icons.temple_hindu_rounded,
        color: Color(0xFF8B5CF6),
      ),
      const _StockGroup(
        label: 'Utensils',
        description: '60.01% to 75.00%',
        icon: Icons.soup_kitchen_rounded,
        color: Color(0xFF2563EB),
      ),
      const _StockGroup(
        label: 'Jewellery',
        description: 'Up to 60.00%',
        icon: Icons.diamond_rounded,
        color: Color(0xFFB7791F),
      ),
      const _StockGroup(
        label: 'Other',
        description: 'Needs review',
        icon: Icons.category_rounded,
        color: Color(0xFF64748B),
      ),
    ];

    final totals = {for (final group in groups) group.label: 0.0};
    for (final entry in summary.entries) {
      final percent = _extractPurityPercent(entry.key);
      final fineWeight = percent <= 0 ? 0.0 : entry.value * percent / 100.0;
      final bucket = _bucketFor(percent);
      totals[bucket] = (totals[bucket] ?? 0.0) + fineWeight;
    }

    return groups
        .map((group) => group.copyWith(fineWeight: totals[group.label] ?? 0.0))
        .toList(growable: false);
  }

  String _bucketFor(double percent) {
    if (percent >= 99.5) {
      return 'Fine Silver';
    }
    if ((percent - 92.5).abs() <= 1.0) {
      return 'Sterling';
    }
    if (percent > 75.0) {
      return 'Idols';
    }
    if (percent > 60.0) {
      return 'Utensils';
    }
    if (percent > 0) {
      return 'Jewellery';
    }
    return 'Other';
  }

  double _extractPurityPercent(String raw) {
    final value = raw.toUpperCase();
    final touchMatch =
        RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%\s*TOUCH').firstMatch(value);
    if (touchMatch != null) {
      return double.tryParse(touchMatch.group(1) ?? '') ?? 0.0;
    }

    final percentMatches = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%')
        .allMatches(value)
        .toList(growable: false);
    if (percentMatches.isNotEmpty) {
      return double.tryParse(percentMatches.last.group(1) ?? '') ?? 0.0;
    }

    final codeMatch = RegExp(r'\b(999|925|800|700)\b').firstMatch(value);
    if (codeMatch != null) {
      final code = double.tryParse(codeMatch.group(1) ?? '');
      if (code != null) {
        return code / 10.0;
      }
    }

    final numericMatch = RegExp(r'\b(\d{2}(?:\.\d+)?)\b').firstMatch(value);
    if (numericMatch != null) {
      return double.tryParse(numericMatch.group(1) ?? '') ?? 0.0;
    }

    return 0.0;
  }
}

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
                  'Set the batch grade before entering items, wastage and supplier settlement.',
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
              selected.isEmpty ? 'GRADE OPEN' : selected,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.value,
                style: GoogleFonts.manrope(
                  fontSize: 20,
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
                  fontSize: 11,
                  height: 1.35,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockGroupRow extends StatelessWidget {
  final _StockGroup group;

  const _StockGroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: group.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _IconBadge(icon: group.icon, color: group.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  group.description,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${group.fineWeight.toStringAsFixed(3)} g',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: group.color,
                ),
              ),
              Text(
                'Total Fine',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStockState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilverLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SilverStockColors.brandSilver.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 28,
            color: SilverStockColors.brandSilver.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
          Text(
            'No silver stock recorded yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SilverStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved batches will appear here by business grade.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 1.5,
              color: SilverStockColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _SilverPurityOption {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  const _SilverPurityOption({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });
}

class _StockGroup {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final double fineWeight;

  const _StockGroup({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.fineWeight = 0.0,
  });

  _StockGroup copyWith({double? fineWeight}) {
    return _StockGroup(
      label: label,
      description: description,
      icon: icon,
      color: color,
      fineWeight: fineWeight ?? this.fineWeight,
    );
  }
}
