import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../core/appearance.dart';

String money(dynamic amount, [String prefix = 'Rs']) {
  final n = Decimal.tryParse((amount ?? '0').toString());
  if (n == null) return '$prefix —';
  final s = n.toStringAsFixed(2);
  final pieces = s.split('.');
  final whole = pieces[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final offset = whole.length - i;
    buffer.write(whole[i]);
    if (offset > 1 && offset % 3 == 1) buffer.write(',');
  }
  return '$prefix ${buffer.toString()}.${pieces[1]}';
}

String decimalString(dynamic n) => n?.toString() ?? '0';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ]),
      );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(padding: padding, child: child),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.subtitle, this.icon = Icons.inbox_outlined});
  final String title;
  final String? subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: color)),
        ],
      ],
    )));
  }
}

class FailureState extends StatelessWidget {
  const FailureState({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 42),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
    ]),
  ));
}

class GradientHero extends StatelessWidget {
  const GradientHero({super.key, required this.appearance, required this.child});
  final AppAppearance appearance;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [appearance.accent,
            Color.lerp(appearance.accent, const Color(0xFF050E2B), 0.45)!],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(appearance.corner + 8),
        ),
        child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
      );
}

Future<void> showApiError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error.toString()), behavior: SnackBarBehavior.floating,
  ));
}

Widget pageLoading() => const Center(child: CircularProgressIndicator());


/// Identical brand mark across Login, Workspace, Receipts and Android launcher.
class BlueposBrandMark extends StatelessWidget {
  const BlueposBrandMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .23),
    child: Image.asset('assets/branding/bluepos_launcher.png',
      width: size, height: size, fit: BoxFit.cover),
  );
}

class BpModuleTile extends StatelessWidget {
  const BpModuleTile({super.key, required this.icon, required this.name,
    required this.onTap, this.tint});
  final IconData icon;
  final String name;
  final VoidCallback onTap;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = tint ?? scheme.primary;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Surface(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(
            color: accent.withValues(alpha: .11), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 25, color: accent)),
          const SizedBox(height: 10),
          Text(name, maxLines: 2, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ])),
    );
  }
}

class BpStatCard extends StatelessWidget {
  const BpStatCard({super.key, required this.icon, required this.caption,
    required this.value, this.hint});
  final IconData icon;
  final String caption, value;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 21, color: scheme.primary), const Spacer(),
        Icon(Icons.arrow_outward, size: 14, color: scheme.onSurfaceVariant)]),
      const SizedBox(height: 11),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21))),
      const SizedBox(height: 4),
      Text(caption, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      if (hint != null) Text(hint!, style: TextStyle(fontSize: 10,
        color: scheme.onSurfaceVariant), maxLines: 2),
    ]));
  }
}
