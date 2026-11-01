import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/cash_book/cash_transaction_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import 'cash_book_error_state.dart';

part 'cash_book_transaction_filters.dart';
part 'cash_book_transaction_rows.dart';
part 'cash_book_transaction_detail.dart';
part 'cash_book_transaction_states.dart';

class CashBookTransactionList extends StatelessWidget {
  final CashBookController ctrl;
  final VoidCallback onAddEntry;

  const CashBookTransactionList({
    super.key,
    required this.ctrl,
    required this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ Top control bar: search + filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _TopBar(ctrl: ctrl),

        // â”€â”€ List body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: ctrl.isLoading
              ? _LoadingShimmer()
              : ctrl.errorMessage != null
                  ? CashBookErrorState(
                      message: ctrl.errorMessage!,
                      onRetry: ctrl.retry,
                    )
                  : ctrl.groups.isEmpty
                      ? _EmptyState(
                          onAddEntry: onAddEntry,
                          filtered: ctrl.searchCtrl.text.trim().isNotEmpty ||
                              ctrl.filter != CashBookFilter.all,
                          onClear: () {
                            ctrl.searchCtrl.clear();
                            ctrl.setFilter(CashBookFilter.all);
                          },
                        )
                      : _GroupedList(ctrl: ctrl),
        ),
      ],
    );
  }
}

// â”€â”€ Top Bar: Search + Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
