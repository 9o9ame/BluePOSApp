import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

/// Server-authorized session overview. A user with session-view but no revoke
/// privilege sees only their own sessions; server filters the list.
class SecuritySessionsScreen extends StatefulWidget {
  const SecuritySessionsScreen({super.key, required this.app});
  final AppController app;
  @override
  State<SecuritySessionsScreen> createState() =>
    _SecuritySessionsScreenState();
}

class _SecuritySessionsScreenState extends State<SecuritySessionsScreen> {
  List<Map<String, dynamic>> sessions = const [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/security/sessions');
      if (mounted) setState(() => sessions = recordsOf(data));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> revoke(Map<String, dynamic> session) async {
    final id = field(session['ulid']);
    if (!validPublicUlid(id) || session['is_current'] == true) return;
    if (!await confirmMutation(context,
      title: 'Revoke this session?',
      warning: 'BluePOS will immediately reject future calls from this '
        'session. This cannot be undone.',
      actionLabel: 'Revoke')) return;
    try {
      await widget.app.api.request('DELETE', '/api/security/sessions/$id');
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> revokeOthers() async {
    if (!await confirmMutation(context,
      title: 'Sign out all other sessions?',
      warning: 'All other sessions for your account will be revoked. '
        'Your current BluePOS session will remain signed in.',
      actionLabel: 'Revoke Others')) return;
    try {
      await widget.app.api.request('DELETE',
        '/api/security/sessions/others');
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Security Sessions'),
        actions: [IconButton(onPressed: loading ? null : refresh,
          icon: const Icon(Icons.refresh_rounded))]),
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Signed-in devices & sessions'),
          if (!loading)
            OutlinedButton.icon(
              onPressed: revokeOthers,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out Other Sessions')),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (sessions.isEmpty) const EmptyState(title: 'No sessions')
          else for (final session in sessions) Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  Icon(Icons.verified_user_outlined,
                    color: session['is_current'] == true
                      ? palette.primary : palette.onSurfaceVariant),
                  const SizedBox(width: 9),
                  Expanded(child: Text(field(
                    objectOf(session['device'])['name'],
                    field(objectOf(session['membership'])['username'],
                      'User session')),
                    style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (session['is_current'] == true)
                    const Text('This device', style: TextStyle(fontSize: 11)),
                ]),
                Text('Last active: ${field(session['last_seen_at'])}',
                  style: const TextStyle(fontSize: 11)),
                if (session['revoked_at'] != null)
                  Text('Revoked: ${field(session['revoked_at'])}',
                    style: TextStyle(fontSize: 11, color: palette.error)),
                if (session['revoked_at'] == null &&
                    session['is_current'] != true &&
                    validPublicUlid(field(session['ulid'])))
                  TextButton.icon(onPressed: () => revoke(session),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Revoke Session')),
              ]))),
          const SizedBox(height: 35),
        ])),
    );
  }
}
