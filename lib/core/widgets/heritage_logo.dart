import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeritageLogoWidget extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const HeritageLogoWidget({
    super.key,
    this.size = 48,
    this.primaryColor = AppTheme.kAccent,
    this.secondaryColor = AppTheme.kTerracotta,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeritagePainter(
          primary: primaryColor,
          secondary: secondaryColor,
        ),
      ),
    );
  }
}

class _HeritagePainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  const _HeritagePainter({required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final archPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final archPath = Path();
    archPath.moveTo(cx - w * 0.30, h * 0.95);
    archPath.lineTo(cx - w * 0.30, h * 0.38);
    archPath.quadraticBezierTo(cx - w * 0.30, h * 0.10, cx, h * 0.04);
    archPath.quadraticBezierTo(cx + w * 0.30, h * 0.10, cx + w * 0.30, h * 0.38);
    archPath.lineTo(cx + w * 0.30, h * 0.95);
    canvas.drawPath(archPath, archPaint);

    final basePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - w * 0.38, h * 0.95),
      Offset(cx + w * 0.38, h * 0.95),
      basePaint,
    );

    final obFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primary, secondary],
      ).createShader(Rect.fromLTWH(cx - w * 0.08, h * 0.18, w * 0.16, h * 0.60));

    final obPath = Path();
    obPath.moveTo(cx, h * 0.18);
    obPath.lineTo(cx + w * 0.08, h * 0.55);
    obPath.lineTo(cx + w * 0.10, h * 0.78);
    obPath.lineTo(cx - w * 0.10, h * 0.78);
    obPath.lineTo(cx - w * 0.08, h * 0.55);
    obPath.close();
    canvas.drawPath(obPath, obFill);

    final obStroke = Paint()
      ..color = primary.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022;
    canvas.drawPath(obPath, obStroke);

    final haloPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045;
    canvas.drawCircle(Offset(cx, h * 0.14), w * 0.115, haloPaint);

    final dotPaint = Paint()..color = primary.withOpacity(0.85);
    canvas.drawCircle(Offset(cx, h * 0.14), w * 0.038, dotPaint);

    _drawDiamond(canvas, Offset(cx - w * 0.42, h * 0.55), w * 0.07, secondary);
    _drawDiamond(
      canvas,
      Offset(cx - w * 0.42, h * 0.70),
      w * 0.05,
      secondary.withOpacity(0.6),
    );
    _drawDiamond(canvas, Offset(cx + w * 0.42, h * 0.55), w * 0.07, secondary);
    _drawDiamond(
      canvas,
      Offset(cx + w * 0.42, h * 0.70),
      w * 0.05,
      secondary.withOpacity(0.6),
    );

    final detailPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = w * 0.012;
    for (double yFrac in [0.45, 0.58, 0.68]) {
      final yy = h * yFrac;
      final halfW = _obeliskHalfWidthAt(yy, h) * w;
      canvas.drawLine(Offset(cx - halfW, yy), Offset(cx + halfW, yy), detailPaint);
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.35
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  double _obeliskHalfWidthAt(double y, double h) {
    final t = ((y / h) - 0.18) / (0.78 - 0.18);
    if (t < 0 || t > 1) return 0;
    if (t < 0.6) return 0.08 * (t / 0.6);
    return 0.08 + 0.02 * ((t - 0.6) / 0.4);
  }

  @override
  bool shouldRepaint(_HeritagePainter old) =>
      old.primary != primary || old.secondary != secondary;
}

class AnimatedHeritageLogoWidget extends StatefulWidget {
  final double size;
  const AnimatedHeritageLogoWidget({super.key, this.size = 80});

  @override
  State<AnimatedHeritageLogoWidget> createState() =>
      _AnimatedHeritageLogoWidgetState();
}

class _AnimatedHeritageLogoWidgetState extends State<AnimatedHeritageLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.kAccent.withOpacity(_glow.value),
              blurRadius: widget.size * 0.6,
              spreadRadius: widget.size * 0.05,
            ),
          ],
        ),
        child: child,
      ),
      child: HeritageLogoWidget(size: widget.size),
    );
  }
}
