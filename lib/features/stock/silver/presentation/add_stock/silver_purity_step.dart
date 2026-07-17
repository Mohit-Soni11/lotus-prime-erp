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

  bool _showPurityBuilder = false;
  String? _customError;

  static const List<_SilverPurityOption> _presets = [
    _SilverPurityOption(
      label: '999 Fine Silver',
      value: '99.90%',
      detail: 'Coins, bullion and premium silver articles',
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFF526677),
    ),
    _SilverPurityOption(
      label: '925 Sterling Silver',
      value: '92.50%',
      detail: 'Hallmarked jewellery and premium ornaments',
      icon: Icons.verified_rounded,
      accent: Color(0xFF0F8A72),
    ),
    _SilverPurityOption(
      label: '800 Premium Silver',
      value: '80.00%',
      detail: 'Pooja articles, idols and crafted stock',
      icon: Icons.temple_hindu_rounded,
      accent: Color(0xFF8B5CF6),
    ),
    _SilverPurityOption(
      label: '700 Utility Silver',
      value: '70.00%',
      detail: 'Utensils, tableware and durable articles',
      icon: Icons.soup_kitchen_rounded,
      accent: Color(0xFF2563EB),
    ),
    _SilverPurityOption(
      label: '600 Lightweight Silver',
      value: '60.00%',
      detail: 'Daily wear and lightweight commercial stock',
      icon: Icons.diamond_rounded,
      accent: Color(0xFFB7791F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController();
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
            'Select Silver Intake Type',
            style: SilverStockStyles.pageTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one fixed silver purity for a clean grade batch, or use Mixed Silver Supplier Invoice when one supplier bill contains multiple companies, item groups or purities.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: SilverStockColors.textDark,
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
                  final isSelected = ctrl.purityDisplay == preset.value;

                  return SizedBox(
                    width: itemWidth,
                    child: _PurityCard(
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () {
                        ctrl.setPurity(preset.value);
                        setState(() {
                          _showPurityBuilder = false;
                          _customError = null;
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _CreateSilverGradeButton(
                expanded: _showPurityBuilder,
                icon: Icons.add_rounded,
                label: _showPurityBuilder
                    ? 'Close Custom Purity Builder'
                    : 'Create Custom Silver Purity',
                onTap: () => setState(() {
                  _showPurityBuilder = !_showPurityBuilder;
                  _customError = null;
                }),
              ),
              _MixedSilverInvoiceButton(
                selected: ctrl.isMixedInvoiceMode,
                onTap: () {
                  ctrl.startMixedSupplierInvoice();
                  setState(() {
                    _showPurityBuilder = false;
                    _customError = null;
                  });
                },
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _showPurityBuilder
                ? Padding(
                    key: const ValueKey('custom-silver-purity-builder'),
                    padding: const EdgeInsets.only(top: 14),
                    child: _CustomSilverPurityPanel(
                      purityCtrl: _customCtrl,
                      errorText: _customError,
                      onCreate: _createCustomPurity,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
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
                  'Select a silver grade or mixed supplier invoice to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SilverStockColors.textDark,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createCustomPurity() {
    final purity = _parsePurity(_customCtrl.text);
    if (purity <= 0 || purity > 100) {
      setState(() {
        _customError = 'Enter a valid silver purity between 1 and 100.';
      });
      return;
    }

    final display = '${_formatPurity(purity)}%';
    widget.ctrl.setPurity('Custom');
    widget.ctrl.setCustomPurity(display);
    _customCtrl.clear();
    setState(() {
      _showPurityBuilder = false;
      _customError = null;
    });
  }

  double _parsePurity(String value) {
    final normalized = value.replaceAll('%', '').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatPurity(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
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
            'Available inventory grouped by silver grade with total fine weight.',
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
          _guideline('999 Fine Silver is used for coins, bars and bullion.'),
          _guideline(
              '925 Sterling Silver is preferred for hallmarked jewellery.'),
          _guideline(
              '800 and 700 grades are used for idols, utensils and utility stock.'),
          _guideline(
              'Custom grades remain traceable as separate inventory groups.'),
          _guideline(
              'Use Mixed Silver Supplier Invoice for one supplier bill with multiple companies or purities.'),
        ],
      ),
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
        label: '999 Fine Silver',
        description: '99.90% grade',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFF526677),
      ),
      const _StockGroup(
        label: '925 Sterling Silver',
        description: '92.50% grade',
        icon: Icons.verified_rounded,
        color: Color(0xFF0F8A72),
      ),
      const _StockGroup(
        label: '800 Premium Silver',
        description: '80.00% grade',
        icon: Icons.temple_hindu_rounded,
        color: Color(0xFF8B5CF6),
      ),
      const _StockGroup(
        label: '700 Utility Silver',
        description: '70.00% grade',
        icon: Icons.soup_kitchen_rounded,
        color: Color(0xFF2563EB),
      ),
      const _StockGroup(
        label: '600 Lightweight Silver',
        description: '60.00% grade',
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
      return '999 Fine Silver';
    }
    if ((percent - 92.5).abs() <= 1.0) {
      return '925 Sterling Silver';
    }
    if (percent > 75.0) {
      return '800 Premium Silver';
    }
    if (percent > 60.0) {
      return '700 Utility Silver';
    }
    if (percent > 0) {
      return '600 Lightweight Silver';
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
