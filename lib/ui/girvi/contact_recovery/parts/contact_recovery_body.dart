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
  final void Function(ContactRecoveryCase item, GirviNoticeAction action)
      onConfirmDelivery;
  final ValueChanged<ContactRecoveryCase> onSettlement;
  final void Function(ContactRecoveryCase item, GirviNoticeAction action)
      onRecordCustomerResponse;
  final ValueChanged<ContactRecoveryCase> onViewCustomerResponses;
  final ValueChanged<ContactRecoveryCase> onViewInvoice;
  final ValueChanged<ContactRecoveryCase> onDownloadInvoice;
  final ValueChanged<ContactRecoveryCase> onViewItemImage;
  final ValueChanged<ContactRecoveryCase> onDownloadItemImage;
  final ValueChanged<ContactRecoveryCase> onCompleteRecovery;

  const _ContactRecoveryBody({
    required this.state,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
    required this.onConfirmDelivery,
    required this.onSettlement,
    required this.onRecordCustomerResponse,
    required this.onViewCustomerResponses,
    required this.onViewInvoice,
    required this.onDownloadInvoice,
    required this.onViewItemImage,
    required this.onDownloadItemImage,
    required this.onCompleteRecovery,
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
    if (state.allCases.isEmpty) {
      return const _EmptyState(
        title: 'Invoice unavailable for notice',
        subtitle:
            'This invoice was not found or is no longer eligible for notice and recovery.',
      );
    }

    final item = state.allCases.single;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: _ContactRecoveryCard(
        item: item,
        onOpenAccount: () => onOpenAccount(item),
        onPrepareNotice: item.nextNoticeType == null || !item.canPrepareNotice
            ? null
            : () => onPrepareNotice(item),
        onViewNotice: (action) => onViewNotice(item, action),
        onDownloadNotice: (action) => onDownloadNotice(item, action),
        onPrintNotice: (action) => onPrintNotice(item, action),
        onConfirmDelivery: (action) => onConfirmDelivery(item, action),
        onSettlement: () => onSettlement(item),
        onRecordCustomerResponse: (action) =>
            onRecordCustomerResponse(item, action),
        onViewCustomerResponses: () => onViewCustomerResponses(item),
        onViewInvoice: () => onViewInvoice(item),
        onDownloadInvoice: () => onDownloadInvoice(item),
        onViewItemImage: () => onViewItemImage(item),
        onDownloadItemImage: () => onDownloadItemImage(item),
        onCompleteRecovery:
            item.canInitiateCollateralRecovery || item.canCloseDisposal
                ? () => onCompleteRecovery(item)
                : null,
      ),
    );
  }
}
