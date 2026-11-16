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

  Widget _recoveryField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color tone,
    required Color plate,
    required String keyName,
    bool enabled = true,
    bool obscure = false,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0F3FF)]),
        border: Border.all(color: Colors.white, width: 1.7),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(
          color: Color(0x295D78B8), blurRadius: 13,
          offset: Offset(0, 6))],
      ),
      child: TextField(
        key: ValueKey(keyName),
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14,
          color: Color(0xFF16274D)),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14,
            color: Color(0xFF445371)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 16),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 75, minHeight: 50),
          prefixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 8),
            Container(width: 35, height: 35,
              decoration: BoxDecoration(
                color: plate, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 21, color: tone)),
            const SizedBox(width: 11),
            Container(width: 1.3, height: 24,
              color: const Color(0xFFB9C5DD)),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).height < 730;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Stack(children: [
        const Positioned.fill(child: LoginReferenceBackground()),
        SafeArea(child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back to Login',
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF071947)),
            ),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
            children: [
              const Center(child: LoginReferenceBrand()),
              SizedBox(height: compact ? 18 : 28),
              const Center(child: _RecoveryLockArt()),
              SizedBox(height: compact ? 16 : 20),
              Text(requested ? 'Reset Password' : 'Forgot Password',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: Color(0xFF081943))),
              const SizedBox(height: 5),
              Text(requested
                  ? 'Enter your reset code and choose a new password.'
                  : 'Recover access to your business account',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13, color: Color(0xFF52617D))),
              SizedBox(height: compact ? 22 : 30),
              _recoveryField(
                keyName: 'recovery-tenant', controller: tenant,
                enabled: !busy && !requested,
                label: 'Tenant / Mart Code',
                icon: Icons.storefront_outlined,
                tone: const Color(0xFF0B78F6),
                plate: const Color(0xFFE3F0FF)),
              const SizedBox(height: 12),
              _recoveryField(
                keyName: 'recovery-username', controller: username,
                enabled: !busy && !requested,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                tone: const Color(0xFF1767CE),
                plate: const Color(0xFFEAF2FF)),
              if (requested) ...[
                const SizedBox(height: 12),
                _recoveryField(
                  keyName: 'recovery-token', controller: token,
                  label: 'Reset code', icon: Icons.pin_outlined,
                  tone: const Color(0xFF0B78F6),
                  plate: const Color(0xFFE3F0FF)),
                const SizedBox(height: 12),
                _recoveryField(
                  keyName: 'recovery-password', controller: password,
                  label: 'New password', icon: Icons.lock_outline,
                  tone: const Color(0xFF0B78F6),
                  plate: const Color(0xFFE3F0FF), obscure: true),
                const SizedBox(height: 12),
                _recoveryField(
                  keyName: 'recovery-confirmation',
                  controller: confirmation,
                  label: 'Confirm new password',
                  icon: Icons.lock_outline,
                  tone: const Color(0xFF0B78F6),
                  plate: const Color(0xFFE3F0FF), obscure: true),
              ],
              if (!requested) ...[
                const SizedBox(height: 16),
                Container(
                  key: const ValueKey('recovery-information'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFDAE5FB))),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded,
                      size: 21, color: Color(0xFF2A64B1)),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'If the account is eligible, follow the recovery instructions sent through its configured channel.',
                      style: TextStyle(
                        fontSize: 11.5, color: Color(0xFF354969)),
                    )),
                  ]),
                ),
              ],
              if (feedback != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(feedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.error, fontSize: 12))),
              const SizedBox(height: 22),
              LoginReferenceGradientButton(
                key: const ValueKey('recovery-submit'),
                onPressed: busy ? null : submit,
                busy: busy,
                label: requested ? 'Reset Password' : 'Send Reset Link'),
              const SizedBox(height: 11),
              Center(child: TextButton.icon(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
                label: const Text('Back to Login',
                  style: TextStyle(fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF081943)),
              )),
            ],
          )),
        ])),
      ]),
    );
  }
}

/// Large layered lock and mint reset badge from the reference layout.
/// Purely visual; never represents authentication or recovery success.
class _RecoveryLockArt extends StatelessWidget {
  const _RecoveryLockArt();

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('recovery-lock-art'),
    width: 104, height: 104,
    child: Stack(alignment: Alignment.center, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F8FF), Color(0xFFD8FFF1)])),
      ),
      Container(
        width: 56, height: 65,
        alignment: Alignment.center,
        child: const Icon(Icons.lock_rounded,
          size: 57, color: Color(0xFF078FF9)),
      ),
      Positioned(
        bottom: 12, right: 5,
        child: Container(
          width: 35, height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEBFFF5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white, width: 2)),
          child: const Icon(Icons.sync_rounded,
            size: 25, color: Color(0xFF0CB971)),
        ),
      ),
    ]),
  );
}
