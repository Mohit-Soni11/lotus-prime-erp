import 'package:flutter/material.dart';

import 'brand_lotus_logo.dart';
import 'luxury_auth_palette.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 360;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF07162F), Color(0xFF020B1C)],
                  ),
                ),
              ),
              if (!compact)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: constraints.maxHeight * .60,
                  child: Image.asset(
                    'assets/images/auth_wedding_rings.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              if (!compact)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: constraints.maxHeight * .40,
                  height: constraints.maxHeight * .20,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF07162F), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              const Positioned.fill(
                  child: CustomPaint(painter: _BrandSweepPainter())),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(compact ? 18 : 32,
                      compact ? 12 : 40, compact ? 18 : 32, compact ? 12 : 20),
                  child: Column(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      BrandLotusLogo(compact: compact),
                      SizedBox(height: compact ? 2 : 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'LOTUS ERP',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: compact ? 38 : 61,
                            letterSpacing: 1.2,
                            color: LuxuryAuthPalette.paleGold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 8),
                      Text(
                        'Professional Jewellery Operations Platform',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12 : 17,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 23),
                        Container(
                          width: 310,
                          height: 1,
                          decoration: const BoxDecoration(
                              gradient: LuxuryAuthPalette.goldGradient),
                        ),
                        const SizedBox(height: 27),
                        const Text(
                          'Every operation, seamlessly connected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            letterSpacing: .3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xCE031024),
                            border: Border.all(
                                color: LuxuryAuthPalette.gold, width: 1.4),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront_rounded,
                                  color: LuxuryAuthPalette.gold, size: 21),
                              SizedBox(width: 10),
                              Text('Single-shop workspace',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _BrandSweepPainter extends CustomPainter {
  const _BrandSweepPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final upper = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .39, 0)
      ..quadraticBezierTo(
          size.width * .15, size.height * .04, 0, size.height * .13)
      ..close();
    canvas.drawPath(
      upper,
      Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFF9F6B18),
          Color(0xFFFFE6A0),
          Color(0xFFB97C19)
        ]).createShader(Offset.zero & size),
    );
    final lower = Path()
      ..moveTo(size.width * .65, size.height)
      ..quadraticBezierTo(
          size.width * .89, size.height * .95, size.width, size.height * .78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lower, Paint()..color = LuxuryAuthPalette.darkGold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
