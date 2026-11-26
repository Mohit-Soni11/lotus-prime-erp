import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/security_access/domain/security_access_identity.dart';

import '../security_access_theme.dart';

class SecurityIdentityPanel extends StatelessWidget {
  const SecurityIdentityPanel({super.key, required this.identity});

  final SecurityAccessIdentity identity;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ShopLogo(identity: identity),
          const SizedBox(height: 22),
          Text(
            identity.shopName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SecurityAccessTheme.text,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep your sign-in details protected and update your password whenever you need to.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SecurityAccessTheme.text,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          const _SecurityGuidanceCard(),
        ],
      );
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo({required this.identity});

  final SecurityAccessIdentity identity;

  @override
  Widget build(BuildContext context) {
    final path = identity.logoPath?.trim() ?? '';
    final file = path.isEmpty ? null : File(path);
    final hasImage = file?.existsSync() ?? false;
    final square = identity.logoShape.toLowerCase() == 'square';
    return Container(
      width: 198,
      height: 198,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(28) : null,
        border: Border.all(color: SecurityAccessTheme.goldBorder, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: hasImage
          ? Image.file(
              file!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Center(
        child: Text(
          identity.initials.toUpperCase(),
          style: const TextStyle(
            color: SecurityAccessTheme.gold,
            fontSize: 62,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
          ),
        ),
      );
}

class _SecurityGuidanceCard extends StatelessWidget {
  const _SecurityGuidanceCard();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SecurityAccessTheme.goldBorder),
        ),
        child: const Column(
          children: [
            _GuidanceRow(
              icon: Icons.key_outlined,
              title: 'Use a Strong Password',
              detail: 'Use at least 8 characters with letters and numbers.',
            ),
            SizedBox(height: 16),
            _GuidanceRow(
              icon: Icons.shield_outlined,
              title: 'Keep It Private',
              detail: 'Do not share your password with anyone.',
            ),
            SizedBox(height: 16),
            _GuidanceRow(
              icon: Icons.sync_lock_outlined,
              title: 'Update When Needed',
              detail: 'Change your password if you suspect any misuse.',
            ),
          ],
        ),
      );
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SecurityAccessTheme.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SecurityAccessTheme.gold, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: SecurityAccessTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(detail,
                    style: const TextStyle(
                        color: SecurityAccessTheme.text,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}
