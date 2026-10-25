import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Interactive live compass dial with 3D beveled needle and destination guide.
/// Menggunakan animasi interpolasi (smoothing) agar jarum dan dial berputar mulus tanpa patah-patah.
class CompassDialWidget extends StatefulWidget {
  final double heading; // 0.0 - 360.0 degrees
  final double? destBearing; // Optional geographic bearing to target destination
  final double size;

  const CompassDialWidget({
    super.key,
    required this.heading,
    this.destBearing,
    this.size = 170.0,
  });

  @override
  State<CompassDialWidget> createState() => _CompassDialWidgetState();
}

class _CompassDialWidgetState extends State<CompassDialWidget> {
  double _continuousHeading = 0.0;
  double _lastTargetHeading = 0.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _lastTargetHeading = widget.heading;
    _continuousHeading = widget.heading;
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant CompassDialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateContinuousHeading(widget.heading);
  }

  void _updateContinuousHeading(double newHeading) {
    if (!_initialized) {
      _lastTargetHeading = newHeading;
      _continuousHeading = newHeading;
      _initialized = true;
      return;
    }

    // Hitung jarak sudut terpendek (menghindari lompatan 360° saat melewati Utara)
    double diff = newHeading - _lastTargetHeading;
    diff = ((diff + 180) % 360 + 360) % 360 - 180;
    _continuousHeading += diff;
    _lastTargetHeading = newHeading;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _continuousHeading),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, animatedHeading, child) {
          final dialAngle = -animatedHeading * (math.pi / 180);

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Live Rotating Compass Rose (Bezel Ticks + Cardinal Letters + 3D Needle rotate smoothly)
              Transform.rotate(
                angle: dialAngle,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dial Base Ring with Bezel & Radial Grid
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _CompassDialBezelPainter(
                        isDark: isDark,
                        primaryColor: AppColors.primary,
                      ),
                    ),

                    // Cardinal Direction Letters on Bezel (U, S, T, B)
                    ..._buildCardinalLabels(context),

                    // Live 3D Beveled Needle pointing towards U (North)
                    CustomPaint(
                      size: Size(widget.size * 0.72, widget.size * 0.72),
                      painter: _CompassNeedlePainter(),
                    ),
                  ],
                ),
              ),

              // 2. Fixed Top Reference Index / Lubber Line (Always marks current heading at 12 o'clock)
              Positioned(
                top: 1,
                child: Container(
                  width: 7,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Optional Destination Beacon Indicator on Dial Edge
              if (widget.destBearing != null)
                Transform.rotate(
                  angle: (widget.destBearing! - animatedHeading) * (math.pi / 180),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Center Metallic Pivot Pin
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCardinalLabels(BuildContext context) {
    const pad = 12.0;
    return [
      // Utara (North) - Highlighted Red
      const Positioned(
        top: pad,
        child: Text(
          'U',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Selatan (South)
      Positioned(
        bottom: pad,
        child: Text(
          'S',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
          ),
        ),
      ),
      // Timur (East)
      Positioned(
        right: pad,
        child: Text(
          'T',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
            fontSize: 12,
          ),
        ),
      ),
      // Barat (West)
      Positioned(
        left: pad,
        child: Text(
          'B',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
            fontSize: 12,
          ),
        ),
      ),
    ];
  }
}

/// Custom painter for dial bezel, degree graduation lines & tick marks
class _CompassDialBezelPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  _CompassDialBezelPainter({
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle fill
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // Bezel border ring
    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.4 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Inner subtle guide ring
    final innerRingPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.72, innerRingPaint);

    // Graduation ticks: 36 ticks (every 10 degrees)
    final tickPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * (math.pi / 180);
      final isMajor = (i % 9 == 0); // 0, 90, 180, 270
      final isMid = (i % 3 == 0) && !isMajor; // 30, 60, etc.

      final tickLength = isMajor ? 9.0 : (isMid ? 6.0 : 3.5);
      final startR = radius - 5.0;
      final endR = startR - tickLength;

      tickPaint.color = isMajor
          ? (i == 0
              ? Colors.redAccent.withValues(alpha: 0.8)
              : (isDark ? Colors.white60 : Colors.black45))
          : (isMid
              ? (isDark ? Colors.white30 : Colors.black26)
              : (isDark ? Colors.white12 : Colors.black12));
      tickPaint.strokeWidth = isMajor ? 2.0 : (isMid ? 1.4 : 0.8);

      final p1 = Offset(
        center.dx + startR * math.sin(angle),
        center.dy - startR * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + endR * math.sin(angle),
        center.dy - endR * math.cos(angle),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialBezelPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.primaryColor != primaryColor;
}

/// Custom painter for a sharp 3D beveled dual-pointed needle (North Red, South Slate)
class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.height / 2 - 4;
    final halfWidth = size.width * 0.085;

    // --- 1. NORTH NEEDLE (Pointed Top, Red with 3D Left/Right lighting) ---
    // Left Half (Light Red / Highlight)
    final northLeft = Path()
      ..moveTo(center.dx, center.dy - needleLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final northLeftPaint = Paint()
      ..color = const Color(0xFFEF4444) // Bright Red
      ..style = PaintingStyle.fill;
    canvas.drawPath(northLeft, northLeftPaint);

    // Right Half (Darker Red / Shadow)
    final northRight = Path()
      ..moveTo(center.dx, center.dy - needleLength)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final northRightPaint = Paint()
      ..color = const Color(0xFFB91C1C) // Deep Dark Red
      ..style = PaintingStyle.fill;
    canvas.drawPath(northRight, northRightPaint);

    // --- 2. SOUTH NEEDLE (Pointed Bottom, Slate Gray with 3D Left/Right lighting) ---
    // Left Half (Darker Slate / Shadow)
    final southLeft = Path()
      ..moveTo(center.dx, center.dy + needleLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final southLeftPaint = Paint()
      ..color = const Color(0xFF475569) // Dark Slate
      ..style = PaintingStyle.fill;
    canvas.drawPath(southLeft, southLeftPaint);

    // Right Half (Light Slate / Highlight)
    final southRight = Path()
      ..moveTo(center.dx, center.dy + needleLength)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final southRightPaint = Paint()
      ..color = const Color(0xFF94A3B8) // Light Slate
      ..style = PaintingStyle.fill;
    canvas.drawPath(southRight, southRightPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) => false;
}
