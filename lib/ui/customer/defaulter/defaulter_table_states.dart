part of 'defaulter_data_table.dart';

class _ShimmerRows extends StatelessWidget {
  const _ShimmerRows();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 134,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: DefaulterColors.riskLowBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              DefaulterIcons.emptyState,
              size: 38,
              color: DefaulterColors.riskLowText,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            DefaulterStrings.emptyTitle,
            style: DefaulterStyles.emptyTitle,
          ),
          const SizedBox(height: 8),
          const Text(
            DefaulterStrings.emptySubtitle,
            style: DefaulterStyles.emptySubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: DefaulterColors.riskCriticalText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: DefaulterStyles.emptyTitle.copyWith(
              color: DefaulterColors.riskCriticalText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
