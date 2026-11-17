import 'package:flutter/material.dart';

/// Shared mobile reference navigation. The raised center action is a real
/// barcode scanner; it never impersonates the product catalog tab.
class BlueposReferenceNav extends StatelessWidget {
  const BlueposReferenceNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onScan,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget destination(int index, IconData icon, String label) {
      final selected = selectedIndex == index;
      return Expanded(child: InkWell(
        key: ValueKey('reference-nav-$label'),
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 37, width: 54,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDDF8E8) : Colors.transparent,
                borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, size: 26,
                color: selected
                  ? const Color(0xFF00985F)
                  : const Color(0xFF10234C))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              color: selected
                ? const Color(0xFF008C54)
                : const Color(0xFF111E40))),
          ]),
      ));
    }
    return SafeArea(top: false, child: Container(
      height: 77,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(
          color: scheme.shadow.withValues(alpha: .12),
          blurRadius: 18, offset: const Offset(0, -6))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        destination(0, Icons.home_outlined, 'Home'),
        destination(1, Icons.shopping_cart_outlined, 'POS'),
        Expanded(child: Center(child: Transform.translate(
          offset: const Offset(0, -17),
          child: Material(
            elevation: 8,
            shadowColor: const Color(0x6600AD75),
            shape: const CircleBorder(),
            color: const Color(0xFF04B05F),
            child: InkWell(
              key: const ValueKey('reference-nav-scan'),
              customBorder: const CircleBorder(),
              onTap: onScan,
              child: Container(
                width: 65, height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11CF70), Color(0xFF009748)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 32)),
            ),
          ),
        ))),
        destination(3, Icons.bar_chart_outlined, 'Reports'),
        destination(4, Icons.more_horiz_rounded, 'More'),
      ]),
    ));
  }
}
