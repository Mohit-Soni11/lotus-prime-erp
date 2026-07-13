import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_purity_catalog_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/gold/domain/models/gold_purity_profile.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldPurityStep extends StatefulWidget {
  final GoldStockController ctrl;

  const GoldPurityStep({super.key, required this.ctrl});

  @override
  State<GoldPurityStep> createState() => _GoldPurityStepState();
}

class _GoldPurityStepState extends State<GoldPurityStep>
    with SingleTickerProviderStateMixin {
  late final GoldPurityCatalogController _catalog;
  late final TextEditingController _customNameCtrl;
  late final TextEditingController _customKaratCtrl;
  late final TextEditingController _customHallmarkCtrl;
  late final TextEditingController _customPercentCtrl;
  late final TextEditingController _customDescriptionCtrl;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _showCustomBuilder = false;
  String? _customError;

  @override
  void initState() {
    super.initState();
    _catalog = GoldPurityCatalogController()..load();
    _customNameCtrl = TextEditingController();
    _customKaratCtrl = TextEditingController();
    _customHallmarkCtrl = TextEditingController();
    _customPercentCtrl = TextEditingController();
    _customDescriptionCtrl = TextEditingController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
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
    _catalog.dispose();
    _customNameCtrl.dispose();
    _customKaratCtrl.dispose();
    _customHallmarkCtrl.dispose();
    _customPercentCtrl.dispose();
    _customDescriptionCtrl.dispose();
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
      decoration: GoldStockStyles.cardWithAccent(GoldStockColors.brandGold),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBanner(ctrl: ctrl),
          const SizedBox(height: 24),
          Text(
            'Select Gold Purity Grade',
            style: _titleStyle(24),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the base purity for this gold stock batch. Item rows can add wastage later, and the final purity will be used for valuation, billing and inventory classification.',
            style: _bodyStyle(14),
          ),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: _catalog,
            builder: (_, __) => _buildProfileGrid(),
          ),
          const SizedBox(height: 14),
          _CreateCustomGradeButton(
            expanded: _showCustomBuilder,
            onTap: () => setState(() {
              _showCustomBuilder = !_showCustomBuilder;
              _customError = null;
            }),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _showCustomBuilder
                ? Padding(
                    key: const ValueKey('custom-grade-builder'),
                    padding: const EdgeInsets.only(top: 14),
                    child: _CustomGradePanel(
                      nameCtrl: _customNameCtrl,
                      karatCtrl: _customKaratCtrl,
                      hallmarkCtrl: _customHallmarkCtrl,
                      percentCtrl: _customPercentCtrl,
                      descriptionCtrl: _customDescriptionCtrl,
                      errorText: _customError,
                      onCreate: _createCustomProfile,
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
                  backgroundColor: GoldStockColors.shellBg,
                  disabledBackgroundColor: GoldStockColors.inputBgLocked,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          if (!ctrl.canProceedFromPurity) ...[
            const SizedBox(height: 10),
            Text(
              'Select a gold purity grade to continue.',
              style: _bodyStyle(13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileGrid() {
    if (_catalog.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: GoldStockColors.brandGold,
          ),
        ),
      );
    }

    return LayoutBuilder(
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
          children: _catalog.profiles.map((profile) {
            return SizedBox(
              width: itemWidth,
              child: _PurityCard(
                profile: profile,
                tone: _toneFor(profile),
                icon: _iconFor(profile),
                isSelected: _isSelected(profile),
                onTap: () {
                  widget.ctrl.setPurity(profile.displayValue);
                  setState(() => _customError = null);
                },
                onDelete: profile.isCustom
                    ? () async {
                        if (_isSelected(profile)) {
                          widget.ctrl.setPurity('');
                        }
                        await _catalog.deleteCustomProfile(profile.id);
                      }
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSidePanel() {
    final ctrl = widget.ctrl;

    return Container(
      decoration: GoldStockStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(
                icon: Icons.inventory_2_rounded,
                color: GoldStockColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gold Stock Summary',
                  style: _titleStyle(16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Available inventory grouped by business grade with total fine weight.',
            style: _bodyStyle(12),
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
                        color: GoldStockColors.brandGold,
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
          const Divider(height: 1, color: GoldStockColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Classification Rules',
            style: _titleStyle(14).copyWith(color: GoldStockColors.brandGold),
          ),
          const SizedBox(height: 10),
          _guideline('24KT: 999 fine gold, coins and bullion.'),
          _guideline('22KT: 916 hallmarked jewellery stock.'),
          _guideline(
              '18KT and 14KT: studded, diamond and lightweight articles.'),
          _guideline(
              'Custom karat, hallmark or percentage grades remain traceable.'),
        ],
      ),
    );
  }

  Future<void> _createCustomProfile() async {
    final profile = await _catalog.createCustomProfile(
      name: _customNameCtrl.text,
      karatText: _customKaratCtrl.text,
      hallmarkText: _customHallmarkCtrl.text,
      purityPercentText: _customPercentCtrl.text,
      description: _customDescriptionCtrl.text,
    );

    if (!mounted) {
      return;
    }

    if (profile == null) {
      setState(() {
        _customError =
            'Enter a profile name and a valid karat, hallmark or purity percent.';
      });
      return;
    }

    widget.ctrl.setPurity(profile.displayValue);
    _customNameCtrl.clear();
    _customKaratCtrl.clear();
    _customHallmarkCtrl.clear();
    _customPercentCtrl.clear();
    _customDescriptionCtrl.clear();
    setState(() {
      _showCustomBuilder = false;
      _customError = null;
    });
  }

  bool _isSelected(GoldPurityProfile profile) {
    return widget.ctrl.purityDisplay.trim().toUpperCase() ==
        profile.displayValue.trim().toUpperCase();
  }

  Color _toneFor(GoldPurityProfile profile) {
    final percent = profile.purityPercent;
    if (profile.isCustom) {
      return GoldStockColors.textDark;
    }
    if (percent >= 99) {
      return const Color(0xFFD4AF37);
    }
    if (percent >= 90) {
      return const Color(0xFFB88718);
    }
    if (percent >= 73) {
      return const Color(0xFF2563EB);
    }
    if (percent >= 56) {
      return const Color(0xFF0F8A72);
    }
    return const Color(0xFF8B5CF6);
  }

  IconData _iconFor(GoldPurityProfile profile) {
    final percent = profile.purityPercent;
    if (profile.isCustom) {
      return Icons.tune_rounded;
    }
    if (percent >= 99) {
      return Icons.workspace_premium_rounded;
    }
    if (percent >= 90) {
      return Icons.verified_rounded;
    }
    if (percent >= 73) {
      return Icons.diamond_rounded;
    }
    if (percent >= 56) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.category_rounded;
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
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GoldStockColors.brandGold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: _bodyStyle(12)),
          ),
        ],
      ),
    );
  }

  List<_StockGroup> _stockGroups(Map<String, double> summary) {
    final groups = <_StockGroup>[
      const _StockGroup(
        label: '24KT Fine Gold',
        description: '999 fine grade',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFD4AF37),
      ),
      const _StockGroup(
        label: '22KT Hallmark Gold',
        description: '916 jewellery',
        icon: Icons.verified_rounded,
        color: Color(0xFFB88718),
      ),
      const _StockGroup(
        label: '18KT Studded Gold',
        description: '750 jewellery',
        icon: Icons.diamond_rounded,
        color: Color(0xFF2563EB),
      ),
      const _StockGroup(
        label: '14KT Lightweight Gold',
        description: '585 jewellery',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF0F8A72),
      ),
      const _StockGroup(
        label: '9KT Low Karat Gold',
        description: '375 and lower',
        icon: Icons.category_rounded,
        color: Color(0xFF8B5CF6),
      ),
      const _StockGroup(
        label: 'Custom Gold Grade',
        description: 'Custom purity stock',
        icon: Icons.tune_rounded,
        color: Color(0xFF0F172A),
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
    if (percent >= 99.5) return '24KT Fine Gold';
    if (percent >= 90.0) return '22KT Hallmark Gold';
    if (percent >= 73.0) return '18KT Studded Gold';
    if (percent >= 56.0) return '14KT Lightweight Gold';
    if (percent > 0) return '9KT Low Karat Gold';
    return 'Custom Gold Grade';
  }

  double _extractPurityPercent(String raw) {
    final value = raw.toUpperCase().replaceAll('KT', 'K');
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

    final codeMatch =
        RegExp(r'\b(999|995|916|900|833|750|585|375)\b').firstMatch(value);
    if (codeMatch != null) {
      final code = double.tryParse(codeMatch.group(1) ?? '');
      if (code != null) return code / 10.0;
    }

    final karatMatch = RegExp(r'\b(\d{1,2})\s*K\b').firstMatch(value);
    if (karatMatch != null) {
      final karat = double.tryParse(karatMatch.group(1) ?? '');
      if (karat != null) return karat / 24.0 * 100.0;
    }

    return 0.0;
  }
}

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
                Text(group.label, style: _titleStyle(13)),
                const SizedBox(height: 2),
                Text(group.description, style: _bodyStyle(11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${group.fineWeight.toStringAsFixed(3)} g',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: group.color,
                    ),
                  ),
                ),
                Text('Total Fine', style: _bodyStyle(10)),
              ],
            ),
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
        color: GoldStockColors.brandGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GoldStockColors.brandGold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 28,
            color: GoldStockColors.brandGold.withValues(alpha: 0.70),
          ),
          const SizedBox(height: 8),
          Text(
            'No gold stock recorded yet.',
            textAlign: TextAlign.center,
            style: _titleStyle(13),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved batches will appear here by business grade.',
            textAlign: TextAlign.center,
            style: _bodyStyle(11),
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

TextStyle _titleStyle(double size) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: GoldStockColors.textDark,
  );
}

TextStyle _bodyStyle(double size) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: GoldStockColors.textDark,
  );
}
