import 'package:flutter/material.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.app});
  final AppController app;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  @override
  void dispose() { current.dispose(); next.dispose(); confirm.dispose(); super.dispose(); }

  Future<void> save() async {
    if (next.text.length < 8 || next.text != confirm.text) {
      await showApiError(context, 'Password must have at least 8 characters and match confirmation.'); return;
    }
    setState(() => busy = true);
    try {
      await widget.app.changePassword(current.text, next.text);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change password')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const SectionHeading('Security update required'),
      const Text('Your account requires a password change before using BluePOS.'),
      const SizedBox(height: 20),
      TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
      const SizedBox(height: 12),
      TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
      const SizedBox(height: 12),
      TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
      const SizedBox(height: 22),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving…' : 'Update password')),
      TextButton(onPressed: busy ? null : widget.app.logout, child: const Text('Sign out')),
    ]),
  );
}
