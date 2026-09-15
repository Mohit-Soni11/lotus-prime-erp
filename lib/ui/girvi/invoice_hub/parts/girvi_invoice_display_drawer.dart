part of '../girvi_invoice_hub_screen.dart';

class _GirviInvoiceDisplayDrawer extends StatefulWidget {
  const _GirviInvoiceDisplayDrawer({
    required this.controller,
    required this.onClose,
  });

  final GirviInvoiceHubController controller;
  final VoidCallback onClose;

  @override
  State<_GirviInvoiceDisplayDrawer> createState() =>
      _GirviInvoiceDisplayDrawerState();
}

class _GirviInvoiceDisplayDrawerState
    extends State<_GirviInvoiceDisplayDrawer> {
  static const _itemColor = GirviColors.brandGold;
  static const _receiptColor = Color(0xFF2DD4BF);

  bool _isSaving = false;

  Future<void> _saveDisplaySetup() async {
    setState(() => _isSaving = true);
    final saved = await widget.controller.saveInvoiceDisplaySetup();
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          saved
              ? 'Girvi invoice display setup saved.'
              : 'Girvi invoice display setup could not be saved.',
        ),
      ),
    );
    if (saved) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: width < 760 ? width - 20 : 620,
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
            _buildHeader(),
            const Divider(color: GirviColors.shellBorder, height: 1),
            Expanded(child: _buildOptions()),
            _buildSaveAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 13),
      child: Row(
        children: [
          const Icon(Icons.dashboard_customize_outlined, color: _itemColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Girvi Invoice Display',
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextTitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Every switch updates the current PDF preview',
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: GirviColors.shellTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionTitle(
          icon: Icons.inventory_2_outlined,
          title: 'Pledged Item Table',
          subtitle: 'Fields printed in pledged item rows',
          color: _itemColor,
        ),
        for (final group in const ['Item Identity', 'Weight Details'])
          _buildItemFieldGroup(group),
        _sectionTitle(
          icon: Icons.price_check_outlined,
          title: 'Valuation & Photos',
          subtitle: 'Valuation columns and pledged item media',
          color: _itemColor,
        ),
        for (final group in const ['Valuation', 'Media'])
          _buildItemFieldGroup(group),
        _sectionTitle(
          icon: Icons.person_pin_circle_outlined,
          title: 'Customer & Loan Sections',
          subtitle: 'Customer details, loan terms and maturity',
          color: _receiptColor,
        ),
        for (final group in const ['Customer Details', 'Loan & Interest'])
          _buildDocumentFieldGroup(group),
        _sectionTitle(
          icon: Icons.verified_user_outlined,
          title: 'Payment, KYC & Print Content',
          subtitle: 'Disbursement, KYC, notes, terms and footer',
          color: _receiptColor,
        ),
        for (final group in const ['Payment & Verification', 'Print Content'])
          _buildDocumentFieldGroup(group),
      ],
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
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
    );
  }

  Widget _buildDocumentFieldGroup(String group) {
    final options = _girviInvoiceDocumentOptions
        .where((option) => option.group == group)
        .toList();
    return _fieldGroup(
      group: group,
      color: _receiptColor,
      options: options,
      valueFor: widget.controller.getDocumentCustomizationValue,
      onChanged: widget.controller.setDocumentCustomization,
    );
  }

  Widget _buildItemFieldGroup(String group) {
    final options = _girviInvoiceFieldOptions
        .where((option) => option.group == group)
        .toList();
    return _fieldGroup(
      group: group,
      color: _itemColor,
      options: options,
      valueFor: widget.controller.getCombinedCustomizationValue,
      onChanged: widget.controller.setCombinedCustomization,
    );
  }

  Widget _fieldGroup({
    required String group,
    required Color color,
    required List<_GirviInvoiceFieldOption> options,
    required bool Function(String key) valueFor,
    required Future<void> Function(String key, bool value) onChanged,
  }) {
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
              value: valueFor(option.key),
              onChanged: (value) async {
                await onChanged(option.key, value);
                if (mounted) setState(() {});
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

  Widget _buildSaveAction() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveDisplaySetup,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(
            _isSaving ? 'SAVING DISPLAY SETUP' : 'APPLY DISPLAY SETUP',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _itemColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
