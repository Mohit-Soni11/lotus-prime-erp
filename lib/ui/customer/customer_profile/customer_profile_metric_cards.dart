import 'package:flutter/material.dart';

import '../../../theme/customer/customer_profile/customer_profile_theme.dart';

class CustomerProfileMetricCard extends StatelessWidget {
  const CustomerProfileMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: const [
          BoxShadow(
            color: CustomerProfileColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CustomerProfileColors.bodyTextMain))),
          ]),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CustomerProfileColors.bodyTextMain)),
          if (detail != null) ...[
            const SizedBox(height: 3),
            Text(detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CustomerProfileColors.bodyTextMain)),
          ],
        ],
      ),
    );
  }
}

class CustomerProfileLedgerCard extends StatelessWidget {
  const CustomerProfileLedgerCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.metrics,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 9),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: CustomerProfileColors.bodyTextMain))),
          ]),
          const SizedBox(height: 14),
          for (final (label, value) in metrics) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CustomerProfileColors.bodyTextMain))),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: CustomerProfileColors.bodyTextMain))),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
