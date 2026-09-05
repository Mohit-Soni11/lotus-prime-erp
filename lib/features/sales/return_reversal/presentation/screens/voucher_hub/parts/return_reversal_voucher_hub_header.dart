part of '../../return_reversal_voucher_preview_screen.dart';

extension _ReturnReversalVoucherHubHeader
    on _ReturnReversalVoucherPreviewScreenState {
  Widget _buildHubHeader(ReturnReversalSourceDocument sourceDocument) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SalesPosColors.shellBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: SalesPosColors.shellTextTitle,
              size: 20,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _voucherCtrl.selectedOutputDocumentLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontValue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '${sourceDocument.documentNo} | ${sourceDocument.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
