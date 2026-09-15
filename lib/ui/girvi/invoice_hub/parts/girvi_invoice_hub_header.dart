part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubHeader on _GirviInvoiceHubScreenState {
  Widget _buildHubHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 22, 18, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GirviColors.shellBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Girvi',
            onPressed: _closeHub,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: GirviColors.shellTextTitle,
              size: 19,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GIRVI INVOICE HUB',
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Review, export and finalize',
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: GirviColors.shellBg,
      child: Row(
        children: [
          IconButton(
            onPressed: _closeHub,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: GirviColors.shellTextTitle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'GIRVI INVOICE HUB',
            style: GoogleFonts.inter(
              color: GirviColors.shellTextTitle,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
