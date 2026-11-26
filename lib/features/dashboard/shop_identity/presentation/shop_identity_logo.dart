import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/domain/shop_identity.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_card_theme.dart';

class ShopIdentityLogo extends StatelessWidget {
  const ShopIdentityLogo({super.key, required this.identity});

  final ShopIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${identity.displayName} logo',
      child: Container(
        width: ShopIdentityCardTheme.logoSize,
        height: ShopIdentityCardTheme.logoSize,
        decoration: BoxDecoration(
          color: const Color(0xFF34270A),
          shape: identity.isCircularLogo ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              identity.isCircularLogo ? null : BorderRadius.circular(16),
          border: Border.all(color: ShopIdentityCardTheme.goldBorder, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: identity.hasLogo
            ? Image.file(
                File(identity.logoPath!),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _LogoFallback(identity: identity),
              )
            : _LogoFallback(identity: identity),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.identity});

  final ShopIdentity identity;

  @override
  Widget build(BuildContext context) {
    final initials = identity.initials;
    return initials.isEmpty
        ? const Icon(Icons.storefront_rounded,
            color: ShopIdentityCardTheme.gold, size: 38)
        : Text(
            initials,
            style: const TextStyle(
              color: ShopIdentityCardTheme.gold,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          );
  }
}
