import 'package:flutter/material.dart';

class BrandLotusLogo extends StatelessWidget {
  const BrandLotusLogo({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: compact ? 132 : 172,
        height: compact ? 88 : 116,
        child: Image.asset(
          'lib/logo/Gold Lotus Clean.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'Lotus ERP gold lotus logo',
        ),
      );
}
