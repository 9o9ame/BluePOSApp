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
