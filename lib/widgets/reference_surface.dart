import 'package:flutter/material.dart';

/// Theme-aware palette for mobile reference screens 11–15.
/// The user's Settings > Theme selection remains the source of truth.
class BpReferenceStyle {
  BpReferenceStyle.of(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark,
        scheme = Theme.of(context).colorScheme;

  final bool dark;
  final ColorScheme scheme;

  Color get page => dark ? const Color(0xFF101827) : const Color(0xFFF7F9FF);
  Color get surface => dark ? const Color(0xFF1A2741) : Colors.white;
  Color get surfaceEnd => dark ? const Color(0xFF202E4C) : const Color(0xFFF0F4FF);
  Color get ink => dark ? const Color(0xFFF3F6FF) : const Color(0xFF0B1C44);
  Color get muted => dark ? const Color(0xFFB5C3DD) : const Color(0xFF657492);
  Color get line => dark ? const Color(0xFF344563) : const Color(0xFFDDE5F6);
  Color get input => dark ? const Color(0xFF25334F) : const Color(0xFFF9FAFF);
  Color get shadow => dark ? const Color(0x33000000) : const Color(0x205776B4);
  Color get green => dark ? const Color(0xFF3CDE8F) : const Color(0xFF07944C);

  BoxDecoration card({double radius = 16}) => BoxDecoration(
    gradient: LinearGradient(colors: [surface, surfaceEnd]),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: line.withValues(alpha: .70)),
    boxShadow: [BoxShadow(
      color: shadow, blurRadius: 12, offset: const Offset(0, 5))],
  );

  InputDecoration search(String hint, {Widget? prefixIcon}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: input,
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: scheme.primary, width: 1.4)),
    );
}

/// Two-tier header from the approved mobile reference. The secondary bar
/// keeps the back action and title while the top brand remains consistent.
class BpReferenceSubpageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BpReferenceSubpageAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onNotifications,
    this.onSearch,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onNotifications;
  final VoidCallback? onSearch;

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return AppBar(
      backgroundColor: style.page,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 112,
      titleSpacing: 0,
      title: Column(children: [
        SizedBox(
          height: 58,
          child: Stack(alignment: Alignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/branding/bluepos_launcher.png',
                  width: 39, height: 39)),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Blue',
                      style: TextStyle(color: style.ink)),
                    TextSpan(text: 'POS',
                      style: TextStyle(color: style.scheme.primary)),
                  ]), style: const TextStyle(
                    fontSize: 23, fontWeight: FontWeight.w900)),
                  Text('P O S  &  E R P', style: TextStyle(
                    fontSize: 8, color: style.muted,
                    fontWeight: FontWeight.w800)),
                ],
              ),
            ]),
            if (onNotifications != null)
              Positioned(right: 8,
                child: IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_rounded,
                    color: style.ink),
                  onPressed: onNotifications)),
          ]),
        ),
        SizedBox(height: 54, child: Row(children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: style.ink),
            onPressed: onBack ?? () => Navigator.of(context).maybePop()),
          Expanded(child: Text(title, textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: style.ink, fontSize: 21,
              fontWeight: FontWeight.w900))),
          if (onSearch != null)
            IconButton(
              tooltip: 'Search',
              icon: Icon(Icons.search_rounded, color: style.ink),
              onPressed: onSearch)
          else
            const SizedBox(width: 48),
        ])),
      ]),
    );
  }
}

/// Decorative upper-right swoosh from the approved light reference.
/// It stays behind content and darkens with the selected theme.
class BpReferenceTopAccent extends StatelessWidget {
  const BpReferenceTopAccent({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(child: SizedBox(
      width: 200, height: 96,
      child: CustomPaint(painter: _BpReferenceTopPainter(dark))));
  }
}

class _BpReferenceTopPainter extends CustomPainter {
  const _BpReferenceTopPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..cubicTo(size.width * .68, size.height * .63,
        size.width * .48, size.height * .96, 0, size.height * .92)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight, end: Alignment.bottomLeft,
        colors: dark
          ? [const Color(0xFF263C65), const Color(0xFF182C4A)]
          : [const Color(0xFFE8F2FF), const Color(0xFFCFDFFF)],
      ).createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(covariant _BpReferenceTopPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
