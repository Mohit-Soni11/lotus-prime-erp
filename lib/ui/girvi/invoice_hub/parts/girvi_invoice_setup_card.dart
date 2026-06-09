part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceSetupCard on _GirviInvoiceHubScreenState {
  static const _fieldOptions = <_GirviInvoiceFieldOption>[
    _GirviInvoiceFieldOption(
      key: 'metal',
      title: 'Metal',
      subtitle: 'Gold, silver or other metal',
      icon: Icons.category_outlined,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'pieces',
      title: 'Pieces',
      subtitle: 'Pledged item quantity',
      icon: Icons.numbers_rounded,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'huid',
      title: 'HUID',
      subtitle: 'Hallmark identification number',
      icon: Icons.fingerprint_rounded,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'purity',
      title: 'Entered Purity',
      subtitle: 'Purity recorded at item entry',
      icon: Icons.diamond_outlined,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'gross',
      title: 'Gross Weight',
      subtitle: 'Total item weight',
      icon: Icons.scale_outlined,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'less',
      title: 'Less Weight',
      subtitle: 'Stone and non-metal deduction',
      icon: Icons.remove_circle_outline_rounded,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'net',
      title: 'Net Weight',
      subtitle: 'Gross minus deductions',
      icon: Icons.balance_outlined,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'valuationPurity',
      title: 'Valuation Purity',
      subtitle: 'Purity used for loan valuation',
      icon: Icons.verified_outlined,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'fine',
      title: 'Fine Weight',
      subtitle: 'Purity-adjusted metal weight',
      icon: Icons.monitor_weight_outlined,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'rate',
      title: 'Rate / Gram',
      subtitle: 'Valuation rate used',
      icon: Icons.trending_up_rounded,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'value',
      title: 'Item Value',
      subtitle: 'Calculated pledged item value',
      icon: Icons.payments_outlined,
      group: 'Weight & Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'photos',
      title: 'Item Photos',
      subtitle: 'Print attached pledged item photos',
      icon: Icons.photo_camera_outlined,
      group: 'Supporting Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'kyc',
      title: 'KYC Details',
      subtitle: 'Print proof type and number',
      icon: Icons.badge_outlined,
      group: 'Supporting Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'payment',
      title: 'Disbursement Details',
      subtitle: 'Print Cash, UPI, Bank or Cheque split',
      icon: Icons.account_balance_wallet_outlined,
      group: 'Supporting Details',
    ),
  ];

  Widget _buildInvoiceSetupCard() {
    final settings = _controller.invoiceSettings;
    final copyEnabled =
        settings.printTermsAndConditions || settings.printFooterMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('GIRVI BILLING SETUP'),
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
                        Icons.tune_rounded,
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
                            'Girvi Invoice Setup',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${settings.visibleInvoiceFieldCount} saved fields active',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _setupStatusPill('SAVED SETUP'),
                  ],
                ),
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _setupActionRow(
                icon: Icons.settings_backup_restore_rounded,
                title: 'Use Saved Setup',
                subtitle: 'Reload settings from Girvi Billing',
                action: 'Apply',
                onPressed: _controller.restoreSavedSetup,
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              _setupActionRow(
                icon: Icons.dashboard_customize_outlined,
                title: 'Invoice Fields',
                subtitle: 'Choose item and supporting details',
                action: 'Edit',
                onPressed: _showGirviFieldSelector,
              ),
              const Divider(color: GirviColors.shellBorder, height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: GirviColors.brandGold,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Print Saved Copy',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            copyEnabled
                                ? 'Terms and footer are included'
                                : 'Terms and footer are hidden',
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: copyEnabled,
                      onChanged: _controller.setSavedCopyEnabled,
                      activeThumbColor: GirviColors.brandGold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _setupActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: GirviColors.brandGold, size: 18),
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
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: GirviColors.brandGold,
              side: BorderSide(
                color: GirviColors.brandGold.withValues(alpha: 0.5),
              ),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
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

  void _showGirviFieldSelector() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Girvi invoice field setup',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setPanelState) {
                return Container(
                  width: MediaQuery.sizeOf(context).width < 560
                      ? MediaQuery.sizeOf(context).width - 20
                      : 460,
                  height: double.infinity,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GirviColors.shellPanelBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GirviColors.shellBorder),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 28),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 10, 13),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.dashboard_customize_outlined,
                                color: GirviColors.brandGold,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Girvi Invoice Fields',
                                      style: GoogleFonts.inter(
                                        color: GirviColors.shellTextTitle,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'Changes apply to this invoice preview',
                                      style: GoogleFonts.inter(
                                        color: GirviColors.shellTextMuted,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: GirviColors.shellTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: GirviColors.shellBorder,
                          height: 1,
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(14),
                            children: [
                              for (final group in const [
                                'Item Identity',
                                'Weight & Valuation',
                                'Supporting Details',
                              ])
                                _buildFieldGroup(
                                  group,
                                  setPanelState,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('APPLY CHANGES'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GirviColors.brandGold,
                                foregroundColor: GirviColors.shellBg,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _buildFieldGroup(String group, StateSetter setPanelState) {
    final options =
        _fieldOptions.where((option) => option.group == group).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GirviColors.shellBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 7),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: GirviColors.brandGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group,
                    style: GoogleFonts.inter(
                      color: GirviColors.shellTextTitle,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final option in options)
            SwitchListTile(
              value: _controller.getCustomizationValue(option.key),
              onChanged: (value) async {
                await _controller.setCustomization(option.key, value);
                setPanelState(() {});
              },
              dense: true,
              activeThumbColor: GirviColors.brandGold,
              secondary: Icon(
                option.icon,
                color: _controller.getCustomizationValue(option.key)
                    ? GirviColors.brandGold
                    : GirviColors.shellTextMuted,
                size: 18,
              ),
              title: Text(
                option.title,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GirviInvoiceFieldOption {
  const _GirviInvoiceFieldOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.group,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String group;
}
