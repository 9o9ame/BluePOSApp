import 'package:flutter/material.dart';

/// Shared reference-inspired chrome for Screens 01, 02 and verification.
/// Adapt colors to the user's selected Theme & Appearance rather than
/// hard-coding the illustrative cyan/blue/green screenshot colors.
/// Reference blue/mint decorative footer used by Screens 08–10.
/// Does not intercept touches and cannot replace module/navigation UI.
class AuthReferenceWaves extends StatelessWidget {
  const AuthReferenceWaves({super.key, this.height = 112});
  final double height;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(height: height, width: double.infinity,
      child: const CustomPaint(painter: _WavePainter())));
}

class _WavePainter extends CustomPainter {
  const _WavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rear = Path()
      ..moveTo(0, h * .40)
      ..cubicTo(w * .31, h * .35, w * .39, h * .85, w * .63, h * .62)
      ..cubicTo(w * .84, h * .40, w * .92, h * .28, w, h * .35)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(rear, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF91EDFA), Color(0xFF59EADC),
        Color(0xFFA2F5CE)]).createShader(Offset.zero & size));
    final front = Path()
      ..moveTo(0, h * .71)
      ..cubicTo(w * .29, h * .93, w * .57, h * .31, w, h * .44)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(front, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF59DDF8), Color(0xFF56E9DB),
        Color(0xFFADF9C7)]).createShader(Offset.zero & size));
  }
  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}

class AuthReferenceBrand extends StatelessWidget {
  const AuthReferenceBrand({super.key, this.iconSize = 49, this.horizontal = true});
  final double iconSize;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wordmark = Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text('BluePOS', style: TextStyle(color: scheme.primary,
          fontSize: horizontal ? 23 : 32,
          fontWeight: FontWeight.w900, letterSpacing: -.7)),
        Text('P O S  &  E R P', style: TextStyle(
          color: scheme.onSurfaceVariant, fontSize: horizontal ? 8 : 11,
          letterSpacing: 1.0, fontWeight: FontWeight.w700)),
      ],
    );
    final mark = Image.asset('assets/branding/bluepos_launcher.png',
      width: iconSize, height: iconSize);
    return horizontal
      ? Row(mainAxisSize: MainAxisSize.min, children: [
          mark, const SizedBox(width: 9), wordmark,
        ])
      : Column(mainAxisSize: MainAxisSize.min, children: [
          mark, const SizedBox(height: 10), wordmark,
        ]);
  }
}
