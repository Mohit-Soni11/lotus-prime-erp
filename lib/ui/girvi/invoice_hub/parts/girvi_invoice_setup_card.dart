part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceSetupCard on _GirviInvoiceHubScreenState {
  Widget _buildInvoiceSetupCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('CUSTOMER PRINT FORMAT'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: GirviColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GirviColors.brandGold.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: GirviColors.brandGoldLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: GirviColors.brandGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fixed Girvi Customer Copy',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Customer-safe format linked with Girvi billing',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _setupStatusPill('LOCKED'),
                  ],
                ),
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _fixedFormatRow(
                icon: Icons.view_column_outlined,
                title: '9 Fixed Item Columns',
                subtitle:
                    'S/N, Metal, Item, Pcs, HUID, Purity, Gross, Less and Net',
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _fixedFormatRow(
                icon: Icons.percent_rounded,
                title: 'Loan Details',
                subtitle: 'Loan amount and monthly interest percentage only',
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _fixedFormatRow(
                icon: Icons.photo_camera_outlined,
                title: 'Item Photos Included',
                subtitle: 'Attached pledged-item photos print automatically',
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _fixedFormatRow(
                icon: Icons.visibility_off_outlined,
                title: 'Internal Valuation Hidden',
                subtitle:
                    'Valuation purity, fine weight, rate and value stay private',
                protected: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fixedFormatRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool protected = false,
  }) {
    final color = protected ? GirviColors.success : GirviColors.brandGold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextTitle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            protected ? Icons.shield_outlined : Icons.check_circle_rounded,
            color: color,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _setupStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.brandGoldLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: GirviColors.brandGold,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
