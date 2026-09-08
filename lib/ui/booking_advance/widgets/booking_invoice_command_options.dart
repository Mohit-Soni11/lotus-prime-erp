part of 'booking_invoice_command_panel.dart';

class _DisplayOptionsSection extends StatelessWidget {
  const _DisplayOptionsSection({required this.controller});

  final BookingInvoicePreviewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('DOCUMENT DISPLAY'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BookingAdvanceColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BookingAdvanceColors.shellBorder),
          ),
          child: Column(
            children: [
              _SwitchSurface(
                icon: Icons.location_on_rounded,
                title: 'Customer Address',
                subtitle: 'Show address on booking invoice',
                value: controller.includeCustomerAddress,
                onChanged: (value) => controller.updateDocumentOptions(
                  customerAddress: value,
                ),
              ),
              const SizedBox(height: 10),
              _SwitchSurface(
                icon: Icons.price_change_rounded,
                title: 'Rate Column',
                subtitle: 'Show locked/open rate details',
                value: controller.includeRateColumn,
                onChanged: (value) => controller.updateDocumentOptions(
                  rateColumn: value,
                ),
              ),
              const SizedBox(height: 10),
              _SwitchSurface(
                icon: Icons.policy_rounded,
                title: 'Terms Note',
                subtitle: 'Show booking policy note',
                value: controller.includeTerms,
                onChanged: (value) => controller.updateDocumentOptions(
                  terms: value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchSurface extends StatelessWidget {
  const _SwitchSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PrintControlSurface(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: BookingAdvanceColors.brandGold,
        activeTrackColor:
            BookingAdvanceColors.brandGold.withValues(alpha: 0.32),
        inactiveThumbColor: BookingAdvanceColors.shellTextMuted,
        inactiveTrackColor: BookingAdvanceColors.shellBg,
      ),
    );
  }
}
