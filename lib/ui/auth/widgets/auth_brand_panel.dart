import 'package:flutter/material.dart';

import '../../../theme/dashboard/app/uv.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: UV.colors.overlayDark,
        padding: EdgeInsets.all(UV.layout.pLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              UV.icons.defaultStore,
              size: UV.layout.iconXl,
              color: UV.colors.primary,
            ),
            SizedBox(height: UV.layout.pMd),
            Text('LOTUS ERP',
                style: UV.styles.hero, textAlign: TextAlign.center),
            SizedBox(height: UV.layout.pSm),
            Text(
              'Professional Jewellery Operations Platform',
              style: UV.styles.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: UV.layout.pMd,
                vertical: UV.layout.pXs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: UV.colors.successBorder),
                borderRadius: BorderRadius.circular(UV.layout.radiusCircular),
                color: UV.colors.successBg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(UV.icons.success,
                      color: UV.colors.success, size: UV.layout.iconSm),
                  SizedBox(width: UV.layout.pXs),
                  Text(
                    'Single-shop workspace',
                    style: UV.styles.hint.copyWith(
                      color: UV.colors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
