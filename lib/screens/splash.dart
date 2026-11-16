import 'package:flutter/material.dart';

import '../core/appearance.dart';
import 'auth_reference_chrome.dart';

/// Screen 01 reference-aligned splash, displayed only while the real
/// authentication session initializes. No artificial startup delay.
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
      vsync: this, duration: const Duration(milliseconds: 1100));
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(child: LayoutBuilder(builder: (context, dimensions) =>
        Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0,
            child: AuthReferenceWaves(height: 128)),
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const AuthReferenceBrand(horizontal: false, iconSize: 76),
              const SizedBox(height: 39),
              AnimatedBuilder(
                animation: _motion,
                builder: (context, child) => Row(
                  key: const ValueKey('splash-loading-dots'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CircleAvatar(radius: i == 1
                            ? 4.2 + _motion.value * 1.5 : 3.3,
                          backgroundColor: i == 1
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: .3))),
                  ],
                ),
              ),
              const SizedBox(height: 42),
              Text('Complete Business Management',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                  color: scheme.onSurfaceVariant)),
            ]),
          )),
        ]),
      )),
    );
  }
}
