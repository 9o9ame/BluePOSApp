import 'package:flutter/material.dart';

/// Screen 02 approved mockup chrome. Purely decorative; never owns login state.
/// Fixed BluePOS brand colors are isolated here so form logic stays unchanged.
class LoginReferenceBackground extends StatelessWidget {
  const LoginReferenceBackground({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: SizedBox.expand(child: CustomPaint(
      painter: _LoginBackgroundPainter())));
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF7F8FF));
    canvas.drawRect(rect, Paint()..shader = const RadialGradient(
      center: Alignment(0, -.08), radius: 1.1,
      colors: [Color(0xFFF9FAFF), Color(0xFFE9EDFF), Color(0xFFF5F7FF)],
      stops: [0, .75, 1],
    ).createShader(rect));
    final w = size.width, h = size.height;
    final backWave = Path()
      ..moveTo(0, h * .937)
      ..cubicTo(w * .23, h * .935, w * .35, h * 1.01, w * .60, h * .972)
      ..cubicTo(w * .82, h * .940, w * .89, h * .925, w, h * .949)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(backWave, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF83E9FD), Color(0xFF3BE9D8), Color(0xFFA4F6CB)],
    ).createShader(Rect.fromLTWH(0, h * .91, w, h * .09)));
    final frontWave = Path()
      ..moveTo(0, h * .975)
      ..cubicTo(w * .28, h * .970, w * .61, h * .915, w, h * .927)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(frontWave, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF61E0FB), Color(0xFF50E8D6), Color(0xFFAEF9C9)],
    ).createShader(Rect.fromLTWH(0, h * .915, w, h * .085)));
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) => false;
}

class LoginReferenceBrand extends StatelessWidget {
  const LoginReferenceBrand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        key: const ValueKey('login-reference-logo'),
        height: 49, width: 49,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF00DBEA), Color(0xFF05A7F6), Color(0xFF0054FB)]),
          boxShadow: const [BoxShadow(color: Color(0x222B83ED),
            blurRadius: 12, offset: Offset(0, 6))]),
        child: CustomPaint(painter: _StoreCartPainter()),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text.rich(TextSpan(children: const [
            TextSpan(text: 'Blue', style: TextStyle(color: Color(0xFF071947))),
            TextSpan(text: 'POS', style: TextStyle(color: Color(0xFF079BFA))),
          ]), textScaler: const TextScaler.linear(1),
            style: const TextStyle(fontSize: 29, height: 1.0,
              letterSpacing: -1.4, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('P O S  &  E R P', textScaler: TextScaler.linear(1),
            style: TextStyle(color: Color(0xFF06183C),
              fontWeight: FontWeight.w700, fontSize: 9.2, letterSpacing: .8)),
        ]),
    ],
  );
}

class _StoreCartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 49;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()..color = Colors.white..style = PaintingStyle.stroke
      ..strokeWidth = 2.8..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cart = Path()..moveTo(10, 13)..lineTo(14, 13)
      ..lineTo(19, 32)..lineTo(38, 32)..lineTo(40, 19)
      ..lineTo(16, 19);
    canvas.drawPath(cart, stroke);
    canvas.drawCircle(const Offset(21, 39), 2.3,
      Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(35, 39), 2.3,
      Paint()..color = Colors.white);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _StoreCartPainter oldDelegate) => false;
}

/// Store-front hero built as normal vector Flutter widgets rather than
/// a static screenshot; scales down for 320px devices.
class LoginReferenceStorefront extends StatelessWidget {
  const LoginReferenceStorefront({super.key, this.height = 122});
  final double height;
  @override
  Widget build(BuildContext context) {
    final factor = height / 122;
    return Center(child: SizedBox(
      key: const ValueKey('login-storefront-hero'),
      height: height, width: 240 * factor,
      child: CustomPaint(painter: _StorefrontPainter())));
  }
}

class _StorefrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final f = size.height / 122;
    canvas.save();
    canvas.scale(f);
    // Artwork coordinates follow the reference's small centered storefront
    // rather than filling its entire 240px layout slot.
    const cx = 120.0;
    final glow = Rect.fromCircle(center: const Offset(cx, 64), radius: 61);
    canvas.drawCircle(const Offset(cx, 65), 61,
      Paint()..shader = const RadialGradient(
        colors: [Color(0xFFFFEAD3), Color(0xFFFCEFE0), Color(0x00FAF1E7)],
        stops: [0, .64, 1]).createShader(glow));
    // A low irregular cloud cushion around the storefront, with soft edges.
    void cloud(Offset center, double rx, double ry, Color inner) {
      final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
      canvas.drawOval(rect, Paint()..shader = RadialGradient(
        colors: [inner, inner.withValues(alpha: 0)],
      ).createShader(rect));
    }
    cloud(const Offset(78, 92), 46, 27, const Color(0x9959E9C9));
    cloud(const Offset(164, 91), 43, 28, const Color(0xAA68D0F9));
    cloud(const Offset(95, 108), 38, 17, const Color(0xAA60D5F8));
    cloud(const Offset(146, 107), 39, 18, const Color(0x8861E8C6));
    // Very soft base shadow directly below the shop.
    canvas.drawOval(const Rect.fromLTWH(78, 106, 89, 10),
      Paint()..color = const Color(0x330D79BE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    final shop = RRect.fromRectAndRadius(
      const Rect.fromLTWH(87, 54, 78, 55), const Radius.circular(7));
    canvas.drawRRect(shop, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFF9FDFF), Color(0xFFC4E9FF)],
    ).createShader(const Rect.fromLTWH(87, 54, 78, 55)));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(102, 73, 25, 36), const Radius.circular(3)),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF008FFF), Color(0xFF49C2FC)],
      ).createShader(const Rect.fromLTWH(102, 73, 25, 36)));
    canvas.drawCircle(const Offset(121, 94), 1.7,
      Paint()..color = const Color(0xFFB6E8FF));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(136, 72, 22, 23), const Radius.circular(3)),
      Paint()..color = const Color(0xFF22A7F7));
    canvas.drawLine(const Offset(139, 91), const Offset(154, 75),
      Paint()..color = const Color(0x99A5EDFF)..strokeWidth = 2);
    // Orange canopy: five alternating tapered fabric strips and soft
    // scalloped hems, not a squared-off cartoon strip.
    final roof = Path()
      ..moveTo(94, 39)..lineTo(155, 39)
      ..quadraticBezierTo(157, 39, 159, 42)
      ..lineTo(172, 61)..lineTo(79, 61)
      ..lineTo(92, 41)..close();
    canvas.drawPath(roof, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFFABB46), Color(0xFFF78A00)],
    ).createShader(const Rect.fromLTWH(79, 39, 93, 26)));
    const strips = <Color>[
      Color(0xFFF9990C), Color(0xFFFFF5E9), Color(0xFFF49B15),
      Color(0xFFFFF5E9), Color(0xFFEF8B09),
    ];
    for (var i = 0; i < 5; i++) {
      final x = 80.0 + i * 18.1;
      final shade = strips[i];
      final piece = Path()
        ..moveTo(91 + i * 13.1, 39)
        ..lineTo(104 + i * 13.1, 39)
        ..lineTo(x + 18.1, 60)
        ..lineTo(x, 60)..close();
      canvas.drawPath(piece, Paint()..color = shade);
      canvas.drawArc(Rect.fromLTWH(x, 53, 18.1, 15),
        0, 3.14159265, false, Paint()..color = shade);
    }
    // Reference's three emerald celebration marks.
    final accent = Paint()..color = const Color(0xFF03AE69)
      ..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(168, 16), const Offset(168, 30), accent);
    canvas.drawLine(const Offset(182, 23), const Offset(191, 12), accent);
    canvas.drawLine(const Offset(188, 35), const Offset(199, 31), accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StorefrontPainter oldDelegate) => false;
}

class LoginReferenceGradientButton extends StatelessWidget {
  const LoginReferenceGradientButton({super.key, required this.onPressed,
    required this.busy, required this.label});
  final VoidCallback? onPressed;
  final bool busy;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(height: 49, child:
    DecoratedBox(decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF03CDF4), Color(0xFF009EFF), Color(0xFF0845FC)]),
      boxShadow: const [BoxShadow(color: Color(0x300356D9),
        blurRadius: 13, offset: Offset(0, 6))]),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            const Positioned.fill(child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: IgnorePointer(child: CustomPaint(
                painter: _LoginButtonShinePainter())))),
            Center(child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) const SizedBox(width: 17, height: 17,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                else const Icon(Icons.login_rounded,
                  color: Colors.white, size: 21),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            )),
          ]),
        ),
      ),
    ));
}


class _LoginButtonShinePainter extends CustomPainter {
  const _LoginButtonShinePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final curve = Path()
      ..moveTo(w * .59, h)
      ..quadraticBezierTo(w * .78, h * .88, w, h * .01)
      ..lineTo(w, h)..close();
    canvas.drawPath(curve, Paint()
      ..color = const Color(0x220028F6));
    final topGlow = Path()
      ..moveTo(0, 0)..lineTo(w, 0)
      ..quadraticBezierTo(w * .58, h * .24, 0, h * .15)
      ..close();
    canvas.drawPath(topGlow, Paint()
      ..color = const Color(0x10FFFFFF));
  }
  @override
  bool shouldRepaint(covariant _LoginButtonShinePainter oldDelegate) => false;
}
