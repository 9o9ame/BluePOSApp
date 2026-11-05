import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.app});
  final AppController app;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final tenant = TextEditingController();
  final user = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String? challenge;
  String? hint;
  bool remember = true, trust = true, obscure = true, busy = false;
  String? error;

  @override
  void dispose() {
    tenant.dispose(); user.dispose(); password.dispose(); code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (challenge == null && (tenant.text.trim().isEmpty || user.text.trim().isEmpty || password.text.isEmpty)) {
      setState(() => error = 'Please enter mart code, username and password.'); return;
    }
    if (challenge != null && code.text.trim().length != 6) {
      setState(() => error = 'Enter the six-digit verification code.'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (challenge == null) {
        await widget.app.login(tenant.text, user.text, password.text, remember);
      } else {
        await widget.app.verifyMfa(challenge!, code.text.trim(), trust, remember);
      }
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.key == 'MFA_REQUIRED' || ex.key == 'EMAIL_DELIVERY_FAILED') {
        setState(() {
          final value = field(ex.extra['challenge_ulid'], challenge ?? '');
          challenge = value.length == 26 ? value : null;
          hint = field(ex.extra['recovery_hint']);
          code.clear(); password.clear();
          error = ex.key == 'EMAIL_DELIVERY_FAILED' ? ex.message : null;
        });
      } else if (ex.key == 'DEVICE_NOT_APPROVED') {
        final approval = field(ex.extra['approval_status']);
        setState(() => error = approval == 'pending'
            ? 'Device/network approval is pending. Ask the tenant owner to approve it.'
            : 'The tenant owner must approve this device/network. ${ex.message}');
      } else {
        setState(() => error = ex.message);
      }
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (challenge == null || busy) return;
    setState(() { busy = true; error = null; });
    try {
      final extra = await widget.app.resendMfa(challenge!);
      if (mounted) setState(() {
        final next = field(extra['challenge_ulid']);
        if (next.length == 26) challenge = next;
        hint = field(extra['recovery_hint'], hint ?? '');
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget compactInput(TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, TextInputType? keyboard, TextInputAction? action}) => SizedBox(
    height: 39, child: TextField(
      controller: controller,
      textInputAction: action,
      keyboardType: keyboard,
      obscureText: isPassword && obscure,
      onSubmitted: isPassword ? (_) => submit() : null,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: isPassword ? IconButton(iconSize: 18, onPressed: () => setState(() => obscure = !obscure),
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)) : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.app.appearance.accent;
    return Scaffold(body: DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [scheme.surface, scheme.primaryContainer.withValues(alpha: .33), scheme.surface])),
      child: SafeArea(child: LayoutBuilder(builder: (ctx, constraints) {
        final diameter = math.min(math.min(constraints.maxWidth - 18, 450.0),
            math.max(330.0, constraints.maxHeight - 150));
        return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 16),
            Text('BLUEPOS', style: TextStyle(color: accent, fontWeight: FontWeight.w900,
              fontSize: 17, letterSpacing: 4)),
            const SizedBox(height: 6),
            Text('Mobile POS & ERP', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 22),
            Container(width: diameter, height: diameter, padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.white.withValues(alpha: .72),
                  scheme.primaryContainer.withValues(alpha: .5)]),
                border: Border.all(color: scheme.primary.withValues(alpha: .13), width: 2),
                boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .14), blurRadius: 28, offset: const Offset(8, 15)),
                  BoxShadow(color: Colors.white.withValues(alpha: .55), blurRadius: 15, offset: const Offset(-10, -10))]),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: diameter < 355 ? 40 : 52, vertical: 11),
                decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surface.withValues(alpha: .93),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: .5)),
                  boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .05), blurRadius: 22, spreadRadius: -8)]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  BlueposBrandMark(size: challenge == null ? 43 : 55),
                  const SizedBox(height: 3),
                  Text(challenge == null ? 'Welcome Back' : 'Verify Account',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(challenge == null ? 'Sign in to your secure workspace' : 'Enter the recovery code',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 7),
                  if (challenge == null) ...[
                    compactInput(tenant, 'Tenant / Mart code', Icons.storefront_outlined, action: TextInputAction.next),
                    const SizedBox(height: 5),
                    compactInput(user, 'Username', Icons.person_outline_rounded, action: TextInputAction.next),
                    const SizedBox(height: 5),
                    compactInput(password, 'Password', Icons.lock_outline, isPassword: true),
                  ] else ...[
                    compactInput(code, '6-digit code', Icons.verified_user_outlined, keyboard: TextInputType.number),
                    if (hint?.isNotEmpty == true) Text('Recovery hint: $hint', style: const TextStyle(fontSize: 10)),
                    SizedBox(height: 30, child: Row(children: [Checkbox(value: trust, onChanged: busy ? null :
                      (v) => setState(() => trust = v ?? false)), const Expanded(child: Text('Trust this device',
                      style: TextStyle(fontSize: 11)))])),
                  ],
                  SizedBox(height: 25, child: Row(children: [
                    Checkbox(value: remember, onChanged: busy ? null : (v) => setState(() => remember = v ?? false)),
                    const Expanded(child: Text('Remember me', style: TextStyle(fontSize: 10))),
                  ])),
                  const SizedBox(height: 3),
                  SizedBox(height: 40, width: double.infinity, child: FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login, size: 18),
                    label: Text(challenge == null ? 'Login' : 'Verify', style: const TextStyle(fontWeight: FontWeight.w700)),
                  )),
                  if (challenge != null) TextButton(onPressed: busy ? null : resend,
                    child: const Text('Resend code', style: TextStyle(fontSize: 11))),
                ]),
              ),
            ),
            if (error != null) Padding(padding: const EdgeInsets.all(15), child: Text(error!,
              style: TextStyle(color: scheme.error, fontSize: 12), textAlign: TextAlign.center)),
            if (challenge != null) TextButton(onPressed: () => setState(() {
              challenge = null; code.clear(); error = null;
            }), child: const Text('Back to password login')),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.fingerprint_rounded, color: accent, size: 23),
              const SizedBox(width: 6), const Icon(Icons.face_unlock_outlined, size: 23),
              const SizedBox(width: 8),
              Text('Fingerprint / Face Unlock', style: TextStyle(fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant, fontSize: 13)),
            ]),
            const SizedBox(height: 5),
            Text('Enable after your first approved login in Settings.',
              textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 15),
            const Text('Protected by BluePOS device approval, MFA and encrypted session storage.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
            const SizedBox(height: 20),
          ]),
        ));
      })),
    ));
  }
}
