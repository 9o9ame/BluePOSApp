import 'package:flutter/material.dart';

/// Shared reference-inspired chrome for Screens 01, 02 and verification.
/// Adapt colors to the user's selected Theme & Appearance rather than
/// hard-coding the illustrative cyan/blue/green screenshot colors.
class AuthReferenceWaves extends StatelessWidget {
  const AuthReferenceWaves({super.key, this.height = 112});
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter(
        scheme.primary.withValues(alpha: .18),
        scheme.tertiary.withValues(alpha: .22))),
    ));
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.first, this.second);
  final Color first, second;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lower = Path()
      ..moveTo(0, h * .58)
      ..cubicTo(w * .32, h * .43, w * .67, h * .94, w, h * .37)
      ..lineTo(w, h)..lineTo(0, h)..close();
    final upper = Path()
      ..moveTo(0, h * .49)
      ..cubicTo(w * .27, h * .75, w * .63, h * .34, w, h * .78)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(lower, Paint()..color = second);
    canvas.drawPath(upper, Paint()..color = first);
  }
  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      first != old.first || second != old.second;
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
