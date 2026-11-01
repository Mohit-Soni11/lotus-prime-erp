import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';

class SupplierListCard extends StatelessWidget {
  const SupplierListCard({
    super.key,
    required this.supplier,
    required this.onTap,
  });

  final SupplierListItemModel supplier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SupplierListColors.bodyBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final avatar = Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SupplierListColors.brandGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SupplierListColors.brandGold),
                ),
                child: Text(
                  supplier.avatarInitial,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              );
              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.businessName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(spacing: 16, runSpacing: 9, children: [
                    _typeBadge(),
                    _detail(Icons.phone_rounded, 'Mobile', supplier.mobile),
                    if (supplier.contactPersonName?.trim().isNotEmpty == true)
                      _detail(Icons.person_rounded, 'Contact Person',
                          supplier.contactPersonName!.trim()),
                    if (supplier.gstNumber?.trim().isNotEmpty == true)
                      _detail(Icons.receipt_long_rounded, 'GST',
                          supplier.gstNumber!.trim()),
                  ]),
                ],
              );
              final open = OutlinedButton.icon(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: SupplierListColors.brandGold),
                  backgroundColor:
                      SupplierListColors.brandGold.withValues(alpha: 0.12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Open Profile',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              );
              if (compact) {
                return Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: information),
                  ]),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: open),
                ]);
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 16),
                    Expanded(child: information),
                    const SizedBox(width: 16),
                    open,
                  ]);
            }),
          ),
        ),
      );

  Widget _typeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: SupplierListColors.brandGold.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          supplier.supplierType.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      );

  Widget _detail(IconData icon, String label, String value) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: SupplierListColors.brandGold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ]),
      );
}
