import 'package:flutter/material.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_card_theme.dart';

class ShopIdentityDetailRow extends StatelessWidget {
  const ShopIdentityDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: ShopIdentityCardTheme.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onTap == null
                        ? ShopIdentityCardTheme.secondaryText
                        : const Color(0xFF8FC8FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: onTap == null
                        ? TextDecoration.none
                        : TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
