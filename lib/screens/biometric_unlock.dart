import 'package:flutter/material.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key, required this.app});
  final AppController app;
  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const BlueposBrandMark(size: 88),
        const SizedBox(height: 23),
        Text('BluePOS is locked', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Verify your fingerprint or face to continue', textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 28),
        Surface(child: Column(children: [
          Icon(Icons.fingerprint_rounded, size: 82, color: scheme.primary),
          const SizedBox(height: 12),
          Text(app.tenantName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(app.userName, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: app.unlocking ? null : () => app.unlock(),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(app.unlocking ? 'Verifying…' : 'Unlock securely')),
          if (app.biometricMessage != null) ...[
            const SizedBox(height: 12),
            Text(app.biometricMessage!, textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          TextButton(onPressed: app.unlocking ? null : () => app.signInWithPassword(),
            child: const Text('Sign in with password instead')),
        ])),
        const SizedBox(height: 18),
        Text('Biometric verification cannot override a revoked session or device approval.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ]),
    ))));
  }
}
