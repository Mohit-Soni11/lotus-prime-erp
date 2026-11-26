import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/security_access/domain/password_strength.dart';

class SecurityPasswordStrengthMeter extends StatelessWidget {
  const SecurityPasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          for (var index = 0; index < 3; index++) ...[
            Expanded(
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: index < strength.filledSegments
                      ? strength.color
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (index < 2) const SizedBox(width: 7),
          ],
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: strength.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              strength.label,
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
