import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/appearance.dart';

/// Screen 01: reference-matched presentation only.
/// This widget never delays real session initialization or simulates login.
class BlueposSplash extends StatefulWidget {
  const BlueposSplash({super.key, required this.appearance});
  final AppAppearance appearance;

  @override
  State<BlueposSplash> createState() => _BlueposSplashState();
}

class _BlueposSplashState extends State<BlueposSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150));
    if (widget.appearance.animations) {
      _motion.repeat(reverse: true);
    } else {
      _motion.value = .5;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The reference is a fixed branded splash, not a color-theme preview.
    // Its identity palette is intentionally consistent in light/dark mode.
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      body: LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest;
        final topInset = MediaQuery.paddingOf(context).top;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final usableHeight = size.height - topInset - bottomInset;
        final scale = math.min(1.1, math.min(size.width / 375, usableHeight / 780));
        final icon = 113.0 * scale;
        // Positions are percentages of the actual display area, matching
        // reference 01 after removing its decorative phone-frame bezel.
        return Stack(children: [
          const Positioned.fill(child: CustomPaint(
            painter: _SplashBackgroundPainter())),
          Positioned(
            left: 0, right: 0,
            top: topInset + usableHeight * .276,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                key: const ValueKey('splash-cart-logo'),
                width: icon, height: icon,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29 * scale),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00E0E6),
                      Color(0xFF00A9FC),
                      Color(0xFF0046FA),
                    ],
                    stops: [0.0, .50, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF146BDE).withValues(alpha: .2),
                      blurRadius: 24 * scale, offset: Offset(0, 13 * scale)),
                  ],
                ),
                child: CustomPaint(painter: _CartMarkPainter()),
              ),
              SizedBox(height: 15 * scale),
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'Blue',
                  style: TextStyle(color: Color(0xFF081B54))),
                const TextSpan(text: 'POS',
                  style: TextStyle(color: Color(0xFF139BFE))),
              ]), key: const ValueKey('splash-wordmark'),
                textAlign: TextAlign.center,
                textScaler: const TextScaler.linear(1),
                style: TextStyle(fontSize: 50 * scale,
                  letterSpacing: -2.8 * scale,
                  height: 1.08,
                  fontWeight: FontWeight.w900)),
              SizedBox(height: 5 * scale),
              Text('P O S  &  E R P',
                textAlign: TextAlign.center,
                textScaler: const TextScaler.linear(1),
                style: TextStyle(color: const Color(0xFF061844),
                  fontSize: 15.5 * scale,
                  fontWeight: FontWeight.w700)),
            ]),
          ),
          Positioned(
            top: topInset + usableHeight * .604,
            left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _motion,
              builder: (context, _) => Row(
                key: const ValueKey('splash-loading-dots'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++) Container(
                    margin: EdgeInsets.symmetric(horizontal: 5 * scale),
                    width: 10 * scale, height: 10 * scale,
                    decoration: BoxDecoration(
                      color: i == 1
                        ? const Color(0xFF128FFB)
                        : Color.lerp(
                            const Color(0xFF9CCCF8),
                            const Color(0xFFBEDCFB),
                            _motion.value)!,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topInset + usableHeight * .66,
            left: 12, right: 12,
            child: Text('Complete Business Management',
              textAlign: TextAlign.center,
              textScaler: const TextScaler.linear(1),
              style: TextStyle(
                color: const Color(0xFF405377),
                fontWeight: FontWeight.w400,
                fontSize: 15 * scale)),
          ),
        ]);
      }),
    );
  }
}

class _CartMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 113;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final cart = Path()
      ..moveTo(24 * scale, 28 * scale)
      ..lineTo(34 * scale, 28 * scale)
      ..quadraticBezierTo(37 * scale, 28 * scale, 38 * scale, 33 * scale)
      ..lineTo(47 * scale, 72 * scale)
      ..quadraticBezierTo(48 * scale, 77 * scale, 53 * scale, 77 * scale)
      ..lineTo(88 * scale, 77 * scale)
      ..lineTo(94 * scale, 41 * scale)
      ..lineTo(41 * scale, 41 * scale);
    canvas.drawPath(cart, paint);
    final wheel = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(53 * scale, 91 * scale), 5.4 * scale, wheel);
    canvas.drawCircle(Offset(84 * scale, 91 * scale), 5.4 * scale, wheel);
  }

  @override
  bool shouldRepaint(covariant _CartMarkPainter oldDelegate) => false;
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
      Paint()..color = const Color(0xFFF7F8FF));

    // Wide subtle lavender glows are intentional reference colors.
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(center, radius, Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)));
    }
    glow(Offset(size.width * .16, size.height * .39),
      size.width * .75, const Color(0x22999AF5));
    glow(Offset(size.width * .84, size.height * .65),
      size.width * .80, const Color(0x2299C2FF));
    glow(Offset(size.width * .80, size.height * .96),
      size.width * .75, const Color(0x5565F6D0));

    final w = size.width, h = size.height;
    final leftWave = Path()
      ..moveTo(0, h * .872)
      ..cubicTo(w * .24, h * .866, w * .41, h * .94, w * .66, h * .914)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(leftWave, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8FEAFF), Color(0xFF6AEFE5)],
      ).createShader(Rect.fromLTWH(0, h * .83, w, h * .17)));

    final mintWave = Path()
      ..moveTo(0, h * .958)
      ..cubicTo(w * .27, h * .946, w * .68, h * .803, w, h * .832)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(mintWave, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [
          Color(0xFF78EAF7),
          Color(0xFF59F0D5),
          Color(0xFFACF9CB),
        ],
      ).createShader(Rect.fromLTWH(0, h * .82, w, h * .18)));
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) => false;
}
