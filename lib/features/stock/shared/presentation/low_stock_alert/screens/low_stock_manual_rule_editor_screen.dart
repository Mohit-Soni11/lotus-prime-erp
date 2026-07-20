import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockManualRuleEditorScreen extends StatefulWidget {
  final LowStockAlertController controller;
  final LowStockStockCard? autoCard;
  final LowStockAlertRule? rule;

  const LowStockManualRuleEditorScreen({
    super.key,
    required this.controller,
    this.autoCard,
    this.rule,
  });

  @override
  State<LowStockManualRuleEditorScreen> createState() =>
      _LowStockManualRuleEditorScreenState();
}

class _LowStockManualRuleEditorScreenState
    extends State<LowStockManualRuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _metalType;
  late final TextEditingController _grade;
  late final TextEditingController _item;
  late final TextEditingController _redPcs;
  late final TextEditingController _yellowPcs;
  late final TextEditingController _targetPcs;
  late final TextEditingController _sets;
  late final TextEditingController _packets;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    final card = widget.autoCard;
    _metalType = rule?.metalType ??
        card?.metalType ??
        (widget.controller.metalCards.isEmpty
            ? 'Gold'
            : widget.controller.metalCards.first.metalType);
    _grade = TextEditingController(
      text: rule?.gradeLabel ?? _editableGradeFromCard(card),
    );
    _item = TextEditingController(
      text: rule == null
          ? _editableItemFromCard(card)
          : _editableItemFromRule(rule),
    );
    _redPcs = TextEditingController(
      text: '${rule?.criticalUnits ?? card?.criticalUnits ?? 0}',
    );
    _yellowPcs = TextEditingController(
      text: '${rule?.thresholdUnits ?? card?.thresholdUnits ?? 0}',
    );
    _targetPcs = TextEditingController(
      text: '${rule?.targetUnits ?? card?.targetUnits ?? 0}',
    );
    _sets = TextEditingController(
        text: '${rule?.targetSets ?? card?.targetSets ?? 0}');
    _packets = TextEditingController(
      text: '${rule?.targetPackets ?? card?.targetPackets ?? 0}',
    );
  }

  @override
  void dispose() {
    _grade.dispose();
    _item.dispose();
    _redPcs.dispose();
    _yellowPcs.dispose();
    _targetPcs.dispose();
    _sets.dispose();
    _packets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopeLocked = widget.autoCard != null || widget.rule != null;
    final metals = {
      for (final card in widget.controller.metalCards) card.metalType,
      'Gold',
      'Silver',
    }.toList(growable: false);
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: LowStockAlertAppBar(
        onBack: () => Navigator.of(context).maybePop(),
        onRefresh: widget.controller.load,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: InvColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          color: InvColors.brandGold, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.autoCard == null
                                  ? 'Manual Alert Rule'
                                  : 'Set Alert Rule From Stock',
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: InvColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set when this stock should become red, yellow and green.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: InvColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (scopeLocked)
                    _lockedValue('Metal', _metalType, Icons.category_rounded)
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _metalType,
                      decoration: _decoration('Metal'),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      iconEnabledColor: InvColors.brandGold,
                      style: _inputTextStyle(),
                      items: [
                        for (final metal in metals)
                          DropdownMenuItem(
                            value: metal,
                            child: Text(metal, style: _inputTextStyle()),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _metalType = value);
                      },
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _grade,
                          'Grade',
                          readOnly: scopeLocked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _item,
                          'Item type',
                          readOnly: scopeLocked,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Pieces Alert Levels'),
                  Row(
                    children: [
                      Expanded(
                        child: _levelField(
                          _redPcs,
                          'Red',
                          'Critical pcs',
                          InvColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _levelField(
                          _yellowPcs,
                          'Yellow',
                          'Half stock pcs',
                          InvColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _levelField(
                          _targetPcs,
                          'Green',
                          'Full target pcs',
                          InvColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TargetNote(
                    totalPcs: _targetPcs.text,
                    yellowPcs: _yellowPcs.text,
                    redPcs: _redPcs.text,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Set / Packet'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _sets,
                          'Target set',
                          validator: _validInt,
                          readOnly: scopeLocked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _packets,
                          'Target packet',
                          validator: _validInt,
                          readOnly: scopeLocked,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Rule'),
                        style: FilledButton.styleFrom(
                          backgroundColor: InvColors.brandGold,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: _decoration(label),
      style: _inputTextStyle(),
      validator: validator,
      onChanged: onChanged,
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.inter(
      color: InvColors.textDark,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    );
  }

  Widget _levelField(
    TextEditingController controller,
    String title,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: InvColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            controller,
            label,
            validator: _validInt,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _lockedValue(String label, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InvColors.brandGold, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: InvColors.brandGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: InvColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: _inputTextStyle()),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: InvColors.textDark, size: 18),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: InvColors.textDark,
        fontWeight: FontWeight.w800,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: InvColors.textDark,
        fontWeight: FontWeight.w900,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: InvColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: InvColors.brandGold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: InvColors.danger),
      ),
    );
  }

  String? _validInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Invalid' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final grade = _grade.text.trim();
    final item = _item.text.trim();
    if (grade.isEmpty && item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set grade or item type for this rule')),
      );
      return;
    }
    final red = int.parse(_redPcs.text.trim());
    final yellow = int.parse(_yellowPcs.text.trim());
    final target = int.parse(_targetPcs.text.trim());
    if (!(red <= yellow && yellow <= target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use Red <= Yellow <= Target pcs')),
      );
      return;
    }
    await widget.controller.saveManualRule(
      LowStockManualRuleDraft(
        metalType: _metalType,
        gradeLabel: grade,
        itemType: item,
        criticalUnits: red,
        thresholdUnits: yellow,
        targetUnits: target,
        criticalNetWeight: 0,
        thresholdNetWeight: 0,
        targetNetWeight: 0,
        targetSets: int.tryParse(_sets.text.trim()) ?? 0,
        targetPackets: int.tryParse(_packets.text.trim()) ?? 0,
        preferredSupplierName: '',
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  String _editableGradeFromCard(LowStockStockCard? card) {
    if (card == null) return '';
    if (card.level == LowStockCardLevel.itemGroup) return '';
    return card.gradeLabel.trim();
  }

  String _editableItemFromCard(LowStockStockCard? card) {
    if (card == null) return '';
    if (card.level == LowStockCardLevel.grade) return '';
    final item = card.itemType.trim();
    if (item.toLowerCase() == LowStockConstants.anyItemKey) return '';
    return item;
  }

  String _editableItemFromRule(LowStockAlertRule rule) {
    final item = rule.itemType.trim();
    if (item.toLowerCase() == LowStockConstants.anyItemKey) return '';
    return item;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: InvColors.textDark,
        ),
      ),
    );
  }
}

class _TargetNote extends StatelessWidget {
  final String totalPcs;
  final String yellowPcs;
  final String redPcs;

  const _TargetNote({
    required this.totalPcs,
    required this.yellowPcs,
    required this.redPcs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvColors.success.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: InvColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Green target $totalPcs pcs is the full stock level to maintain. '
              'Yellow starts at $yellowPcs pcs, Red starts at $redPcs pcs.',
              style: GoogleFonts.inter(
                color: InvColors.textDark,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
