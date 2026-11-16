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
    final backdrop = Paint()
      ..shader = const RadialGradient(colors: [
        Color(0xFFFFEAD1), Color(0xFFFAF0DE), Color(0x00FAF0DE)],
        stops: [0, .65, 1])
        .createShader(const Rect.fromLTWH(42, 4, 156, 120));
    canvas.drawCircle(const Offset(120, 68), 67, backdrop);
    // Soft mint/blue clouds behind the shop.
    for (final cloud in <(Offset,double,Color)>[
      (const Offset(52, 96), 37, const Color(0x7759EBCB)),
      (const Offset(194, 92), 34, const Color(0x8859CFFD)),
      (const Offset(83, 111), 26, const Color(0xBB8DEFFF)),
      (const Offset(167, 112), 32, const Color(0xAA81E5C5)),
    ]) {
      canvas.drawCircle(cloud.$1, cloud.$2, Paint()..color = cloud.$3);
    }
    final shadow = Paint()..color = const Color(0x330A73AC)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(79, 49, 94, 66), const Radius.circular(9)), shadow);
    // Store facade.
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(80, 45, 94, 68), const Radius.circular(8)),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFFFCFFFF), Color(0xFFC6EDFC)],
      ).createShader(const Rect.fromLTWH(80, 45, 94, 68)));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(95, 71, 25, 42), const Radius.circular(4)),
      Paint()..color = const Color(0xFF25A9F5));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(130, 69, 30, 25), const Radius.circular(4)),
      Paint()..color = const Color(0xFF43BDF8));
    canvas.drawLine(const Offset(132, 91), const Offset(157, 72),
      Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 2);
    // Orange striped shop awning.
    final roof = Path()
      ..moveTo(89, 34)..lineTo(166, 34)..lineTo(184, 56)
      ..lineTo(76, 56)..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFFCA528));
    for (var i = 0; i < 5; i++) {
      final left = 79.0 + i * 21;
      final stripe = Path()
        ..moveTo(left + 10, 34)..lineTo(left + 20, 34)
        ..lineTo(left + 20, 56)..lineTo(left + 1, 56)..close();
      canvas.drawPath(stripe, Paint()..color = i.isEven
        ? const Color(0xFFFFF5E2) : const Color(0xFFFB900D));
      canvas.drawCircle(Offset(left + 10, 56), 9, Paint()
        ..color = i.isEven ? const Color(0xFFFFE6C2) : const Color(0xFFFF9C18));
    }
    final accent = Paint()
      ..color = const Color(0xFF12B16B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(169, 5), const Offset(169, 19), accent);
    canvas.drawLine(const Offset(181, 13), const Offset(191, 5), accent);
    canvas.drawLine(const Offset(187, 26), const Offset(200, 22), accent);
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (busy) const SizedBox(width: 17, height: 17,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else const Icon(Icons.login_rounded, color: Colors.white, size: 21),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
        ),
      ),
    ));
}
