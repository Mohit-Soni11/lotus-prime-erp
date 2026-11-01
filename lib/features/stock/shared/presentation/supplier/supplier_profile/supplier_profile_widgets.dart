part of 'supplier_profile_screen.dart';

typedef _SupplierProfileSectionHeader = Widget Function(
  String title,
  String subtitle,
  IconData icon,
  Color color,
);

Widget _supplierProfileStatsOverview(SupplierProfileModel profile) {
  final cards = [
    _StatBox(
        icon: SupplierProfileIcons.inventory,
        label: 'Total Batches',
        value: profile.totalBatchCount.toString(),
        color: SupplierProfileColors.brandGold),
    _StatBox(
        icon: SupplierProfileIcons.clear,
        label: 'Active Batches',
        value: profile.activeBatchCount.toString(),
        color: SupplierProfileColors.success),
  ];
  return LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final columns = constraints.maxWidth >= 580 ? 2 : 1;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final card in cards) SizedBox(width: width, child: card)
      ]);
    },
  );
}

Widget _supplierProfileContactCard(
  SupplierProfileModel profile, {
  required _SupplierProfileSectionHeader sectionHeader,
}) {
  return Container(
    decoration: SupplierProfileStyles.cardDecoration,
    padding: SupplierProfileStyles.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          SupplierProfileStrings.secContact,
          'Active phone, WhatsApp and contact person',
          SupplierProfileIcons.contact,
          SupplierProfileColors.info,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth > 760;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.phone,
                  label: SupplierProfileStrings.lblMobile,
                  value: profile.mobile,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.whatsapp,
                  label: SupplierProfileStrings.lblWhatsapp,
                  value: _valueOrNa(profile.whatsapp),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.email,
                  label: SupplierProfileStrings.lblEmail,
                  value: _valueOrNa(profile.email),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.contact,
                  label: SupplierProfileStrings.lblContactPerson,
                  value: _valueOrNa(profile.contactPersonName),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
