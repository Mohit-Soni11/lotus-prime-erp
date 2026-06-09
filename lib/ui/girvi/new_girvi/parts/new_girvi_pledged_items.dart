part of '../new_girvi_screen.dart';

class _PledgedItemDraft {
  _PledgedItemDraft({
    required this.serialNo,
    required this.onChanged,
  }) {
    customPurityCtrl.text = purity.displayName;
    for (final controller in [
      descriptionCtrl,
      piecesCtrl,
      huidCtrl,
      grossCtrl,
      lessCtrl,
      rateCtrl,
      customPurityCtrl,
    ]) {
      controller.addListener(_notifyChanged);
    }
  }

  int serialNo;
  final VoidCallback onChanged;

  final descriptionCtrl = TextEditingController();
  final piecesCtrl = TextEditingController(text: '1');
  final huidCtrl = TextEditingController();
  final grossCtrl = TextEditingController();
  final lessCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final customPurityCtrl = TextEditingController();

  final descriptionFocus = FocusNode();
  final piecesFocus = FocusNode();
  final huidFocus = FocusNode();
  final grossFocus = FocusNode();
  final lessFocus = FocusNode();
  final rateFocus = FocusNode();
  final customPurityFocus = FocusNode();

  MetalType metalType = MetalType.gold;
  MetalPurity purity = MetalPurity.k22;
  String? photoPath;

  int get itemCount => (int.tryParse(piecesCtrl.text.trim()) ?? 1).clamp(1, 99);
  double get grossWeight => double.tryParse(grossCtrl.text) ?? 0.0;
  double get lessWeight => double.tryParse(lessCtrl.text) ?? 0.0;
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);
  double get purityFactor => _purityFactorFor(this);
  double get fineWeight => netWeight * purityFactor;
  double get ratePerGram => double.tryParse(rateCtrl.text) ?? 0.0;
  double get itemValue => fineWeight * ratePerGram;
  bool get hasPhoto =>
      photoPath != null &&
      photoPath!.isNotEmpty &&
      File(photoPath!).existsSync();

  String get purityLabel {
    final custom = customPurityCtrl.text.trim();
    if (purity == MetalPurity.other && custom.isNotEmpty) return custom;
    return purity.displayName;
  }

  void setMetalType(MetalType value) {
    metalType = value;
    final options = _purityOptionsForMetal(value);
    if (!options.contains(purity)) {
      purity = _defaultPurityForMetal(value);
    }
    _syncPurityText();
    _notifyChanged();
  }

  void setPurity(MetalPurity value) {
    purity = value;
    _syncPurityText();
    _notifyChanged();
  }

  void setPurityText(String value) {
    final matched = _matchPurityText(metalType, value);
    purity = matched ?? MetalPurity.other;
    _notifyChanged();
  }

  void setItemCount(int value) {
    piecesCtrl.text = value.clamp(1, 99).toString();
    _notifyChanged();
  }

  void _notifyChanged() => onChanged();

  void _syncPurityText() {
    if (purity == MetalPurity.other) {
      if (_isKnownPurityText(customPurityCtrl.text)) {
        customPurityCtrl.clear();
      }
      return;
    }
    customPurityCtrl.text = purity.displayName;
    customPurityCtrl.selection = TextSelection.collapsed(
      offset: customPurityCtrl.text.length,
    );
  }

  void dispose() {
    for (final controller in [
      descriptionCtrl,
      piecesCtrl,
      huidCtrl,
      grossCtrl,
      lessCtrl,
      rateCtrl,
      customPurityCtrl,
    ]) {
      controller.removeListener(_notifyChanged);
      controller.dispose();
    }
    for (final focus in [
      descriptionFocus,
      piecesFocus,
      huidFocus,
      grossFocus,
      lessFocus,
      rateFocus,
      customPurityFocus,
    ]) {
      focus.dispose();
    }
  }
}

List<MetalPurity> _purityOptionsForMetal(MetalType metalType) {
  switch (metalType) {
    case MetalType.gold:
      return const [
        MetalPurity.k24,
        MetalPurity.k22,
        MetalPurity.k18,
        MetalPurity.k14,
        MetalPurity.other,
      ];
    case MetalType.silver:
      return const [
        MetalPurity.s999,
        MetalPurity.s925,
        MetalPurity.s800,
        MetalPurity.other,
      ];
    case MetalType.diamond:
    case MetalType.platinum:
    case MetalType.mixed:
    case MetalType.other:
      return const [MetalPurity.other];
  }
}

MetalPurity _defaultPurityForMetal(MetalType metalType) {
  switch (metalType) {
    case MetalType.gold:
      return MetalPurity.k22;
    case MetalType.silver:
      return MetalPurity.s925;
    case MetalType.diamond:
    case MetalType.platinum:
    case MetalType.mixed:
    case MetalType.other:
      return MetalPurity.other;
  }
}

MetalPurity? _matchPurityText(MetalType metalType, String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  for (final purity in _purityOptionsForMetal(metalType)) {
    if (purity == MetalPurity.other) continue;
    if (purity.displayName.toUpperCase() == normalized ||
        purity.dbValue.toUpperCase() == normalized) {
      return purity;
    }
  }
  return null;
}

bool _isKnownPurityText(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return false;
  return MetalPurity.values.any(
    (purity) =>
        purity != MetalPurity.other &&
        (purity.displayName.toUpperCase() == normalized ||
            purity.dbValue.toUpperCase() == normalized),
  );
}

Color _pledgedMetalAccent(MetalType metalType) {
  switch (metalType) {
    case MetalType.gold:
      return GirviColors.brandGold;
    case MetalType.silver:
      return GirviColors.textMuted;
    case MetalType.diamond:
      return GirviColors.info;
    case MetalType.platinum:
      return GirviColors.purple;
    case MetalType.mixed:
      return GirviColors.warning;
    case MetalType.other:
      return GirviColors.textBody;
  }
}

double _purityFactorFor(_PledgedItemDraft item) {
  if (item.purity != MetalPurity.other) return item.purity.fineness;

  final text = item.customPurityCtrl.text.trim().toUpperCase();
  if (text.isEmpty) return 1.0;

  final numberMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
  final parsed = double.tryParse(numberMatch?.group(1) ?? '');
  if (parsed == null || parsed <= 0) return 1.0;

  if (text.contains('K')) return (parsed / 24).clamp(0.0, 1.0);
  if (text.contains('%')) return (parsed / 100).clamp(0.0, 1.0);
  if (parsed > 1 && parsed <= 24 && item.metalType == MetalType.gold) {
    return (parsed / 24).clamp(0.0, 1.0);
  }
  if (parsed > 100) return (parsed / 1000).clamp(0.0, 1.0);
  if (parsed > 1) return (parsed / 100).clamp(0.0, 1.0);
  return parsed.clamp(0.0, 1.0);
}

extension NewGirviPledgedItemsSection on _NewGirviScreenState {
  Widget _buildPledgedItemsSection() {
    return _LedgerSectionCard(
      icon: GirviIcons.itemDetails,
      title: 'Pledged Item Ledger',
      subtitle: 'Fast entry for multiple loan items',
      accent: GirviColors.accentItem,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPledgedItemsToolbar(),
          const SizedBox(height: 12),
          _buildPledgedItemsGrid(),
          if (_pledgedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPledgedItemsTotals(),
            const SizedBox(height: 10),
            _buildPhotoAuditStrip(),
          ],
        ],
      ),
    );
  }

  Widget _buildPledgedValuationSection() {
    return _LedgerSectionCard(
      icon: GirviIcons.valuation,
      title: 'Valuation',
      subtitle: 'Fine weight based market valuation',
      accent: GirviColors.accentValuation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildValuationGrid(),
          const SizedBox(height: 12),
          GirviReadOnlyField(
            label: 'Total Item Value',
            value: 'Rs ${_fmt.format(_ctrl.totalValue)}',
            highlighted: _ctrl.totalValue > 0,
          ),
          if (_ctrl.totalValue > 0) ...[
            const SizedBox(height: 12),
            _LtvSuggestionRow(
              totalValue: _ctrl.totalValue,
              onSuggestionTap: (ltv) {
                _ctrl.onLtvChanged(ltv);
                _loanAmtCtrl.text = _ctrl.loanAmount.toStringAsFixed(2);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPledgedItemsToolbar() {
    final countLabel = _pledgedItems.isEmpty
        ? 'No pledged item added'
        : '${_pledgedItems.length} pledged item'
            '${_pledgedItems.length == 1 ? '' : 's'} ready for loan entry';
    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _LedgerAddButton(onTap: _addPledgedItem),
      ],
    );
  }

  Widget _buildPledgedItemsGrid() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth =
                constraints.maxWidth < 1156 ? 1156.0 : constraints.maxWidth;
            final columnScale =
                ((tableWidth - 82) / 1074).clamp(1.0, 1.25).toDouble();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LedgerHeader(
                      scale: columnScale,
                      columns: const [
                        _LedgerColumn('S/N', 40),
                        _LedgerColumn('Metal', 92),
                        _LedgerColumn('Item Description', 190),
                        _LedgerColumn('Pcs', 56),
                        _LedgerColumn('HUID', 110),
                        _LedgerColumn('Purity', 150),
                        _LedgerColumn('Gross', 84),
                        _LedgerColumn('Less', 84),
                        _LedgerColumn('Net', 86),
                        _LedgerColumn('Fine', 86),
                        _LedgerColumn('Photo', 54),
                        _LedgerColumn('Act', 42),
                      ],
                    ),
                    if (_pledgedItems.isEmpty)
                      _buildPledgedLedgerEmptyState()
                    else
                      for (final item in _pledgedItems)
                        _buildPledgedLedgerRow(item, columnScale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPledgedLedgerRow(_PledgedItemDraft item, double scale) {
    double w(double value) => value * scale;
    return Container(
      decoration: BoxDecoration(
        color: item.serialNo.isOdd ? Colors.white : GirviColors.inputBg,
        border: const Border(
          top: BorderSide(color: GirviColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LedgerSerialCell(serialNo: item.serialNo, width: w(40)),
          const SizedBox(width: 6),
          _LedgerDropdownCell<MetalType>(
            width: w(92),
            value: item.metalType,
            accent: _pledgedMetalAccent(item.metalType),
            items: MetalType.values
                .map((metal) => DropdownMenuItem(
                      value: metal,
                      child: Text(metal.displayName.toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) item.setMetalType(value);
            },
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(190),
            controller: item.descriptionCtrl,
            focusNode: item.descriptionFocus,
            hint: 'Item name',
            validator: _ctrl.validateItemDescription,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(56),
            controller: item.piecesCtrl,
            focusNode: item.piecesFocus,
            hint: '1',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            validator: (value) {
              final pcs = int.tryParse(value?.trim() ?? '');
              if (pcs == null || pcs <= 0) return 'Required';
              return null;
            },
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(110),
            controller: item.huidCtrl,
            focusNode: item.huidFocus,
            hint: 'HUID',
          ),
          const SizedBox(width: 6),
          _LedgerPurityCell(
            width: w(150),
            item: item,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(84),
            controller: item.grossCtrl,
            focusNode: item.grossFocus,
            hint: '0.000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            textAlign: TextAlign.right,
            validator: _ctrl.validateGrossWeight,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(84),
            controller: item.lessCtrl,
            focusNode: item.lessFocus,
            hint: '0.000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            textAlign: TextAlign.right,
            validator: (value) => _validateLessWeight(item, value),
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(86),
            value: item.netWeight.toStringAsFixed(3),
            color: GirviColors.brandGold,
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(86),
            value: item.fineWeight.toStringAsFixed(3),
            color: GirviColors.success,
          ),
          const SizedBox(width: 6),
          _LedgerPhotoCell(
            width: w(54),
            hasPhoto: item.hasPhoto,
            onTap: () => _pickPledgedItemPhoto(item),
            onRemove: () => _removePledgedItemPhoto(item),
          ),
          const SizedBox(width: 6),
          _LedgerActionCell(
            width: w(42),
            enabled: true,
            onDelete: () => _removePledgedItem(item),
          ),
        ],
      ),
    );
  }

  Widget _buildPledgedLedgerEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: const BoxDecoration(
        color: GirviColors.cardBg,
        border: Border(top: BorderSide(color: GirviColors.divider)),
      ),
      child: Center(
        child: InkWell(
          onTap: _addPledgedItem,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: GirviColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GirviColors.success.withValues(alpha: 0.26),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: GirviColors.success,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'ADD NEW ITEM',
                  style: GoogleFonts.inter(
                    color: GirviColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValuationGrid() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth =
                constraints.maxWidth < 902 ? 902.0 : constraints.maxWidth;
            final columnScale =
                ((tableWidth - 52) / 850).clamp(1.0, 1.35).toDouble();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LedgerHeader(
                      scale: columnScale,
                      columns: const [
                        _LedgerColumn('S/N', 40),
                        _LedgerColumn('Item', 260),
                        _LedgerColumn('Net', 96),
                        _LedgerColumn('Purity', 106),
                        _LedgerColumn('Fine', 96),
                        _LedgerColumn('Rate / g', 126),
                        _LedgerColumn('Value', 126),
                      ],
                    ),
                    if (_pledgedItems.isEmpty)
                      _buildValuationEmptyState()
                    else
                      for (final item in _pledgedItems)
                        _buildValuationLedgerRow(item, columnScale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildValuationLedgerRow(_PledgedItemDraft item, double scale) {
    final description = item.descriptionCtrl.text.trim();
    final itemName =
        description.isEmpty ? 'Pledged Item ${item.serialNo}' : description;
    double w(double value) => value * scale;
    return Container(
      decoration: BoxDecoration(
        color: item.serialNo.isOdd ? Colors.white : GirviColors.inputBg,
        border: const Border(
          top: BorderSide(color: GirviColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LedgerSerialCell(serialNo: item.serialNo, width: w(40)),
          const SizedBox(width: 6),
          _LedgerItemNameCell(
            width: w(260),
            title: itemName,
            subtitle: '${item.metalType.displayName} / ${item.purityLabel}',
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(96),
            value: item.netWeight.toStringAsFixed(3),
            color: GirviColors.brandGold,
          ),
          const SizedBox(width: 6),
          _LedgerPurityReadOnlyCell(
            width: w(106),
            value: item.purityLabel,
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(96),
            value: item.fineWeight.toStringAsFixed(3),
            color: GirviColors.success,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(126),
            controller: item.rateCtrl,
            focusNode: item.rateFocus,
            hint: '0.00',
            prefixText: 'Rs ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            textAlign: TextAlign.right,
            validator: _ctrl.validateRatePerGram,
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(126),
            value: 'Rs ${_fmt.format(item.itemValue)}',
            color: GirviColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildValuationEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: const BoxDecoration(
        color: GirviColors.cardBg,
        border: Border(top: BorderSide(color: GirviColors.divider)),
      ),
      child: Text(
        'Valuation will appear after pledged item entry.',
        style: GoogleFonts.inter(
          color: GirviColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPledgedItemsTotals() {
    final summaries = _buildMetalWeightSummaries();
    return Column(
      children: [
        for (var i = 0; i < summaries.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MetalWeightSummaryPanel(summary: summaries[i]),
        ],
      ],
    );
  }

  List<_MetalWeightSummary> _buildMetalWeightSummaries() {
    return MetalType.values
        .map((metal) {
          final items =
              _pledgedItems.where((item) => item.metalType == metal).toList();
          if (items.isEmpty) return null;
          return _MetalWeightSummary(
            metal: metal,
            pieces: items.fold<int>(0, (sum, item) => sum + item.itemCount),
            gross: items.fold<double>(0, (sum, item) => sum + item.grossWeight),
            less: items.fold<double>(0, (sum, item) => sum + item.lessWeight),
            net: items.fold<double>(0, (sum, item) => sum + item.netWeight),
            fine: items.fold<double>(0, (sum, item) => sum + item.fineWeight),
          );
        })
        .whereType<_MetalWeightSummary>()
        .toList();
  }

  Widget _buildPhotoAuditStrip() {
    final attached = _pledgedItems.where((item) => item.hasPhoto).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.brandGoldLight,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_camera_outlined,
              color: GirviColors.brandGold, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Photos are optional. Attach them serial-wise from the Photo column after item entry.',
              style: GoogleFonts.inter(
                color: GirviColors.brandDeep,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$attached/${_pledgedItems.length} attached',
            style: GoogleFonts.manrope(
              color: GirviColors.brandGold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String? _validateLessWeight(_PledgedItemDraft item, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) return 'Invalid';
    if (parsed > item.grossWeight) return 'Too high';
    return null;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.045),
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
                      style: GirviStyles.caption.copyWith(fontSize: 11),
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFF3EFE7),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
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
                  fontSize: 11,
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
                itemBuilder: (context) => options
                    .map(
                      (purity) => PopupMenuItem<MetalPurity>(
                        value: purity,
                        height: 36,
                        child: Text(
                          purity.displayName,
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
                      ),
                    )
                    .toList(),
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

class _LedgerPurityReadOnlyCell extends StatelessWidget {
  const _LedgerPurityReadOnlyCell({
    required this.width,
    required this.value,
  });

  final double width;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: GirviColors.brandGoldLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GirviColors.brandGold.withValues(alpha: 0.20),
          ),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: GirviColors.brandDeep,
            fontSize: 12,
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
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GirviStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerPhotoCell extends StatelessWidget {
  const _LedgerPhotoCell({
    required this.width,
    required this.hasPhoto,
    required this.onTap,
    required this.onRemove,
  });

  final double width;
  final bool hasPhoto;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: hasPhoto
              ? GirviColors.success.withValues(alpha: 0.08)
              : GirviColors.brandGoldLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPhoto
                ? GirviColors.success.withValues(alpha: 0.24)
                : GirviColors.brandGold.withValues(alpha: 0.24),
          ),
        ),
        child: hasPhoto
            ? Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: GirviColors.success,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: GirviColors.success.withValues(alpha: 0.18),
                  ),
                  InkWell(
                    onTap: onRemove,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 38,
                      child: Icon(
                        Icons.close_rounded,
                        color: GirviColors.danger,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: const Center(
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: GirviColors.brandGold,
                    size: 18,
                  ),
                ),
              ),
      ),
    );
  }
}

class _LedgerActionCell extends StatelessWidget {
  const _LedgerActionCell({
    required this.width,
    required this.enabled,
    required this.onDelete,
  });

  final double width;
  final bool enabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap: enabled ? onDelete : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? GirviColors.dangerBg : GirviColors.inputBgLocked,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    enabled ? GirviColors.dangerBorder : GirviColors.cardBorder,
              ),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: enabled ? GirviColors.danger : GirviColors.textHint,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalWeightSummary {
  const _MetalWeightSummary({
    required this.metal,
    required this.pieces,
    required this.gross,
    required this.less,
    required this.net,
    required this.fine,
  });

  final MetalType metal;
  final int pieces;
  final double gross;
  final double less;
  final double net;
  final double fine;
}

class _MetalWeightSummaryPanel extends StatelessWidget {
  const _MetalWeightSummaryPanel({required this.summary});

  final _MetalWeightSummary summary;

  @override
  Widget build(BuildContext context) {
    final accent = _pledgedMetalAccent(summary.metal);
    final tiles = [
      _PledgedTotalTile(
        label: 'Pieces',
        value: '${summary.pieces}',
        color: GirviColors.accentCustomer,
      ),
      _PledgedTotalTile(
        label: 'Gross Weight',
        value: '${summary.gross.toStringAsFixed(3)} g',
        color: GirviColors.accentWeight,
      ),
      _PledgedTotalTile(
        label: 'Less Weight',
        value: '${summary.less.toStringAsFixed(3)} g',
        color: GirviColors.warning,
      ),
      _PledgedTotalTile(
        label: 'Net Weight',
        value: '${summary.net.toStringAsFixed(3)} g',
        color: GirviColors.brandGold,
      ),
      _PledgedTotalTile(
        label: 'Fine Weight',
        value: '${summary.fine.toStringAsFixed(3)} g',
        color: GirviColors.success,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final header = Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${summary.metal.displayName} Weight Summary',
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 10),
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  tiles[i],
                ],
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 210, child: header),
              const SizedBox(width: 10),
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PledgedTotalTile extends StatelessWidget {
  const _PledgedTotalTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GirviStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
