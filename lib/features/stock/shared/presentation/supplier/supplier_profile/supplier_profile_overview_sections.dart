part of 'supplier_profile_screen.dart';

extension _SupplierProfileOverviewSections on _SupplierProfileScreenState {
  Widget _buildHeroCard(SupplierProfileModel profile) {
    final typeColor = _typeColor(profile.supplierType);
    return Container(
      decoration: SupplierProfileStyles.cardDecoration,
      padding: SupplierProfileStyles.cardPadding,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        final identity = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: SupplierProfileStyles.avatarSize,
              height: SupplierProfileStyles.avatarSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SupplierProfileColors.brandGoldBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: SupplierProfileColors.brandGold.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Text(
                profile.avatarInitials,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: SupplierProfileColors.brandGold,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.businessName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SupplierProfileStyles.supplierName,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _softChip(profile.typeLabel, typeColor),
                      _softChip(
                          profile.statusLabel, SupplierProfileColors.info),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
        final contact = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroDetail(SupplierProfileIcons.phone, 'Mobile', profile.mobile),
            const SizedBox(height: 10),
            _heroDetail(
                SupplierProfileIcons.location, 'Address', profile.addressLine),
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 16), contact],
              )
            : Row(children: [
                Expanded(child: identity),
                const SizedBox(width: 24),
                SizedBox(
                  width: constraints.maxWidth > 1280 ? 500 : 380,
                  child: contact,
                ),
              ]);
      }),
    );
  }

  Widget _heroDetail(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 17, color: SupplierProfileColors.brandGold),
          const SizedBox(width: 8),
          Text('$label: ', style: SupplierProfileStyles.supplierMeta),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SupplierProfileStyles.supplierMeta),
          ),
        ],
      );

  Widget _buildActionButtons(SupplierProfileModel profile) {
    final actions = [
      _ActionButton(
        icon: SupplierProfileIcons.addStock,
        label: SupplierProfileStrings.btnAddStock,
        bg: SupplierProfileColors.brandGold,
        fg: Colors.black,
        border: SupplierProfileColors.brandGold,
        filled: true,
        onTap: widget.onNewStock ?? _handleBack,
      ),
      _ActionButton(
        icon: SupplierProfileIcons.edit,
        label: SupplierProfileStrings.btnEdit,
        bg: SupplierProfileColors.infoBg,
        fg: SupplierProfileColors.info,
        border: SupplierProfileColors.info.withValues(alpha: 0.35),
        onTap: () => _showEditDialog(profile),
      ),
      _ActionButton(
        icon: SupplierProfileIcons.deactivate,
        label: SupplierProfileStrings.btnDeactivate,
        bg: SupplierProfileColors.dangerBg,
        fg: SupplierProfileColors.danger,
        border: SupplierProfileColors.danger.withValues(alpha: 0.35),
        onTap: () => _showDeactivateDialog(profile),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final action in actions) SizedBox(width: width, child: action)
        ]);
      },
    );
  }

  Widget _buildStatsOverview(SupplierProfileModel profile) {
    return _supplierProfileStatsOverview(profile);
  }

  Widget _buildContactCard(SupplierProfileModel profile) {
    return _supplierProfileContactCard(
      profile,
      sectionHeader: _sectionHeader,
    );
  }

  Widget _buildBusinessCard(SupplierProfileModel profile) {
    return _supplierProfileBusinessCard(
      profile,
      sectionHeader: _sectionHeader,
    );
  }
}
