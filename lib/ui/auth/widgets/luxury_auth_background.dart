import 'package:flutter/material.dart';

import 'luxury_auth_palette.dart';

class LuxuryAuthBackground extends StatelessWidget {
  const LuxuryAuthBackground({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _LuxuryBackgroundPainter(),
        child: const SizedBox.expand(),
      );
}

class _LuxuryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF040D20), Color(0xFF0C1A35), Color(0xFF1D3459)],
        ).createShader(bounds),
    );

    final upper = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .25, 0)
      ..cubicTo(size.width * .16, size.height * .035, size.width * .075,
          size.height * .13, 0, size.height * .21)
      ..close();
    canvas.drawPath(
      upper,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF875912), Color(0xFFFFE8AA), Color(0xFFBD8424)],
        ).createShader(
            Rect.fromLTWH(0, 0, size.width * .25, size.height * .22)),
    );
    final upperEdge = Path()
      ..moveTo(0, size.height * .28)
      ..cubicTo(size.width * .09, size.height * .12, size.width * .18,
          size.height * .02, size.width * .29, 0);
    canvas.drawPath(upperEdge, _linePaint(1.5));

    final lower = Path()
      ..moveTo(size.width * .67, size.height)
      ..cubicTo(size.width * .81, size.height * .92, size.width * .92,
          size.height * .8, size.width, size.height * .72)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      lower,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF8C5B13), Color(0xFFFFE8AC), Color(0xFFB47D1D)],
        ).createShader(bounds),
    );
    final lowerEdge = Path()
      ..moveTo(size.width * .58, size.height)
      ..cubicTo(size.width * .8, size.height * .91, size.width * .94,
          size.height * .77, size.width, size.height * .67);
    canvas.drawPath(lowerEdge, _linePaint(2));
  }

  Paint _linePaint(double width) => Paint()
    ..color = LuxuryAuthPalette.paleGold
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
