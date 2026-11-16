import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'login_reference_visual.dart';

/// Screen 05. Uses the verified public tenant-scoped reset endpoints.
/// Does not assume email is the login identifier or reveal account existence.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.app,
    this.initialTenant = '', this.initialUsername = ''});
  final AppController app;
  final String initialTenant;
  final String initialUsername;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  late final TextEditingController tenant;
  late final TextEditingController username;
  final token = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool requested = false;
  bool busy = false;
  String? feedback;

  @override
  void initState() {
    super.initState();
    tenant = TextEditingController(text: widget.initialTenant);
    username = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    tenant.dispose();
    username.dispose();
    token.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final t = tenant.text.trim();
    final u = username.text.trim();
    if (busy) return;
    if (t.isEmpty || u.isEmpty) {
      setState(() => feedback = 'Tenant code and username are required.');
      return;
    }
    if (requested && (token.text.trim().isEmpty ||
        password.text.length < 8 ||
        password.text != confirmation.text)) {
      setState(() => feedback =
        'Enter a valid reset code and matching passwords (at least 8 characters).');
      return;
    }
    setState(() { busy = true; feedback = null; });
    try {
      if (!requested) {
        await widget.app.api.post('/api/forgot-password',
          {'tenant_code': t, 'username': u});
        if (!mounted) return;
        setState(() {
          requested = true;
          feedback = 'If the account is eligible, follow the reset instructions you receive.';
        });
      } else {
        await widget.app.api.post('/api/reset-password', {
          'tenant_code': t, 'username': u,
          'token': token.text.trim(),
          'password': password.text,
          'password_confirmation': confirmation.text,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset request completed.')));
        Navigator.of(context).pop();
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => feedback = e.message);
    } catch (_) {
      if (mounted) setState(() => feedback = 'Unable to complete request. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _recoveryField({required Widget child}) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Colors.white, Color(0xFFEEF2FF)]),
      border: Border.all(color: Colors.white, width: 1.8),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [BoxShadow(color: Color(0x305D78B8),
        blurRadius: 12, offset: Offset(0, 6))],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(backgroundColor: const Color(0xFFF7F8FF), title: const Text('')),
      body: SafeArea(child: Stack(children: [
        const Positioned.fill(child: LoginReferenceBackground()),
        ListView(padding: const EdgeInsets.symmetric(horizontal: 23),
          children: [
            const Center(child: LoginReferenceBrand()),
            const SizedBox(height: 24),
            Center(child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFDEFFF9), Color(0xFFDEF0FF)]),
                borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.lock_reset_rounded,
                color: Color(0xFF0872F6), size: 42))),
            const SizedBox(height: 18),
            Text(requested ? 'Reset Password' : 'Forgot Password',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(requested
              ? 'Enter your reset code and choose a new password.'
              : 'Recover access to your business account',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 22),
            _recoveryField(child: TextField(key: const ValueKey('recovery-tenant'),
              controller: tenant, enabled: !busy && !requested,
              decoration: const InputDecoration(
                labelText: 'Tenant / Mart Code',
                prefixIcon: Icon(Icons.storefront_outlined)))),
            const SizedBox(height: 12),
            _recoveryField(child: TextField(key: const ValueKey('recovery-username'),
              controller: username, enabled: !busy && !requested,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded)))),
            if (requested) ...[
              const SizedBox(height: 12),
              TextField(controller: token,
                key: const ValueKey('recovery-token'),
                decoration: const InputDecoration(
                  labelText: 'Reset code',
                  prefixIcon: Icon(Icons.pin_outlined))),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true,
                key: const ValueKey('recovery-password'),
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              TextField(controller: confirmation, obscureText: true,
                key: const ValueKey('recovery-confirmation'),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_outline))),
            ],
            if (feedback != null) Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(feedback!,
                style: TextStyle(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center)),
            const SizedBox(height: 22),
            LoginReferenceGradientButton(
              key: const ValueKey('recovery-submit'),
              onPressed: busy ? null : submit,
              busy: busy,
              label: requested ? 'Reset Password' : 'Send Reset Link'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Login')),
            const SizedBox(height: 120),
          ]),
      ])),
    );
  }
}
