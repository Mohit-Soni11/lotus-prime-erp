part of '../new_girvi_screen.dart';

class _PledgedItemDraft {
  _PledgedItemDraft({
    required this.serialNo,
    required this.onChanged,
  }) {
    for (final controller in [
      descriptionCtrl,
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
  final huidCtrl = TextEditingController();
  final grossCtrl = TextEditingController();
  final lessCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final customPurityCtrl = TextEditingController();

  final descriptionFocus = FocusNode();
  final huidFocus = FocusNode();
  final grossFocus = FocusNode();
  final lessFocus = FocusNode();
  final rateFocus = FocusNode();
  final customPurityFocus = FocusNode();

  MetalType metalType = MetalType.gold;
  MetalPurity purity = MetalPurity.k22;
  int itemCount = 1;
  String? photoPath;

  double get grossWeight => double.tryParse(grossCtrl.text) ?? 0.0;
  double get lessWeight => double.tryParse(lessCtrl.text) ?? 0.0;
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);
  double get ratePerGram => double.tryParse(rateCtrl.text) ?? 0.0;
  double get itemValue => netWeight * ratePerGram;
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
    _notifyChanged();
  }

  void setPurity(MetalPurity value) {
    purity = value;
    _notifyChanged();
  }

  void setItemCount(int value) {
    itemCount = value.clamp(1, 99);
    _notifyChanged();
  }

  void _notifyChanged() => onChanged();

  void dispose() {
    for (final controller in [
      descriptionCtrl,
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

extension NewGirviPledgedItemsSection on _NewGirviScreenState {
  Widget _buildPledgedItemsSection() {
    return GirviSectionCard(
      icon: GirviIcons.itemDetails,
      title: 'Pledged Items',
      subtitle: 'Photos, metal details, hallmark and weights',
      accent: GirviColors.accentItem,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPledgedItemsToolbar(),
          const SizedBox(height: 12),
          for (final item in _pledgedItems) ...[
            _buildPledgedItemPanel(item),
            if (item != _pledgedItems.last) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          _buildPledgedItemsTotals(),
        ],
      ),
    );
  }

  Widget _buildPledgedValuationSection() {
    return GirviSectionCard(
      icon: GirviIcons.valuation,
      title: 'Valuation',
      subtitle: 'Market rate and item-wise value calculation',
      accent: GirviColors.accentValuation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in _pledgedItems) ...[
            _buildValuationLine(item),
            if (item != _pledgedItems.last) const SizedBox(height: 10),
          ],
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

  Widget _buildValuationLine(_PledgedItemDraft item) {
    final description = item.descriptionCtrl.text.trim();
    final itemName =
        description.isEmpty ? 'Pledged Item ${item.serialNo}' : description;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final header = Row(
            children: [
              _PledgedSerialBadge(serialNo: item.serialNo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.metalType.displayName} / ${item.purityLabel} • Net ${item.netWeight.toStringAsFixed(3)} g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GirviStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );

          final rateField = GirviInputField(
            label: 'Market Rate (Rs / gram) *',
            hint: '0.00',
            icon: GirviIcons.valuation,
            controller: item.rateCtrl,
            focusNode: item.rateFocus,
            nextFocus: _loanAmtFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            prefixText: 'Rs ',
            validator: _ctrl.validateRatePerGram,
          );

          final valueField = GirviReadOnlyField(
            label: 'Item Valuation',
            value: 'Rs ${_fmt.format(item.itemValue)}',
            highlighted: item.itemValue > 0,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 12),
                rateField,
                const SizedBox(height: 12),
                valueField,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: header),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: rateField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: valueField),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPledgedItemsToolbar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_pledgedItems.length} pledged item'
            '${_pledgedItems.length == 1 ? '' : 's'} added',
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _PledgedAddButton(onTap: _addPledgedItem),
      ],
    );
  }

  Widget _buildPledgedItemPanel(_PledgedItemDraft item) {
    final canRemove = _pledgedItems.length > 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PledgedSerialBadge(serialNo: item.serialNo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pledged Item ${item.serialNo}',
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PledgedMiniStat(
                label: 'Net',
                value: '${item.netWeight.toStringAsFixed(3)} g',
                color: GirviColors.brandGold,
              ),
              if (canRemove) ...[
                const SizedBox(width: 8),
                _PledgedIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove item',
                  onTap: () => _removePledgedItem(item),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildPledgedItemPhotoPicker(item),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 680;
              return _buildPledgedItemFields(item, twoColumn: twoColumn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPledgedItemPhotoPicker(_PledgedItemDraft item) {
    final path = item.photoPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();
    final file = hasPhoto ? File(path) : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final preview = Container(
            width: compact ? 68 : 76,
            height: compact ? 58 : 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: GirviColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: hasPhoto
                    ? GirviColors.brandGold.withValues(alpha: 0.35)
                    : GirviColors.cardBorder,
              ),
            ),
            child: hasPhoto && file != null
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: GirviColors.textHint,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: GirviColors.brandGold,
                    size: 24,
                  ),
          );

          final details = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? 'Item photo attached' : 'Attach item photo',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasPhoto ? path : 'Use a clear photo for this pledged item.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PhotoActionButton(
                icon: hasPhoto ? Icons.sync_rounded : Icons.upload_rounded,
                label: hasPhoto ? 'Change' : 'Upload',
                filled: true,
                onTap: () => _pickPledgedItemPhoto(item),
              ),
              if (hasPhoto)
                _PhotoActionButton(
                  icon: Icons.close_rounded,
                  label: 'Remove',
                  filled: false,
                  onTap: () => _removePledgedItemPhoto(item),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [preview, const SizedBox(width: 10), details]),
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            children: [
              preview,
              const SizedBox(width: 12),
              details,
              const SizedBox(width: 10),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPledgedItemFields(
    _PledgedItemDraft item, {
    required bool twoColumn,
  }) {
    final widgets = [
      GirviDropdown<MetalType>(
        label: 'Metal Type *',
        icon: GirviIcons.gold,
        value: item.metalType,
        items: MetalType.values
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) item.setMetalType(v);
        },
      ),
      GirviInputField(
        label: 'Item Description *',
        hint: 'e.g. Necklace, bangle, ring',
        icon: GirviIcons.itemDetails,
        controller: item.descriptionCtrl,
        focusNode: item.descriptionFocus,
        nextFocus: item.huidFocus,
        validator: _ctrl.validateItemDescription,
      ),
      GirviInputField(
        label: 'HUID / Hallmark Number',
        hint: 'Certificate, tag or HUID number',
        icon: Icons.verified_outlined,
        controller: item.huidCtrl,
        focusNode: item.huidFocus,
        nextFocus: item.grossFocus,
        keyboardType: TextInputType.text,
      ),
      GirviDropdown<MetalPurity>(
        label: 'Metal Purity *',
        icon: GirviIcons.valuation,
        value: item.purity,
        items: _purityOptionsForMetal(item.metalType)
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) item.setPurity(v);
        },
      ),
      if (item.purity == MetalPurity.other)
        GirviInputField(
          label: 'Custom Purity',
          hint: 'e.g. 20K, 95% silver, platinum 950',
          icon: Icons.edit_note_rounded,
          controller: item.customPurityCtrl,
          focusNode: item.customPurityFocus,
          nextFocus: item.grossFocus,
          keyboardType: TextInputType.text,
          validator: (value) {
            if (item.purity != MetalPurity.other) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Enter custom purity';
            }
            return null;
          },
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item Count *', style: GirviStyles.fieldLabel),
          const SizedBox(height: 6),
          _ItemCountStepper(
            count: item.itemCount,
            onChanged: item.setItemCount,
          ),
        ],
      ),
      GirviInputField(
        label: 'Gross Weight (g) *',
        hint: '0.00',
        icon: GirviIcons.weight,
        controller: item.grossCtrl,
        focusNode: item.grossFocus,
        nextFocus: item.lessFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        suffixText: 'g',
        validator: _ctrl.validateGrossWeight,
      ),
      GirviInputField(
        label: 'Less / Stone Weight (g)',
        hint: '0.00',
        icon: Icons.scatter_plot_outlined,
        controller: item.lessCtrl,
        focusNode: item.lessFocus,
        nextFocus: item.rateFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        suffixText: 'g',
        validator: (value) => _validateLessWeight(item, value),
      ),
      GirviReadOnlyField(
        label: 'Net Metal Weight',
        value: '${item.netWeight.toStringAsFixed(3)} grams',
        highlighted: true,
        valueColor:
            item.netWeight > 0 ? GirviColors.brandGold : GirviColors.textMuted,
      ),
    ];

    if (!twoColumn) {
      return Column(
        children: [
          for (var i = 0; i < widgets.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            widgets[i],
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < widgets.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          GirviRowTwo(
            left: widgets[i],
            right: i + 1 < widgets.length ? widgets[i + 1] : const SizedBox(),
          ),
        ],
      ],
    );
  }

  Widget _buildPledgedItemsTotals() {
    final totalPieces =
        _pledgedItems.fold<int>(0, (sum, item) => sum + item.itemCount);
    final totalGross =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.grossWeight);
    final totalLess =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.lessWeight);
    final totalNet =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.netWeight);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.shellPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final tiles = [
            _PledgedTotalTile(
              label: 'Pieces',
              value: '$totalPieces',
              color: GirviColors.accentCustomer,
            ),
            _PledgedTotalTile(
              label: 'Gross Weight',
              value: '${totalGross.toStringAsFixed(3)} g',
              color: GirviColors.accentWeight,
            ),
            _PledgedTotalTile(
              label: 'Less Weight',
              value: '${totalLess.toStringAsFixed(3)} g',
              color: GirviColors.warning,
            ),
            _PledgedTotalTile(
              label: 'Net Weight',
              value: '${totalNet.toStringAsFixed(3)} g',
              color: GirviColors.brandGold,
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  tiles[i],
                ],
              ],
            );
          }

          return Row(
            children: [
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

  String? _validateLessWeight(_PledgedItemDraft item, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) return 'Enter valid weight';
    if (parsed > item.grossWeight) {
      return 'Less weight cannot exceed gross weight';
    }
    return null;
  }
}

class _PledgedAddButton extends StatelessWidget {
  const _PledgedAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GirviColors.brandGold,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: GirviColors.brandGold.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: GirviColors.shellBg, size: 17),
            const SizedBox(width: 6),
            Text(
              'Add Pledged Item',
              style: GoogleFonts.inter(
                color: GirviColors.shellBg,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PledgedSerialBadge extends StatelessWidget {
  const _PledgedSerialBadge({required this.serialNo});

  final int serialNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GirviColors.brandGoldLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GirviColors.brandGold.withValues(alpha: 0.3)),
      ),
      child: Text(
        '#$serialNo',
        style: GoogleFonts.manrope(
          color: GirviColors.brandDeep,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PledgedMiniStat extends StatelessWidget {
  const _PledgedMiniStat({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PledgedIconButton extends StatelessWidget {
  const _PledgedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.dangerBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.dangerBorder),
          ),
          child: Icon(icon, color: GirviColors.danger, size: 17),
        ),
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            style: GirviStyles.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
