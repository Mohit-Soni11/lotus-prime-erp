part of '../contact_recovery_screen.dart';

class _ContactRecoveryBody extends StatelessWidget {
  final ContactRecoveryState state;
  final ValueChanged<ContactRecoveryCase> onOpenAccount;
  final ValueChanged<ContactRecoveryCase> onPrepareNotice;
  final void Function(ContactRecoveryCase item, GirviNoticeAction action)
      onViewNotice;
  final void Function(ContactRecoveryCase item, GirviNoticeAction action)
      onDownloadNotice;
  final void Function(ContactRecoveryCase item, GirviNoticeAction action)
      onPrintNotice;
  final ValueChanged<ContactRecoveryCase> onInitiateRecovery;
  final ValueChanged<ContactRecoveryCase> onCloseDisposal;

  const _ContactRecoveryBody({
    required this.state,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
    required this.onInitiateRecovery,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GirviColors.brandGold),
      );
    }
    if (state.errorMessage != null) {
      return _EmptyState(
        title: 'Unable to Load Recovery Cases',
        subtitle: state.errorMessage!,
      );
    }
    if (state.visibleCases.isEmpty) {
      return const _EmptyState(
        title: 'No Recovery Cases Found',
        subtitle:
            'There are no pledge accounts requiring contact or recovery review.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: state.visibleCases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.visibleCases[index];
        return _ContactRecoveryCard(
          item: item,
          onOpenAccount: () => onOpenAccount(item),
          onPrepareNotice:
              item.nextNoticeType == null ? null : () => onPrepareNotice(item),
          onViewNotice: (action) => onViewNotice(item, action),
          onDownloadNotice: (action) => onDownloadNotice(item, action),
          onPrintNotice: (action) => onPrintNotice(item, action),
          onInitiateRecovery: item.canInitiateCollateralRecovery
              ? () => onInitiateRecovery(item)
              : null,
          onCloseDisposal:
              item.canCloseDisposal ? () => onCloseDisposal(item) : null,
        );
      },
    );
  }
}
