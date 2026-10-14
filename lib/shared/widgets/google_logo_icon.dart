import 'package:flutter/material.dart';

/// Official-style Google 'G' multicolored logo drawn dynamically with CustomPainter
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Google 4 Official Colors
    const colorBlue = Color(0xFF4285F4);
    const colorRed = Color(0xFFEA4335);
    const colorYellow = Color(0xFFFBBC05);
    const colorGreen = Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red Arc (Top)
    paint.color = colorRed;
    canvas.drawArc(rect, -2.356, 1.571, false, paint); // ~135° to 225°

    // 2. Yellow Arc (Left)
    paint.color = colorYellow;
    canvas.drawArc(rect, 2.356, 1.571, false, paint); // ~225° to 315°

    // 3. Green Arc (Bottom)
    paint.color = colorGreen;
    canvas.drawArc(rect, 0.785, 1.571, false, paint); // ~45° to 135°

    // 4. Blue Arc (Right & Crossbar)
    paint.color = colorBlue;
    canvas.drawArc(rect, -0.785, 1.571, false, paint); // ~-45° to 45°

    // Blue horizontal bar in center
    final barPaint = Paint()
      ..color = colorBlue
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTRB(
      w * 0.45,
      h * 0.39,
      w * 0.98,
      h * 0.61,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
