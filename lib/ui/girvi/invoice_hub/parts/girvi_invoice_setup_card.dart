part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceSetupCard on _GirviInvoiceHubScreenState {
  static const _fieldOptions = <_GirviInvoiceFieldOption>[
    _GirviInvoiceFieldOption(
      key: 'serial',
      title: 'Serial Number',
      subtitle: 'Item row number',
      icon: Icons.format_list_numbered_rounded,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'metal',
      title: 'Metal',
      subtitle: 'Gold, silver, diamond or platinum',
      icon: Icons.category_outlined,
      group: 'Item Identity',
    ),
    _GirviInvoiceFieldOption(
      key: 'item',
      title: 'Item Name',
      subtitle: 'Pledged item description',
      icon: Icons.inventory_2_outlined,
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
      title: 'Purity',
      subtitle: 'Entered purity or tunch',
      icon: Icons.diamond_outlined,
      group: 'Weight Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'gross',
      title: 'Gross Weight',
      subtitle: 'Total item weight',
      icon: Icons.scale_outlined,
      group: 'Weight Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'less',
      title: 'Less Weight',
      subtitle: 'Stone and non-metal deduction',
      icon: Icons.remove_circle_outline_rounded,
      group: 'Weight Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'net',
      title: 'Net Weight',
      subtitle: 'Weight after deductions',
      icon: Icons.balance_outlined,
      group: 'Weight Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'valuationPurity',
      title: 'Valuation Purity',
      subtitle: 'Purity percentage used for valuation',
      icon: Icons.percent_rounded,
      group: 'Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'fineWeight',
      title: 'Fine Weight',
      subtitle: 'Calculated fine metal weight',
      icon: Icons.calculate_outlined,
      group: 'Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'ratePerGram',
      title: 'Valuation Rate / Gram',
      subtitle: 'Rate used for pledged value',
      icon: Icons.trending_up_rounded,
      group: 'Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'valuationAmount',
      title: 'Item Valuation Amount',
      subtitle: 'Calculated item value',
      icon: Icons.currency_rupee_rounded,
      group: 'Valuation',
    ),
    _GirviInvoiceFieldOption(
      key: 'photos',
      title: 'Item Photos',
      subtitle: 'Attached pledged-item photos',
      icon: Icons.photo_camera_outlined,
      group: 'Media',
    ),
  ];

  static const _documentOptions = <_GirviInvoiceFieldOption>[
    _GirviInvoiceFieldOption(
      key: 'customerMobile',
      title: 'Customer Mobile',
      subtitle: 'Selected customer mobile number',
      icon: Icons.phone_outlined,
      group: 'Customer Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'customerCity',
      title: 'Customer Address',
      subtitle: 'Full address saved in the customer profile',
      icon: Icons.location_on_outlined,
      group: 'Customer Details',
    ),
    _GirviInvoiceFieldOption(
      key: 'loanAmount',
      title: 'Loan Amount',
      subtitle: 'Principal paid against the pledge',
      icon: Icons.account_balance_wallet_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'interestRate',
      title: 'Monthly Interest Rate',
      subtitle: 'Interest percentage per month',
      icon: Icons.percent_rounded,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'duration',
      title: 'Loan Duration',
      subtitle: 'Duration in months',
      icon: Icons.timelapse_rounded,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'startDate',
      title: 'Start Date',
      subtitle: 'Loan start date',
      icon: Icons.event_available_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'maturityDate',
      title: 'Maturity Date',
      subtitle: 'Calculated maturity date',
      icon: Icons.event_busy_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'monthlyInterest',
      title: 'Monthly Interest Amount',
      subtitle: 'One month interest amount',
      icon: Icons.calendar_view_month_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'totalInterest',
      title: 'Total Interest',
      subtitle: 'Estimated interest at maturity',
      icon: Icons.show_chart_rounded,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'totalDue',
      title: 'Total Amount Due',
      subtitle: 'Principal plus total interest',
      icon: Icons.payments_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'totalValuation',
      title: 'Total Pledged Valuation',
      subtitle: 'Combined value of all pledged items',
      icon: Icons.price_check_outlined,
      group: 'Loan & Interest',
    ),
    _GirviInvoiceFieldOption(
      key: 'disbursement',
      title: 'Disbursement Breakdown',
      subtitle: 'Cash, UPI, bank and cheque split',
      icon: Icons.account_balance_outlined,
      group: 'Payment & Verification',
    ),
    _GirviInvoiceFieldOption(
      key: 'kycDetails',
      title: 'KYC Type & Number',
      subtitle: 'Identity document details',
      icon: Icons.badge_outlined,
      group: 'Payment & Verification',
    ),
    _GirviInvoiceFieldOption(
      key: 'kycPhoto',
      title: 'KYC Card Photo',
      subtitle: 'Attached identity document image',
      icon: Icons.document_scanner_outlined,
      group: 'Payment & Verification',
    ),
    _GirviInvoiceFieldOption(
      key: 'notes',
      title: 'Notes & Remarks',
      subtitle: 'Entered ticket remarks',
      icon: Icons.notes_rounded,
      group: 'Payment & Verification',
    ),
    _GirviInvoiceFieldOption(
      key: 'terms',
      title: 'Terms & Conditions',
      subtitle: 'Bilingual Girvi terms',
      icon: Icons.gavel_outlined,
      group: 'Print Content',
    ),
    _GirviInvoiceFieldOption(
      key: 'declaration',
      title: 'Customer Declaration',
      subtitle: 'Bilingual declaration above signatures',
      icon: Icons.fact_check_outlined,
      group: 'Print Content',
    ),
    _GirviInvoiceFieldOption(
      key: 'footer',
      title: 'Footer Message',
      subtitle: 'Optional saved footer message',
      icon: Icons.vertical_align_bottom_rounded,
      group: 'Print Content',
    ),
  ];

  Widget _buildInvoiceSetupCard() {
    final metals = _controller.presentMetals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('GIRVI BILLING SETUP'),
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
          _buildCombinedSetupCard(metals),
          const SizedBox(height: 12),
          _buildReceiptSetupCard(),
        ],
      ],
    );
  }

  Widget _buildCombinedSetupCard(List<String> metals) {
    const color = GirviColors.brandGold;
    final metalNames = metals.map(GirviBillingMetal.displayName).join(', ');
    final activeFields = _fieldOptions
        .where(
          (option) => _controller.getCombinedCustomizationValue(option.key),
        )
        .length;

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
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
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
                        'Girvi Invoice Setup',
                        style: GoogleFonts.inter(
                          color: GirviColors.shellTextTitle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$activeFields of ${_fieldOptions.length} common fields'
                        ' | Items: $metalNames',
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
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Use Saved Girvi Setup',
            subtitle: 'Reload saved fields for every pledged metal',
            action: 'Apply',
            color: color,
            onPressed: _controller.restoreCombinedSavedSetup,
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.dashboard_customize_outlined,
            title: 'Invoice Fields',
            subtitle: 'One field setup for all items in this invoice',
            action: 'Edit',
            color: color,
            onPressed: _showFieldSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSetupCard() {
    const color = Color(0xFF2DD4BF);
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
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Receipt Sections',
                        style: GoogleFonts.inter(
                          color: GirviColors.shellTextTitle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${_controller.invoiceSettings.visibleDocumentFieldCount} '
                        'of ${_documentOptions.length} fields visible',
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
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Use Saved Receipt Setup',
            subtitle: 'Reload customer, loan, KYC and terms settings',
            action: 'Apply',
            color: color,
            onPressed: _controller.restoreDocumentSavedSetup,
          ),
          const Divider(color: GirviColors.shellBorder, height: 1),
          _setupActionRow(
            icon: Icons.dashboard_customize_outlined,
            title: 'Receipt Sections',
            subtitle: 'Choose additional sections for this preview',
            action: 'Edit',
            color: color,
            onPressed: _showDocumentSelector,
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

  void _showFieldSelector() {
    const color = GirviColors.brandGold;
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
                                color: color,
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
                                      'Changes apply to this preview only',
                                      style: GoogleFonts.inter(
                                        color: GirviColors.shellTextMuted,
                                        fontSize: 12.5,
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
                                'Weight Details',
                                'Valuation',
                                'Media',
                              ])
                                _buildFieldGroup(
                                  group,
                                  color,
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
                                backgroundColor: color,
                                foregroundColor: Colors.black,
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

  void _showDocumentSelector() {
    const color = Color(0xFF2DD4BF);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Girvi receipt section setup',
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
                      : 470,
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
                                Icons.receipt_long_outlined,
                                color: color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Receipt Sections',
                                      style: GoogleFonts.inter(
                                        color: GirviColors.shellTextTitle,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'Changes apply to this preview only',
                                      style: GoogleFonts.inter(
                                        color: GirviColors.shellTextMuted,
                                        fontSize: 12.5,
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
                                'Customer Details',
                                'Loan & Interest',
                                'Payment & Verification',
                                'Print Content',
                              ])
                                _buildDocumentFieldGroup(
                                  group,
                                  color,
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
                                backgroundColor: color,
                                foregroundColor: Colors.black,
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

  Widget _buildDocumentFieldGroup(
    String group,
    Color color,
    StateSetter setPanelState,
  ) {
    final options =
        _documentOptions.where((option) => option.group == group).toList();
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group,
                    style: GoogleFonts.inter(
                      color: GirviColors.shellTextTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final option in options)
            SwitchListTile(
              value: _controller.getDocumentCustomizationValue(option.key),
              onChanged: (value) async {
                await _controller.setDocumentCustomization(option.key, value);
                setPanelState(() {});
              },
              dense: true,
              activeThumbColor: color,
              secondary: Icon(option.icon, color: color, size: 18),
              title: Text(
                option.title,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldGroup(
    String group,
    Color color,
    StateSetter setPanelState,
  ) {
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group,
                    style: GoogleFonts.inter(
                      color: GirviColors.shellTextTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final option in options)
            SwitchListTile(
              value: _controller.getCombinedCustomizationValue(option.key),
              onChanged: (value) async {
                await _controller.setCombinedCustomization(
                  option.key,
                  value,
                );
                setPanelState(() {});
              },
              dense: true,
              activeThumbColor: color,
              secondary: Icon(option.icon, color: color, size: 18),
              title: Text(
                option.title,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted,
                  fontSize: 12.5,
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
