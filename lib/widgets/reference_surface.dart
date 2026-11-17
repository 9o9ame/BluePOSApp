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

/// Shared geometry for reference screens. Change sizes here, not per form.
abstract final class BpReferenceMetrics {
  static const double fieldVerticalPadding = 7;
  static const double fieldHorizontalPadding = 10;
  static const double fieldTileVerticalPadding = 5;
  static const double fieldIconSize = 33;
  static const double formRowGap = 4;
  static const double actionHeight = 43;
  static const double actionRadius = 13;
  static const double actionBarPadding = 9;
}

/// Consistent compact field tile for add/edit reference screens.
class BpReferenceFormField extends StatelessWidget {
  const BpReferenceFormField({
    super.key, required this.label, required this.hint, required this.icon,
    this.controller, this.readOnly = false, this.maxLines = 1,
    this.maxLength, this.keyboardType, this.suffixIcon, this.child,
    this.fieldKey,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final Key? fieldKey;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: BpReferenceMetrics.formRowGap),
      padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: BpReferenceMetrics.fieldTileVerticalPadding),
      decoration: style.card(radius: 13),
      child: Row(children: [
        Container(
          width: BpReferenceMetrics.fieldIconSize,
          height: BpReferenceMetrics.fieldIconSize + 4,
          decoration: BoxDecoration(
            color: style.scheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 19, color: style.scheme.primary)),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w900,
              color: style.ink)),
            const SizedBox(height: 2),
            child ?? TextField(
              key: fieldKey,
              controller: controller,
              readOnly: readOnly,
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: style.search(hint).copyWith(
                isDense: true, counterText: '',
                suffixIcon: suffixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BpReferenceMetrics.fieldHorizontalPadding,
                  vertical: BpReferenceMetrics.fieldVerticalPadding))),
          ],
        )),
      ]),
    );
  }
}

/// Dense reference tile for invoice/return two-column metadata.
/// Inputs remain caller-controlled; never infer finance values here.
class BpReferenceCompactField extends StatelessWidget {
  const BpReferenceCompactField({
    super.key, required this.label, required this.icon, this.hint = '',
    this.controller, this.onTap, this.value, this.readOnly = false,
    this.keyboardType, this.fieldKey,
  });

  final String label;
  final IconData icon;
  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final String? value;
  final bool readOnly;
  final TextInputType? keyboardType;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    final disabled = readOnly || (controller == null && onTap == null);
    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: style.card(radius: 12),
      child: Row(children: [
        Container(
          width: 27, height: 29,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: style.scheme.primary.withValues(alpha: .10)),
          child: Icon(icon, size: 17, color: style.scheme.primary)),
        const SizedBox(width: 6),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.ink, fontSize: 9,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            if (controller != null)
              SizedBox(height: 27, child: TextField(
                key: fieldKey,
                controller: controller,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: 1,
                style: TextStyle(fontSize: 11, color: style.ink),
                decoration: style.search(hint).copyWith(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4)),
              ))
            else InkWell(
              onTap: disabled ? null : onTap,
              borderRadius: BorderRadius.circular(7),
              child: Row(children: [
                Expanded(child: Text(value?.isNotEmpty == true
                    ? value! : hint,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5,
                    color: value?.isNotEmpty == true
                      ? style.ink : style.muted))),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                    size: 14, color: style.muted),
              ]),
            ),
          ],
        )),
      ]),
    );
  }
}

/// Shared small, single-line bottom actions; Wave stays outside content.
class BpReferenceFooter extends StatelessWidget {
  const BpReferenceFooter({
    super.key, required this.saveLabel, required this.onCancel,
    this.onSave, this.saving = false, this.saveKey,
  });
  final Key? saveKey;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const BpReferenceFooterWave(),
      SafeArea(top: false, child: Container(
        padding: const EdgeInsets.all(BpReferenceMetrics.actionBarPadding),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(18)),
          border: Border.all(color: style.line)),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: saving ? null : onCancel,
            child: const Text('Cancel', maxLines: 1))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(
            key: saveKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              backgroundColor: const Color(0xFF006DF6),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: saving ? null : onSave,
            icon: saving
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 16),
            label: FittedBox(fit: BoxFit.scaleDown,
              child: Text(saving ? 'Saving…' : saveLabel,
                maxLines: 1, softWrap: false)),
          )),
        ]),
      )),
    ]);
  }
}

/// Footer wave is isolated from the form's scrollable body.
class BpReferenceFooterWave extends StatelessWidget {
  const BpReferenceFooterWave({super.key});

  @override
  Widget build(BuildContext context) {
    // The existing AuthReferenceWaves is imported by screens, not by this
    // generic styling component. A lightweight decorative strip is shared.
    return Container(height: 12, decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [
        Color(0xFF76DEEF), Color(0xFF7FF2C6)])));
  }
}

/// Reusable compact Active/Inactive selector for server-backed forms.
class BpReferenceStatusSelector extends StatelessWidget {
  const BpReferenceStatusSelector({
    super.key, required this.active, required this.onChanged,
    this.enabled = true,
  });

  final bool active;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Row(children: [
      for (final value in [true, false]) ...[
        if (!value) const SizedBox(width: 7),
        Expanded(child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged(value) : null,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: active == value
                  ? const Color(0xFFDCF8E6) : style.surface,
                border: Border.all(
                  color: active == value
                    ? const Color(0xFF87DCAD) : style.line)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active == value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: active == value
                      ? const Color(0xFF11974C) : style.muted),
                  const SizedBox(width: 4),
                  Text(value ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: 11,
                      color: active == value
                        ? const Color(0xFF176337) : style.ink,
                      fontWeight: FontWeight.w800)),
                ]),
            ),
          ),
        )),
      ],
    ]);
  }
}

/// Shared compact two-action footer for safe draft/save/post workflows.
/// Callers own authorization, confirmation, idempotency and server posting.
class BpReferenceWorkflowActions extends StatelessWidget {
  const BpReferenceWorkflowActions({
    super.key,
    required this.leftLabel, required this.rightLabel,
    this.onLeft, this.onRight,
    this.leftIcon = Icons.save_outlined,
    this.rightIcon = Icons.verified_outlined,
    this.leftKey, this.rightKey,
  });
  final String leftLabel;
  final String rightLabel;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final Key? leftKey;
  final Key? rightKey;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const BpReferenceFooterWave(),
      SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 10),
        decoration: BoxDecoration(color: style.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(19)),
          border: Border.all(color: style.line)),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(
            key: leftKey,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: onLeft, icon: Icon(leftIcon, size: 17),
            label: FittedBox(fit: BoxFit.scaleDown,
              child: Text(leftLabel, softWrap: false, maxLines: 1)),
          )),
          const SizedBox(width: 7),
          Expanded(child: FilledButton.icon(
            key: rightKey,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF05B74D),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: onRight, icon: Icon(rightIcon, size: 17),
            label: FittedBox(fit: BoxFit.scaleDown,
              child: Text(rightLabel, softWrap: false, maxLines: 1)),
          )),
        ]),
      )),
    ]);
  }
}

/// Shared bottom detail actions for customers and suppliers.
/// These are navigation actions only: no client-authoritative ledger mutation.
class BpReferenceDetailActions extends StatelessWidget {
  const BpReferenceDetailActions({
    super.key, required this.onViewLedger, this.onEdit,
    this.editKey, this.ledgerKey,
  });
  final VoidCallback? onEdit;
  final VoidCallback onViewLedger;
  final Key? editKey;
  final Key? ledgerKey;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const BpReferenceFooterWave(),
      SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 11, 11),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
          border: Border.all(color: style.line),
          boxShadow: [BoxShadow(
            color: style.shadow, blurRadius: 12,
            offset: const Offset(0, -3))]),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(
            key: editKey,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit', maxLines: 1),
          )),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(
            key: ledgerKey,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF006DF6),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, BpReferenceMetrics.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.circular(BpReferenceMetrics.actionRadius))),
            onPressed: onViewLedger,
            icon: const Icon(Icons.layers_outlined, size: 18),
            label: const FittedBox(fit: BoxFit.scaleDown,
              child: Text('View Ledger', maxLines: 1, softWrap: false)),
          )),
        ]),
      )),
    ]);
  }
}

/// Consistent two-column detail rows used by Customer/Supplier screens.
class BpReferenceDetailLine extends StatelessWidget {
  const BpReferenceDetailLine({
    super.key, required this.label, required this.value, required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(children: [
        Container(
          width: 29, height: 29,
          decoration: BoxDecoration(
            color: style.scheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 17, color: style.scheme.primary)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800, color: style.ink))),
        const SizedBox(width: 8),
        Flexible(child: Text(value.trim().isEmpty ? 'Not available' : value,
          maxLines: 2, textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: style.ink))),
      ]),
    );
  }
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
