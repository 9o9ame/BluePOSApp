import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';

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
  bool remember = true;
  bool trust = true;
  bool obscure = true;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    tenant.dispose(); user.dispose(); password.dispose(); code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (challenge == null && (tenant.text.trim().isEmpty || user.text.trim().isEmpty || password.text.isEmpty)) {
      setState(() => error = 'Enter tenant code, username and password.'); return;
    }
    if (challenge != null && code.text.trim().length != 6) {
      setState(() => error = 'Enter the 6-digit verification code.'); return;
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
          challenge = field(ex.extra['challenge_ulid'], challenge ?? '');
          if (challenge!.isEmpty) challenge = null;
          hint = field(ex.extra['recovery_hint']);
          code.clear(); password.clear();
          error = ex.key == 'EMAIL_DELIVERY_FAILED' ? ex.message : null;
        });
      } else if (ex.key == 'DEVICE_NOT_APPROVED') {
        final approval = field(ex.extra['approval_status']);
        setState(() => error = approval == 'pending'
            ? 'Device/network approval is pending. Ask the tenant owner to approve, then log in again.'
            : 'This device/network needs tenant owner approval. ${ex.message}');
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.app.appearance.accent;
    return Scaffold(body: SafeArea(child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 12),
            SizedBox(height: 144, width: 144, child: Stack(alignment: Alignment.center, children: [
              Container(width: 144, height: 144, decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.26), width: 2))),
              Container(width: 119, height: 119, decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent, Color.lerp(accent, const Color(0xFF08183F), 0.5)!]),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.27), blurRadius: 35, spreadRadius: 5)]),
                child: const Icon(Icons.shopping_cart_checkout_rounded, size: 58, color: Colors.white)),
              Positioned(top: 10, right: 5, child: CircleAvatar(radius: 10, backgroundColor: scheme.surface,
                  child: Icon(Icons.circle, size: 11, color: accent))),
              Positioned(bottom: 12, left: 2, child: CircleAvatar(radius: 8, backgroundColor: scheme.surface,
                  child: Icon(Icons.circle, size: 9, color: accent.withValues(alpha: .65)))),
            ])),
            const SizedBox(height: 18),
            Text('BluePOS', style: TextStyle(fontSize: 33, fontWeight: FontWeight.w900,
              color: scheme.onSurface, letterSpacing: -1.3)),
            Text(challenge == null ? 'One workspace. A clearer way to work.' : 'Secure verification',
              textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(widget.app.appearance.corner + 8),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: .08), blurRadius: 35, offset: const Offset(0, 15))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(challenge == null ? 'Welcome back' : 'Verify your account',
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(challenge == null ? 'Sign in to your authorized business.'
                      : 'Enter your 6-digit recovery code${hint == null || hint!.isEmpty ? '' : ' ($hint)'}.',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 22),
                if (challenge == null) ...[
                  TextField(controller: tenant, textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Tenant / Mart code', prefixIcon: Icon(Icons.storefront_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: user, textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: obscure,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                ] else ...[
                  TextField(controller: code, textAlign: TextAlign.center,
                    keyboardType: TextInputType.number, maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Verification code', prefixIcon: Icon(Icons.verified_user_outlined))),
                  CheckboxListTile(value: trust, contentPadding: EdgeInsets.zero, title: const Text('Trust this device'),
                    controlAffinity: ListTileControlAffinity.leading, onChanged: (value) => setState(() => trust = value ?? false)),
                ],
                Row(children: [
                  Checkbox(value: remember, onChanged: (v) => setState(() => remember = v ?? false)),
                  const Text('Remember me', style: TextStyle(fontSize: 13)),
                ]),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error!, style: TextStyle(color: scheme.error, fontSize: 12)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                FilledButton(onPressed: busy ? null : submit,
                  child: busy ? const SizedBox(width: 20, height: 20,
                     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                     : Text(challenge == null ? 'Secure Login' : 'Verify & Continue')),
                if (challenge != null) ...[
                  TextButton(onPressed: busy ? null : resend, child: const Text('Resend verification code')),
                  TextButton(onPressed: () => setState(() { challenge = null; code.clear(); error = null; }),
                    child: const Text('Back to sign in')),
                ],
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shield_outlined, color: scheme.onSurfaceVariant, size: 16),
              const SizedBox(width: 5),
              Text('Secure access • Device approval • Location verified',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    )));
  }
}
