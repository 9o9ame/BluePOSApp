import 'package:flutter/material.dart';

import '../core/appearance.dart';

/// Branded startup presentation while real session initialization is running.
/// Never displays fabricated business data or stalls authentication artificially.
class BlueposSplash extends StatefulWidget {
  const BlueposSplash({super.key, required this.appearance});
  final AppAppearance appearance;

  @override
  State<BlueposSplash> createState() => _BlueposSplashState();
}

class _BlueposSplashState extends State<BlueposSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1250),
    );
    if (widget.appearance.animations) {
      _motion.repeat(reverse: true);
    } else {
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _feature(IconData icon, String label, String detail, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(
        color: accent.withValues(alpha: .11), borderRadius: BorderRadius.circular(13),
      ), child: Icon(icon, color: accent, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        Text(detail, style: const TextStyle(fontSize: 11)),
      ])),
    ]),
  );

  /// Layered POS terminal, receipt printer, scanner and store bag rather
  /// than decorative glyphs. Colors adapt to the active appearance palette.
  Widget _hardwareIllustration(Color accent, ColorScheme scheme) {
    BoxDecoration caseDecoration(double radius, {bool dark = false}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dark ? [
            accent.withValues(alpha: .88),
            accent.withValues(alpha: .54),
          ] : [
            scheme.surface,
            scheme.primaryContainer.withValues(alpha: .85),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: .22)),
        boxShadow: [BoxShadow(
          color: accent.withValues(alpha: .18),
          blurRadius: 18, offset: const Offset(1, 8),
        )],
      );

    return SizedBox(width: 310, height: 180, child: Stack(children: [
      Positioned(left: 22, right: 20, bottom: 8, child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(80),
        ),
      )),
      Positioned(left: 106, bottom: 26, child: Container(
        width: 24, height: 55,
        decoration: caseDecoration(8, dark: true),
      )),
      Positioned(left: 66, bottom: 23, child: Container(
        width: 107, height: 18,
        decoration: caseDecoration(8, dark: true),
      )),
      Positioned(left: 46, top: 13, child: Transform.rotate(
        angle: -.085,
        child: Container(
          width: 146, height: 106, padding: const EdgeInsets.all(9),
          decoration: caseDecoration(17, dark: true),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_checkout_rounded,
                  color: accent, size: 36),
                const SizedBox(height: 1),
                Text('BLUEPOS', style: TextStyle(
                  color: accent, fontSize: 14, letterSpacing: 1.3,
                  fontWeight: FontWeight.w900)),
              ]),
          ),
        ),
      )),
      Positioned(right: 22, top: 51, child: Container(
        width: 72, height: 95, padding: const EdgeInsets.all(8),
        decoration: caseDecoration(13),
        child: Icon(Icons.shopping_bag_outlined,
          color: accent, size: 47),
      )),
      Positioned(left: 12, bottom: 23, child: Container(
        width: 68, height: 59,
        decoration: caseDecoration(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: accent, size: 25),
            Container(width: 39, height: 3,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(3))),
          ]),
      )),
      Positioned(right: 91, bottom: 25, child: Transform.rotate(
        angle: .16,
        child: Container(
          width: 35, height: 55,
          decoration: caseDecoration(9, dark: true),
          child: const Icon(Icons.qr_code_scanner_rounded,
            color: Colors.white, size: 25),
        ),
      )),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.appearance.accent;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [scheme.surface, accent.withValues(alpha: dark ? .22 : .11), scheme.surface],
        )),
        child: SafeArea(child: LayoutBuilder(builder: (context, size) {
          return SingleChildScrollView(child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.maxHeight),
            child: Padding(padding: const EdgeInsets.fromLTRB(27, 28, 27, 26),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Image.asset('assets/branding/bluepos_launcher.png', width: 56, height: 56),
                  const SizedBox(width: 11),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BLUEPOS', style: TextStyle(color: scheme.onSurface,
                      fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1)),
                    const Text('M O B I L E  P O S  &  E R P',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
                  ]),
                ]),
                SizedBox(height: size.maxHeight < 700 ? 24 : 46),
                Text('Run Your Business\nAnywhere',
                  style: TextStyle(fontSize: size.maxWidth < 345 ? 30 : 36,
                    height: 1.08, letterSpacing: -.7, fontWeight: FontWeight.w900)),
                const SizedBox(height: 13),
                Text('A modern POS & ERP for retail, wholesale and multi-store businesses.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35, fontSize: 13)),
                const SizedBox(height: 23),
                _feature(Icons.shopping_cart_outlined, 'Point of Sale', 'Fast, reliable billing', accent),
                _feature(Icons.inventory_2_outlined, 'Inventory', 'Real-time stock management', accent),
                _feature(Icons.bar_chart_rounded, 'Reports & Insights', 'Sales, stock and business performance', accent),
                _feature(Icons.storefront_outlined, 'Multi-Store', 'Manage multiple outlets with ease', accent),
                const SizedBox(height: 18),
                Center(child: AnimatedBuilder(animation: _motion,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, widget.appearance.animations
                      ? (1 - _motion.value) * 9 : 0),
                    child: child,
                  ),
                  child: SizedBox(
                    width: size.maxWidth < 340 ? 250 : 298,
                    height: size.maxHeight < 700 ? 137 : 183,
                    child: FittedBox(fit: BoxFit.contain,
                      child: _hardwareIllustration(accent, scheme)),
                  ),
                )),
                const SizedBox(height: 16),
                Center(child: AnimatedBuilder(animation: _motion, builder: (context, _) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 3; i++) Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CircleAvatar(radius: 3.5 + (_motion.value * (i == 1 ? 2 : 1)),
                        backgroundColor: accent.withValues(alpha: i == 1 ? .95 : .45)),
                    ),
                  ]);
                })),
              ]),
            ),
          ));
        })),
      ),
    );
  }
}
