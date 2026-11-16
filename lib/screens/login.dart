import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/saved_accounts.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'login_reference_visual.dart';
import 'password_recovery.dart';

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
      TextInputType? keyboard, TextInputAction? action,
      bool compact = false}) {
    final index = identical(controller, tenant) ? 0 :
      identical(controller, user) ? 1 : 2;
    const tones = [Color(0xFF0074F8), Color(0xFF0EA760), Color(0xFFF39B0A)];
    const plates = [Color(0xFFDFEEFF), Color(0xFFDCFAE9), Color(0xFFFFF0DB)];
    final faceHeight = compact ? 45.0 : 50.0;
    return Container(
      key: ValueKey('login-field-$index'),
      height: faceHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEDF1FF)]),
        border: Border.all(color: Colors.white, width: 1.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x335E7CC1),
            blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: TextField(
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
        style: const TextStyle(fontSize: 14.2, color: Color(0xFF172848)),
        decoration: InputDecoration(
          filled: false,
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xFF465471), fontSize: 14.2),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 9,
            vertical: compact ? 11 : 13),
          prefixIconConstraints: const BoxConstraints(minWidth: 77, minHeight: 43),
          prefixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 8),
            Container(
              width: 35, height: 35,
              decoration: BoxDecoration(color: plates[index],
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: tones[index], size: 22),
            ),
            const SizedBox(width: 12),
            Container(width: 1.4, height: 24, color: const Color(0xFFB9C5DD)),
            const SizedBox(width: 9),
          ]),
          suffixIcon: isPassword ? IconButton(
            tooltip: obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => obscure = !obscure),
            icon: Icon(obscure ? Icons.visibility_outlined :
              Icons.visibility_off_outlined,
              color: const Color(0xFF40516D), size: 20)) : null,
        ),
      ),
    );
  }

  // Screen 04 reference: six independently framed digit positions, while
  // retaining one real accessible TextField and the existing MFA API flow.
  Widget _verificationCodeBoxes() {
    final digits = code.text;
    return SizedBox(
      key: const ValueKey('mfa-six-digit-code'),
      height: 61,
      child: Stack(children: [
        Row(children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            Expanded(child: Container(
              height: 57,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == digits.length
                  ? const Color(0xFFE9F6FF) : const Color(0xFFF9FAFF),
                border: Border.all(
                  color: i == digits.length
                    ? const Color(0xFF20A8FF) : const Color(0xFFE1E6F4),
                  width: i == digits.length ? 1.5 : 1),
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [
                  BoxShadow(color: Color(0x225875AC),
                    blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Text(i < digits.length ? digits[i] : '',
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: Color(0xFF132653))),
            )),
          ],
        ]),
        Positioned.fill(child: Opacity(
          opacity: .01,
          child: TextField(
            controller: code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(
              counterText: '', border: InputBorder.none,
              labelText: '6-digit verification code'),
          ),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.app.appearance.accent;
    final verifying = challenge != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SizedBox.expand(
        key: const ValueKey('login-background'),
        child: SafeArea(child: LayoutBuilder(builder: (context, layout) {
          final compact = layout.maxHeight < 700;
          final maxWidth = math.min(385.0, layout.maxWidth - 34);
          return Stack(children: [
            const Positioned.fill(child: LoginReferenceBackground()),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: layout.maxHeight),
                child: Center(child: SizedBox(
                  width: maxWidth,
                  child: Padding(padding: EdgeInsets.only(
                    top: compact ? 12 : 25,
                    bottom: compact ? 25 : 35),
                    child: AutofillGroup(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LoginReferenceBrand(),
                        SizedBox(height: compact ? 14 : 20),
                        if (!verifying)
                          LoginReferenceStorefront(height: compact ? 108 : 129)
                        else Center(child: Container(
                          width: 75, height: 75,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEEDFF),
                            borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.verified_user_rounded,
                            color: Color(0xFF086CF1), size: 41))),
                        SizedBox(height: compact ? 10 : 14),
                        Text(verifying ? 'Verify Your Account' : 'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF071947),
                            fontSize: compact ? 26 : 29,
                            fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(verifying
                          ? 'Enter the 6-digit code sent to your device'
                          : 'Sign in to your business account',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12,
                            color: const Color(0xFF546078))),
                        SizedBox(height: compact ? 16 : 21),
                        if (!verifying) ...[
                          _input(tenant, 'Tenant / Mart Code',
                            Icons.storefront_outlined,
                            action: TextInputAction.next, compact: compact),
                          const SizedBox(height: 11),
                          _input(user, 'Username',
                            Icons.person_outline_rounded,
                            action: TextInputAction.next, compact: compact),
                          const SizedBox(height: 11),
                          _input(password, 'Password',
                            Icons.lock_outline_rounded,
                            isPassword: true, compact: compact),
                          const SizedBox(height: 7),
                          Row(children: [
                            SizedBox(height: 38, width: 42,
                              child: Checkbox(value: remember,
                                onChanged: busy ? null : (value) =>
                                  setState(() => remember = value ?? false))),
                            const Expanded(child: Text('Remember Me',
                              style: TextStyle(fontSize: 12))),
                          ]),
                        ] else ...[
                          _verificationCodeBoxes(),
                          if (hint?.isNotEmpty == true)
                            Padding(padding: const EdgeInsets.only(top: 7),
                              child: Text('Recovery hint: $hint',
                                style: TextStyle(fontSize: 11,
                                  color: scheme.onSurfaceVariant))),
                          Row(children: [
                            SizedBox(height: 36, width: 42,
                              child: Checkbox(value: trust,
                                onChanged: busy ? null : (v) =>
                                  setState(() => trust = v ?? false))),
                            const Expanded(child: Text('Trust this device',
                              style: TextStyle(fontSize: 12))),
                          ]),
                        ],
                        const SizedBox(height: 12),
                        LoginReferenceGradientButton(
                          key: const ValueKey('login-submit'),
                          onPressed: busy ? null : submit,
                          busy: busy,
                          label: verifying ? 'Verify & Continue' : 'Login'),
                        if (verifying) ...[
                          TextButton(
                            onPressed: busy ? null : resend,
                            child: const Text('Resend Code')),
                          TextButton(
                            onPressed: busy ? null : () => setState(() {
                              challenge = null;
                              code.clear();
                              error = null;
                            }),
                            child: const Text('Back to Login')),
                        ] else ...[
                          Align(alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const ValueKey('login-forgot-password'),
                              onPressed: busy ? null : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) =>
                                  PasswordRecoveryScreen(
                                    app: widget.app,
                                    initialTenant: tenant.text.trim(),
                                    initialUsername: user.text.trim()))),
                              child: const Text('Forgot Password?'))),
                          SizedBox(height: compact ? 4 : 8),
                          Row(children: [
                            const Expanded(child: Divider(color: Color(0xFFB8C3DE))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Text('or', style: TextStyle(
                                color: scheme.onSurfaceVariant))),
                            const Expanded(child: Divider(color: Color(0xFFB8C3DE))),
                          ]),
                          const SizedBox(height: 9),
                          Container(
                            height: 49,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF9FAFF), Color(0xFFE9F0FF)]),
                              border: Border.all(color: Colors.white, width: 1.7),
                              boxShadow: const [BoxShadow(
                                color: Color(0x205A79C0),
                                blurRadius: 10, offset: Offset(0, 5))]),
                            child: TextButton(
                              onPressed: busy ? null : biometricLogin,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fingerprint_rounded,
                                    color: Color(0xFF135CFA), size: 27),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 5),
                                    child: Text('/',
                                      style: TextStyle(color: Color(0xFF1649BC),
                                        fontSize: 19, fontWeight: FontWeight.w800))),
                                  const Icon(Icons.face_rounded,
                                    color: Color(0xFF135CFA), size: 23),
                                  const SizedBox(width: 11),
                                  Container(width: 1.2, height: 25,
                                    color: const Color(0xFF9DAAC5)),
                                  const SizedBox(width: 11),
                                  const Flexible(child: Text(
                                    'Fingerprint / Face Unlock',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Color(0xFF091A46),
                                      fontWeight: FontWeight.w800, fontSize: 12.5))),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (error != null) Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!, textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error, fontSize: 12))),
                      ],
                    ))),
                  ),
                )),
              ),
          ]);
        })),
      ),
    );
  }
}
