part of '../new_girvi_screen.dart';

class _PledgedItemDraft {
  _PledgedItemDraft({
    required this.serialNo,
    required this.onChanged,
  }) {
    customPurityCtrl.text = purity.shortLabel;
    for (final controller in [
      descriptionCtrl,
      piecesCtrl,
      huidCtrl,
      grossCtrl,
      lessCtrl,
      valuationPurityCtrl,
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
  final valuationPurityCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final customPurityCtrl = TextEditingController();

  final descriptionFocus = FocusNode();
  final piecesFocus = FocusNode();
  final huidFocus = FocusNode();
  final grossFocus = FocusNode();
  final lessFocus = FocusNode();
  final valuationPurityFocus = FocusNode();
  final rateFocus = FocusNode();
  final customPurityFocus = FocusNode();

  MetalType metalType = MetalType.gold;
  MetalPurity purity = MetalPurity.k22;
  final List<String> photoPaths = [];

  int get itemCount => (int.tryParse(piecesCtrl.text.trim()) ?? 1).clamp(1, 99);
  double get grossWeight => double.tryParse(grossCtrl.text) ?? 0.0;
  double get lessWeight => double.tryParse(lessCtrl.text) ?? 0.0;
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);
  double get entryPurityFactor => _entryPurityFactorFor(this);
  double get valuationPurityPercent {
    final parsed = double.tryParse(valuationPurityCtrl.text.trim());
    if (parsed == null || parsed <= 0) return 0;
    return parsed.clamp(0.0, 100.0).toDouble();
  }

  double get valuationPurityFactor => valuationPurityPercent / 100;
  bool get usesDirectSilverRate =>
      metalType == MetalType.silver && valuationPurityCtrl.text.trim().isEmpty;
  double get fineWeight =>
      usesDirectSilverRate ? netWeight : netWeight * valuationPurityFactor;
  double get ratePerGram => double.tryParse(rateCtrl.text) ?? 0.0;
  double get itemValue => fineWeight * ratePerGram;
  List<String> get validPhotoPaths => photoPaths
      .where((path) => path.isNotEmpty && File(path).existsSync())
      .toList();
  bool get hasPhoto => validPhotoPaths.isNotEmpty;
  int get photoCount => validPhotoPaths.length;

  String get purityLabel {
    final custom = customPurityCtrl.text.trim();
    if (purity == MetalPurity.other && custom.isNotEmpty) return custom;
    return purity.shortLabel;
  }

  String get valuationPurityLabel {
    if (usesDirectSilverRate) return 'Direct';
    if (valuationPurityPercent <= 0) return '-';
    return '${_formatPurityPercent(valuationPurityPercent)}%';
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
    customPurityCtrl.text = purity.shortLabel;
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
      valuationPurityCtrl,
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
      valuationPurityFocus,
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
        MetalPurity.k20,
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
        purity.shortLabel.toUpperCase() == normalized ||
        purity.legacyValues
            .any((legacy) => legacy.toUpperCase() == normalized)) {
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
            purity.shortLabel.toUpperCase() == normalized ||
            purity.legacyValues
                .any((legacy) => legacy.toUpperCase() == normalized)),
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

String _formatPurityPercent(double value) {
  final normalized = value.clamp(0.0, 100.0).toDouble();
  return _formatSmartNumber(normalized);
}

double _entryPurityFactorFor(_PledgedItemDraft item) {
  if (item.purity != MetalPurity.other) return item.purity.fineness;

  final text = item.customPurityCtrl.text.trim().toUpperCase();
  if (text.isEmpty) return 1.0;

  final numberMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
  final parsed = double.tryParse(numberMatch?.group(1) ?? '');
  if (parsed == null || parsed <= 0) return 1.0;

  if (text.contains('K')) return (parsed / 24).clamp(0.0, 1.0).toDouble();
  if (text.contains('%')) return (parsed / 100).clamp(0.0, 1.0).toDouble();
  if (parsed > 1 && parsed <= 24 && item.metalType == MetalType.gold) {
    return (parsed / 24).clamp(0.0, 1.0).toDouble();
  }
  if (parsed > 100) return (parsed / 1000).clamp(0.0, 1.0).toDouble();
  if (parsed > 1) return (parsed / 100).clamp(0.0, 1.0).toDouble();
  return parsed.clamp(0.0, 1.0).toDouble();
}

extension NewGirviPledgedItemsSection on _NewGirviScreenState {
  Widget _buildPledgedItemsSection() {
    return _LedgerSectionCard(
      icon: GirviIcons.itemDetails,
      title: 'Pledged Items Ledger',
      subtitle: 'Structured item entry for this Girvi ticket',
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
            if (_pledgedItems.any((item) => item.hasPhoto)) ...[
              const SizedBox(height: 10),
              _buildPledgedPhotoPreviewCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPledgedValuationSection() {
    return _LedgerSectionCard(
      icon: GirviIcons.valuation,
      title: 'Pledged Valuation',
      subtitle: 'Fine weight and market-rate estimate',
      accent: GirviColors.accentValuation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildValuationGrid(),
          const SizedBox(height: 12),
          _TotalItemValueHighlight(value: _ctrl.totalValue),
          if (_ctrl.totalValue > 0) ...[
            const SizedBox(height: 12),
            _LtvSuggestionRow(
              totalValue: _ctrl.totalValue,
              onSuggestionTap: (ltv) {
                _ctrl.onLtvChanged(ltv);
                _loanAmtCtrl.text = _formatSmartNumber(_ctrl.loanAmount);
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
                constraints.maxWidth < 1082 ? 1082.0 : constraints.maxWidth;
            final columnScale =
                ((tableWidth - 76) / 1006).clamp(1.0, 1.22).toDouble();
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
                        _LedgerColumn('S.No', 46),
                        _LedgerColumn('Metal', 92),
                        _LedgerColumn('Item Description', 210),
                        _LedgerColumn('Pcs', 56),
                        _LedgerColumn('HUID', 110),
                        _LedgerColumn('Purity', 102),
                        _LedgerColumn('Gross Wt.', 94),
                        _LedgerColumn('Less Wt.', 94),
                        _LedgerColumn('Net Wt.', 96),
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
          _LedgerSerialCell(serialNo: item.serialNo, width: w(46)),
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
            width: w(210),
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
            width: w(102),
            item: item,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(94),
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
            width: w(94),
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
            width: w(96),
            value: _formatLedgerWeight(item.netWeight),
            color: item.netWeight > 0
                ? GirviColors.brandGold
                : GirviColors.textMuted,
          ),
          const SizedBox(width: 6),
          _LedgerPhotoCell(
            width: w(54),
            hasPhoto: item.hasPhoto,
            photoCount: item.photoCount,
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
                constraints.maxWidth < 916 ? 916.0 : constraints.maxWidth;
            final columnScale =
                ((tableWidth - 60) / 856).clamp(1.0, 1.35).toDouble();
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
                        _LedgerColumn('S.No', 46),
                        _LedgerColumn('Item', 260),
                        _LedgerColumn('Net Wt.', 96),
                        _LedgerColumn('Val. Purity', 106),
                        _LedgerColumn('Fine Wt.', 96),
                        _LedgerColumn('Rate / g', 126),
                        _LedgerColumn('Pledged Value', 126),
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
          _LedgerSerialCell(serialNo: item.serialNo, width: w(46)),
          const SizedBox(width: 6),
          _LedgerItemNameCell(
            width: w(260),
            title: itemName,
            subtitle: '${item.metalType.displayName} / ${item.purityLabel}',
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(96),
            value: _formatLedgerWeight(item.netWeight),
            color: item.netWeight > 0
                ? GirviColors.brandGold
                : GirviColors.textMuted,
          ),
          const SizedBox(width: 6),
          _LedgerTextCell(
            width: w(106),
            controller: item.valuationPurityCtrl,
            focusNode: item.valuationPurityFocus,
            hint: '',
            suffixText: '%',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            textAlign: TextAlign.right,
            validator: (value) => _validateValuationPurity(item, value),
          ),
          const SizedBox(width: 6),
          _LedgerReadOnlyCell(
            width: w(96),
            value: _formatLedgerWeight(item.fineWeight),
            color: item.fineWeight > 0
                ? GirviColors.success
                : GirviColors.textMuted,
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
            value: _formatLedgerAmount(item.itemValue),
            color: item.itemValue > 0
                ? GirviColors.success
                : GirviColors.textMuted,
          ),
        ],
      ),
    );
  }

  String _formatLedgerWeight(double value) {
    if (value <= 0) return '-';
    return _formatSmartWeight(value);
  }

  String _formatLedgerAmount(double value) {
    if (value <= 0) return '-';
    return _formatSmartMoney(value);
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
    final totalPieces =
        _pledgedItems.fold<int>(0, (sum, item) => sum + item.itemCount);
    return _PledgedLedgerBottomBar(
      totalItems: _pledgedItems.length,
      totalPieces: totalPieces,
      summaries: summaries,
      onAdd: _addPledgedItem,
    );
  }

  List<_MetalWeightSummary> _buildMetalWeightSummaries() {
    return MetalType.values
        .map((metal) {
          final items =
              _pledgedItems.where((item) => item.metalType == metal).toList();
          if (items.isEmpty) return null;
          final gross =
              items.fold<double>(0, (sum, item) => sum + item.grossWeight);
          final less =
              items.fold<double>(0, (sum, item) => sum + item.lessWeight);
          final net =
              items.fold<double>(0, (sum, item) => sum + item.netWeight);
          if (gross <= 0 && less <= 0 && net <= 0) return null;
          return _MetalWeightSummary(
            metal: metal,
            pieces: items.fold<int>(0, (sum, item) => sum + item.itemCount),
            gross: gross,
            less: less,
            net: net,
          );
        })
        .whereType<_MetalWeightSummary>()
        .toList();
  }

  Widget _buildPhotoAuditStrip() {
    final attached =
        _pledgedItems.fold<int>(0, (sum, item) => sum + item.photoCount);
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
              'Photos are optional. Attach one or more photos from the Photo column after item entry.',
              style: GoogleFonts.inter(
                color: GirviColors.brandDeep,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$attached attached',
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

  Widget _buildPledgedPhotoPreviewCard() {
    final entries = <({int serialNo, String title, String path})>[];
    for (final item in _pledgedItems) {
      final description = item.descriptionCtrl.text.trim();
      final title =
          description.isEmpty ? 'Pledged Item ${item.serialNo}' : description;
      for (final path in item.validPhotoPaths) {
        entries.add((serialNo: item.serialNo, title: title, path: path));
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: GirviColors.brandGoldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: GirviColors.brandGold,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pledged Item Photo Preview',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${entries.length} photos',
                style: GoogleFonts.manrope(
                  color: GirviColors.brandGold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: entries.map((entry) {
              final item = _pledgedItems.firstWhere(
                (draft) => draft.serialNo == entry.serialNo,
              );
              return _PledgedPhotoThumbnail(
                serialNo: entry.serialNo,
                title: entry.title,
                path: entry.path,
                onPreview: () => _showPledgedItemPhotoPreview(item, entry.path),
                onRemove: () => _removePledgedItemPhotoPath(item, entry.path),
              );
            }).toList(),
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

  String? _validateValuationPurity(_PledgedItemDraft item, String? value) {
    if (item.metalType == MetalType.silver &&
        (value == null || value.trim().isEmpty)) {
      return null;
    }
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Required';
    if (parsed > 100) return 'Max 100';
    return null;
  }
}
