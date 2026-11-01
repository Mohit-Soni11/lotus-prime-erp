import 'package:flutter/material.dart';

import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';

class DueCollectionEmptyState extends StatelessWidget {
  const DueCollectionEmptyState(
      {super.key, required this.isLoading, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final failed = errorMessage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: DueCollectionEntryStyles.panel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: failed
                  ? DueCollectionEntryColors.dangerBg
                  : DueCollectionEntryColors.successBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : DueCollectionEntryIcons.empty,
                    color: failed
                        ? DueCollectionEntryColors.danger
                        : const Color(0xFF008D70),
                    size: 32,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            isLoading
                ? 'Loading due bills'
                : failed
                    ? 'Due bills unavailable'
                    : 'All due bills are clear',
            style: DueCollectionEntryStyles.sectionTitle.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            isLoading
                ? 'Your collection desk is getting ready.'
                : failed
                    ? errorMessage!
                    : 'New outstanding sales bills will appear here automatically.',
            style: DueCollectionEntryStyles.label.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
