import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/saved_accounts.dart';
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
  String? error;
  bool remember = true;
  bool trust = true;
  bool obscure = true;
  bool busy = false;
  bool biometricConfigured = false;
  bool _automaticBiometricPrompted = false;
  bool _accountSheetOpen = false;
  List<SavedLoginAccount> savedLogins = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocalLoginOptions());
  }

  Future<void> _loadLocalLoginOptions() async {
    final logins = await widget.app.savedAccounts.list();
    final owner = await widget.app.biometric.savedOwner();
    final hardware = await widget.app.biometric.available();
    if (!mounted) return;
    final enabled = owner != null && hardware &&
        widget.app.api.hasSavedSessionCookies;
    setState(() {
      savedLogins = logins;
      biometricConfigured = enabled;
    });

    // The user sees the login screen before Android displays its OS prompt.
    // Never launch an automatic second prompt after cancellation.
    if (enabled && widget.app.authenticated && widget.app.locked &&
        !_automaticBiometricPrompted) {
      _automaticBiometricPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) biometricLogin(automatic: true);
      });
    }
  }

  Future<void> biometricLogin({bool automatic = false}) async {
    if (busy) return;
    if (!biometricConfigured) {
      if (!automatic && mounted) {
        setState(() => error = 'Sign in first to enable biometrics.');
      }
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ok = await widget.app.biometricSignIn();
      if (!ok && !automatic && mounted) {
        setState(() => error = 'Unable to unlock. Sign in with password.');
      }
    } on ApiFailure catch (ex) {
      if (mounted) setState(() => error = ex.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Biometric unlock failed. Sign in with password.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openSavedLogins() async {
    if (_accountSheetOpen || savedLogins.isEmpty || busy || challenge != null) {
      return;
    }
    _accountSheetOpen = true;
    var choices = savedLogins;
    try {
      final choice = await showModalBottomSheet<SavedLoginAccount>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, updateSheet) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              left: 18, right: 18,
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Saved accounts',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                const SizedBox(height: 4),
                Text('Select an account. Passwords are not stored.',
                  style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * .47),
                  child: ListView(shrinkWrap: true,
                    children: choices.map((account) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text((account.displayName.isNotEmpty
                          ? account.displayName : account.username)
                          .substring(0, 1).toUpperCase())),
                      title: Text(account.displayName.isNotEmpty
                        ? account.displayName : account.username,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${account.martCode}  •  ${account.username}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        tooltip: 'Forget saved account',
                        onPressed: () async {
                          await widget.app.savedAccounts.forget(account);
                          final remaining = await widget.app.savedAccounts.list();
                          if (!mounted || !sheetContext.mounted) return;
                          setState(() => savedLogins = remaining);
                          updateSheet(() => choices = remaining);
                          if (remaining.isEmpty) Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close_rounded)),
                      onTap: () => Navigator.pop(sheetContext, account),
                    )).toList(),
                  ),
                ),
              ]),
          ),
        ),
      );
      if (choice != null && mounted) {
        setState(() {
          tenant.text = choice.martCode;
          user.text = choice.username;
          password.clear();
          error = null;
        });
      }
    } finally {
      _accountSheetOpen = false;
    }
  }

  @override
  void dispose() {
    tenant.dispose();
    user.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (challenge == null &&
        (tenant.text.trim().isEmpty || user.text.trim().isEmpty ||
          password.text.isEmpty)) {
      setState(() => error = 'Enter your mart code, username and password.');
      return;
    }
    if (challenge != null && code.text.trim().length != 6) {
      setState(() => error = 'Enter your six-digit verification code.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
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
          code.clear();
          password.clear();
          error = ex.key == 'EMAIL_DELIVERY_FAILED' ? ex.message : null;
        });
      } else if (ex.key == 'DEVICE_NOT_APPROVED') {
        final approval = field(ex.extra['approval_status']);
        setState(() => error = approval == 'pending'
          ? 'Device approval is pending. Contact your administrator.'
          : ex.message);
      } else {
        setState(() => error = ex.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Sign-in failed. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (challenge == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
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

  Widget _input(TextEditingController controller, String placeholder,
      IconData icon, {bool isPassword = false,
      TextInputType? keyboard, TextInputAction? action}) {
    return SizedBox(height: 42, child: TextField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      autofillHints: isPassword ? const [AutofillHints.password] :
        identical(controller, user) ? const [AutofillHints.username] : null,
      enableSuggestions: !isPassword,
      autocorrect: false,
      obscureText: isPassword && obscure,
      onTap: challenge == null && (identical(controller, tenant) ||
        identical(controller, user)) ? _openSavedLogins : null,
      onSubmitted: isPassword ? (_) => submit() : null,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: placeholder,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        prefixIconConstraints: const BoxConstraints(minWidth: 39, minHeight: 42),
        prefixIcon: Icon(icon, size: 18),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 42),
        suffixIcon: isPassword ? IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => obscure = !obscure),
          icon: Icon(obscure ? Icons.visibility_outlined :
            Icons.visibility_off_outlined, size: 19)) : null,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.app.appearance.accent;
    return Scaffold(body: DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [scheme.surface, scheme.primaryContainer.withValues(alpha: .28),
          scheme.surface],
      )),
      child: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        // Keep inputs readable on narrow Android phones; do not scale text.
        final compact = constraints.maxHeight < 660 || constraints.maxWidth < 350;
        final narrow = constraints.maxWidth < 350;
        final diameter = math.min(constraints.maxWidth - 16,
          math.min(440.0, math.max(320.0, constraints.maxHeight - 168)));
        final formWidth = math.min(252.0, diameter - 94);
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 22),
              Text('BLUEPOS', style: TextStyle(
                color: accent, fontWeight: FontWeight.w900,
                fontSize: 21, letterSpacing: 4)),
              const SizedBox(height: 5),
              Text('POS & ERP', style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 13,
                letterSpacing: 1.5)),
              SizedBox(height: compact ? 14 : 23),
              Container(
                width: diameter, height: diameter,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.white.withValues(alpha: .65),
                    scheme.primaryContainer.withValues(alpha: .47),
                  ]),
                  border: Border.all(color: accent.withValues(alpha: .25), width: 2),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: .16),
                    blurRadius: 32, offset: const Offset(3, 14))],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface.withValues(alpha: .95),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
                  ),
                  child: Center(child: SizedBox(width: formWidth,
                    height: narrow ? diameter - 42 : null,
                    child: SingleChildScrollView(
                      physics: narrow ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                      child: AutofillGroup(child: Column(
                        mainAxisSize: MainAxisSize.min, children: [
                          BlueposBrandMark(size: compact ? 36 : 40),
                          const SizedBox(height: 5),
                          Text(challenge == null ? 'Welcome Back' : 'Verify Account',
                            style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                          SizedBox(height: compact ? 8 : 10),
                          if (challenge == null) ...[
                            _input(tenant, 'Tenant / Mart Code',
                              Icons.storefront_outlined, action: TextInputAction.next),
                            SizedBox(height: compact ? 5 : 7),
                            _input(user, 'Username',
                              Icons.person_outline_rounded, action: TextInputAction.next),
                            SizedBox(height: compact ? 5 : 7),
                            _input(password, 'Password',
                              Icons.lock_outline_rounded, isPassword: true),
                          ] else ...[
                            _input(code, '6-digit verification code',
                              Icons.verified_user_outlined, keyboard: TextInputType.number,
                              action: TextInputAction.done),
                            if (hint?.isNotEmpty == true) Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text('Recovery hint: $hint',
                                style: const TextStyle(fontSize: 11))),
                            SizedBox(height: 32, child: Row(children: [
                              Checkbox(value: trust,
                                onChanged: busy ? null : (v) =>
                                  setState(() => trust = v ?? false)),
                              const Expanded(child: Text('Trust this device',
                                style: TextStyle(fontSize: 11))),
                            ])),
                          ],
                          SizedBox(height: compact ? 30 : 32, child: Row(children: [
                            Checkbox(value: remember,
                              onChanged: busy ? null : (v) =>
                                setState(() => remember = v ?? false)),
                            const Expanded(child: Text('Remember Me',
                              style: TextStyle(fontSize: 11))),
                          ])),
                          const SizedBox(height: 5),
                          SizedBox(height: 42, width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : submit,
                              icon: busy ? const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)) :
                                const Icon(Icons.login_rounded, size: 18),
                              label: Text(challenge == null ? 'Login' : 'Verify',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            )),
                          if (challenge != null) TextButton(
                            onPressed: busy ? null : resend,
                            child: const Text('Resend code')),
                        ],
                      )))),
                  )),
                ),
              if (error != null) Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(error!, textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error, fontSize: 12.5)),
              ),
              if (challenge != null) TextButton(
                onPressed: () => setState(() {
                  challenge = null;
                  code.clear();
                  error = null;
                }),
                child: const Text('Back to password login')),
              SizedBox(height: compact ? 27 : 39),
              SizedBox(
                width: math.min(constraints.maxWidth - 54, 305.0),
                height: 49,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : biometricLogin,
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  label: const Text('Fingerprint / Face Unlock',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
            ]),
          ),
        );
      })),
    ));
  }
}
