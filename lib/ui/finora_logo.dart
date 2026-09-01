import 'package:flutter/material.dart';

class FinoraLogoMark extends StatelessWidget {
  final double size;

  const FinoraLogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _FinoraLogoPainter()),
      );
}

class _FinoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64;
    final sy = size.height / 64;
    final scale = sx < sy ? sx : sy;

    final background = Paint()..color = const Color(0xFF08090A);
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE58A),
          Color(0xFFF4C84A),
          Color(0xFFB97A0C),
        ],
      ).createShader(Offset.zero & size);

    final border = Paint()
      ..shader = gold.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;

    final radius = Radius.circular(14 * scale);
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(2 * sx, 2 * sy, 60 * sx, 60 * sy),
      radius,
    );
    canvas.drawRRect(outer, background);
    canvas.drawRRect(outer, border);

    // Monograma F com base inclinada, inspirado em movimento e crescimento.
    final f = Path()
      ..moveTo(17 * sx, 14 * sy)
      ..lineTo(47 * sx, 14 * sy)
      ..lineTo(44 * sx, 23 * sy)
      ..lineTo(28 * sx, 23 * sy)
      ..lineTo(27 * sx, 29 * sy)
      ..lineTo(39 * sx, 29 * sy)
      ..lineTo(35 * sx, 37 * sy)
      ..lineTo(25 * sx, 37 * sy)
      ..lineTo(15 * sx, 45 * sy)
      ..close();
    canvas.drawPath(f, gold);

    // Barras de crescimento.
    final barRadius = Radius.circular(1.5 * scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17 * sx, 49 * sy, 7 * sx, 6 * sy),
        barRadius,
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(27 * sx, 44 * sy, 7 * sx, 11 * sy),
        barRadius,
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(37 * sx, 39 * sy, 7 * sx, 16 * sy),
        barRadius,
      ),
      gold,
    );

    // Linha ascendente com seta.
    final line = Paint()
      ..shader = gold.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final trend = Path()
      ..moveTo(15 * sx, 47 * sy)
      ..lineTo(27 * sx, 37 * sy)
      ..lineTo(36 * sx, 41 * sy)
      ..lineTo(50 * sx, 29 * sy);
    canvas.drawPath(trend, line);

    final arrow = Path()
      ..moveTo(46 * sx, 29 * sy)
      ..lineTo(52 * sx, 27 * sy)
      ..lineTo(51 * sx, 33 * sy)
      ..close();
    canvas.drawPath(arrow, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
