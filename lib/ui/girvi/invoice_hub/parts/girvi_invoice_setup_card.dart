part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceSetupCard on _GirviInvoiceHubScreenState {
  Widget _buildInvoiceSetupCard() {
    final metals = _controller.presentMetals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('INVOICE DISPLAY'),
        const SizedBox(height: 10),
        if (metals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GirviColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GirviColors.shellBorder),
            ),
            child: Text(
              'Add pledged items to load metal-specific invoice settings.',
              style: GoogleFonts.inter(
                color: GirviColors.shellTextMuted,
                fontSize: 12.5,
              ),
            ),
          )
        else ...[
          _buildGirviInvoiceDisplayCard(metals),
        ],
        const SizedBox(height: 12),
        _buildShopPrintSetupCard(),
      ],
    );
  }

  Widget _buildGirviInvoiceDisplayCard(List<String> metals) {
    const color = GirviColors.brandGold;
    final metalNames = metals.map(GirviBillingMetal.displayName).join(', ');
    final activeItemFields = _girviInvoiceFieldOptions
        .where(
          (option) => _controller.getCombinedCustomizationValue(option.key),
        )
        .length;
    final visibleReceiptFields =
        _controller.invoiceSettings.visibleDocumentFieldCount;

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.05),
          GirviColors.shellPanelBg,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_outlined,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Girvi Invoice Display',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Item table, loan sections, KYC, terms and footer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _setupStatusPill('SAVED SETUP', color),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _setupMetricPill(
                      Icons.inventory_2_outlined,
                      '$activeItemFields/${_girviInvoiceFieldOptions.length} Item Fields',
                      color,
                    ),
                    _setupMetricPill(
                      Icons.receipt_long_outlined,
                      '$visibleReceiptFields/${_girviInvoiceDocumentOptions.length} Receipt Sections',
                      const Color(0xFF2DD4BF),
                    ),
                    _setupMetricPill(
                      Icons.category_rounded,
                      metalNames,
                      GirviColors.shellTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.dashboard_customize_outlined,
            title: 'Configure Display',
            subtitle: 'Edit item fields, loan sections, KYC, terms and footer',
            action: 'Edit',
            color: color,
            onPressed: _showGirviInvoiceDisplaySelector,
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Reload Saved Girvi Display',
            subtitle: 'Reload saved Girvi billing and receipt setup',
            action: 'Apply',
            color: color,
            onPressed: () async {
              await _controller.restoreCombinedSavedSetup();
              await _controller.restoreDocumentSavedSetup();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShopPrintSetupCard() {
    final state = _controller.shopPrintInformationState;
    const color = GirviColors.success;

    if (state == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.05),
            GirviColors.shellPanelBg,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading business print profile...',
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.05),
          GirviColors.shellPanelBg,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Print Profile',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Business details printed on this Girvi invoice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _setupMetricPill(
                      Icons.toggle_on_rounded,
                      '${state.enabledCount}/${state.configuredCount} Enabled',
                      color,
                    ),
                    _setupMetricPill(
                      Icons.inventory_2_rounded,
                      '${state.missingCount} Missing',
                      state.missingCount == 0 ? color : GirviColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.dashboard_customize_outlined,
            title: 'Configure Business Info',
            subtitle: '${state.enabledCount} fields visible in invoice header',
            action: 'Edit',
            color: color,
            onPressed: _showShopPrintProfileEditor,
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Reload Saved Business Setup',
            subtitle: 'Use saved shop information on this preview',
            action: 'Apply',
            color: color,
            onPressed: _controller.restoreShopPrintInformationSetup,
          ),
        ],
      ),
    );
  }

  Widget _setupMetricPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required Color color,
    required VoidCallback onPressed,
  }) {
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.55)),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showGirviInvoiceDisplaySelector() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Girvi invoice display setup',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _GirviInvoiceDisplayDrawer(
              controller: _controller,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _showShopPrintProfileEditor() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close business print profile editor',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _GirviShopPrintProfileDrawer(
              controller: _controller,
              accentColor: GirviColors.success,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
