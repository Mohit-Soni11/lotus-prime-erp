part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubHeader on _PosInvoicePreviewScreenState {
  Widget _buildHubHeader() {
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
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVOICE WORKSPACE',
                  style: TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontValue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Review, Print & Close',
                  style: TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
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
