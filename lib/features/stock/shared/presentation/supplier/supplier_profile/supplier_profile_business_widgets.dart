part of 'supplier_profile_screen.dart';

Widget _supplierProfileBusinessCard(
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
          SupplierProfileStrings.secBusiness,
          'Supplier type, account status and tax registration',
          SupplierProfileIcons.business,
          SupplierProfileColors.violet,
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
                  icon: SupplierProfileIcons.business,
                  label: SupplierProfileStrings.lblSupplierType,
                  value: profile.typeLabel,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.clear,
                  label: SupplierProfileStrings.lblStatus,
                  value: profile.statusLabel,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.gst,
                  label: SupplierProfileStrings.lblGst,
                  value: _valueOrNa(profile.gstNumber),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.pan,
                  label: SupplierProfileStrings.lblPan,
                  value: _valueOrNa(profile.panNumber),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
