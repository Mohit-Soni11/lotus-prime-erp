import 'package:flutter/material.dart';

import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_controls.dart';
import 'customer_list_number_format.dart';

class CustomerListResultHeader extends StatelessWidget {
  const CustomerListResultHeader({
    super.key,
    required this.visibleCount,
    required this.filter,
    required this.sort,
    required this.searchQuery,
  });

  final int visibleCount;
  final CustomerFilter filter;
  final CustomerSort sort;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final count = CustomerListNumberFormat.count(visibleCount);
    final details = [
      '$count ${visibleCount == 1 ? 'customer' : 'customers'}',
      if (filter != CustomerFilter.all) filter.label,
      sort.label,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CustomerListStrings.profilesHeading,
                  style: CustomerListStyles.resultTitle,
                ),
                const SizedBox(height: 3),
                Text(details, style: CustomerListStyles.resultMeta),
              ],
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(width: 12),
            CustomerListResultPill(
              icon: CustomerListIcons.search,
              label: searchQuery,
            ),
          ],
        ],
      ),
    );
  }
}
