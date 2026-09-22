part of '../interest_calc_screen.dart';

class _ReadyForDeliveryPanel extends StatelessWidget {
  final DateTime? expectedDeliveryDate;
  final double principalCollected;
  final double interestCollected;
  final double discountGiven;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final bool isSaving;
  final VoidCallback onDeliver;

  const _ReadyForDeliveryPanel({
    required this.expectedDeliveryDate,
    required this.principalCollected,
    required this.interestCollected,
    required this.discountGiven,
    required this.moneyFmt,
    required this.dateFmt,
    required this.isSaving,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.success.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.release,
                color: GirviColors.success,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settlement Complete',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Payment is complete. Item remains in shop custody until handover.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _FocusMetric(
                label: 'Principal Received',
                value: 'Rs ${moneyFmt.format(principalCollected)}',
                color: GirviColors.purple,
                wide: true,
              ),
              _FocusMetric(
                label: 'Interest Collected',
                value: 'Rs ${moneyFmt.format(interestCollected)}',
                color: GirviColors.warning,
                wide: true,
              ),
              if (discountGiven > 0)
                _FocusMetric(
                  label: 'Discount Approved',
                  value: 'Rs ${moneyFmt.format(discountGiven)}',
                  color: GirviColors.info,
                  wide: true,
                ),
              _FocusMetric(
                label: 'Expected Pickup',
                value: expectedDeliveryDate == null
                    ? 'Not set'
                    : dateFmt.format(expectedDeliveryDate!),
                color: GirviColors.info,
                wide: true,
              ),
              const _FocusMetric(
                label: 'Custody Status',
                value: 'In Shop',
                color: GirviColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onDeliver,
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.inventory_2_rounded, size: 18),
              label: Text(
                isSaving ? 'Delivering...' : 'Confirm Item Delivered',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
