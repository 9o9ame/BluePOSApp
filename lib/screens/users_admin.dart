import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key, required this.app});
  final AppController app;
  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> users = const [], roles = const [], branches = const [];

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/memberships');
      List<Map<String, dynamic>> allowedRoles = const [];
      List<Map<String, dynamic>> allowedBranches = const [];
      try {
        allowedRoles = recordsOf(await widget.app.api.get('/api/roles'));
      } catch (_) {
        // Roles may be hidden from users who can only view memberships.
      }
      try {
        allowedBranches = recordsOf(await widget.app.api.get('/api/branches'));
      } catch (_) {
        // Branch directory may require a separate permission.
      }
      if (mounted) setState(() {
        users = recordsOf(data);
        roles = allowedRoles;
        branches = allowedBranches;
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Set<String>?> pickMany({
    required String title,
    required List<Map<String, dynamic>> options,
    required Set<String> initial,
    bool requiredNonEmpty = false,
  }) async {
    if (options.isEmpty) {
      if (mounted) await showApiError(context,
        'No authorized $title options are available.');
      return null;
    }
    final selected = {...initial};
    return showModalBottomSheet<Set<String>>(context: context,
      useSafeArea: true, showDragHandle: true, isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: SizedBox(height: MediaQuery.sizeOf(sheet).height * .7,
            child: Column(children: [
              Text(title, style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 10),
              Expanded(child: ListView(
                children: options.where((r) =>
                  validPublicUlid(field(r['ulid']))).map((r) {
                  final id = field(r['ulid']);
                  return CheckboxListTile(
                    title: Text(field(r['name'])),
                    subtitle: Text(field(r['code'])),
                    value: selected.contains(id),
                    onChanged: (v) => update(() {
                      if (v == true) selected.add(id);
                      else selected.remove(id);
                    }),
                  );
                }).toList(),
              )),
              FilledButton.icon(
                onPressed: requiredNonEmpty && selected.isEmpty
                  ? null : () => Navigator.pop(sheet, selected),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Use selection')),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> createUser() async {
    if (!widget.app.hasPermission('users.create')) return;
    final name = TextEditingController();
    final username = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    var selectedRoles = <String>{}, selectedBranches = <String>{};
    var mustChange = true, busy = false, uncertain = false;
    String? formError;
    try {
      final created = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true,
        showDragHandle: true, useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, update) => Padding(
            padding: EdgeInsets.fromLTRB(16, 9, 16,
              MediaQuery.viewInsetsOf(sheet).bottom + 18),
            child: ConstrainedBox(constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * .83),
              child: ListView(shrinkWrap: true, children: [
                Text('New team member',
                  style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextField(controller: name, maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Name *')),
                TextField(controller: username, maxLength: 63,
                  decoration: const InputDecoration(labelText: 'Username *')),
                TextField(controller: email, maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Recovery email (optional)')),
                TextField(controller: phone, maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Recovery phone (optional)')),
                TextField(controller: password, obscureText: true,
                  enableSuggestions: false, autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password (8+ characters) *')),
                ListTile(contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text('Roles (${selectedRoles.length})'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: busy || uncertain ? null : () async {
                    final result = await pickMany(
                      title: 'Select user roles', options: roles,
                      initial: selectedRoles, requiredNonEmpty: true);
                    if (result != null && sheet.mounted) {
                      update(() => selectedRoles = result);
                    }
                  }),
                ListTile(contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text('Branches (${selectedBranches.length})'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: busy || uncertain ? null : () async {
                    final result = await pickMany(
                      title: 'Select accessible branches',
                      options: branches, initial: selectedBranches);
                    if (result != null && sheet.mounted) {
                      update(() => selectedBranches = result);
                    }
                  }),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Must change password at first login'),
                  value: mustChange,
                  onChanged: busy || uncertain
                    ? null : (v) => update(() => mustChange = v)),
                if (formError != null)
                  Text(formError!, style: TextStyle(
                    color: Theme.of(sheet).colorScheme.error)),
                const SizedBox(height: 9),
                FilledButton.icon(
                  onPressed: busy || uncertain ? null : () async {
                    if (name.text.trim().isEmpty ||
                        username.text.trim().isEmpty ||
                        password.text.length < 8 ||
                        selectedRoles.isEmpty) {
                      update(() => formError =
                        'Name, username, password and at least one role are required.');
                      return;
                    }
                    update(() { busy = true; formError = null; uncertain = true; });
                    try {
                      final data = <String, dynamic>{
                        'name': name.text.trim(),
                        'username': username.text.trim(),
                        'password': password.text,
                        'must_change_password': mustChange,
                        'roles': selectedRoles.toList(),
                        'branches': selectedBranches.toList(),
                        if (email.text.trim().isNotEmpty)
                          'recovery_email': email.text.trim(),
                        if (phone.text.trim().isNotEmpty)
                          'recovery_phone': phone.text.trim(),
                      };
                      await widget.app.api.post('/api/memberships', data);
                      if (sheet.mounted) Navigator.pop(sheet, true);
                    } on ApiFailure catch (ex) {
                      if (sheet.mounted) update(() {
                        if (ex.status == 403 || ex.status == 422) {
                          uncertain = false;
                        }
                        formError = uncertain
                          ? 'Creation uncertain. Check Users before submitting again.'
                          : ex.message;
                      });
                    } catch (_) {
                      if (sheet.mounted) update(() =>
                        formError = 'Create status uncertain. Refresh users before another attempt.');
                    } finally {
                      if (sheet.mounted) update(() => busy = false);
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Create User')),
              ]),
            ),
          ),
        ),
      );
      if (created == true && mounted) await refresh();
    } finally {
      password.clear();
      name.dispose(); username.dispose();
      email.dispose(); phone.dispose(); password.dispose();
    }
  }

  Future<void> changeAssignments(
    Map<String, dynamic> member, {required bool branchesOnly}
  ) async {
    final permission = branchesOnly
      ? 'users.manage_branches' : 'users.manage_roles';
    if (!widget.app.hasPermission(permission)) return;
    final id = field(member['ulid']);
    if (!validPublicUlid(id)) return;
    final present = recordsOf(member[branchesOnly ? 'branches' : 'roles'])
      .map((item) => field(item['ulid'])).toSet();
    final chosen = await pickMany(
      title: branchesOnly ? 'Assigned branches' : 'Assigned roles',
      options: branchesOnly ? branches : roles,
      initial: present, requiredNonEmpty: !branchesOnly,
    );
    if (chosen == null || !mounted) return;
    final confirm = await confirmMutation(context,
      title: 'Update access assignments?',
      warning: 'The user\'s access will change immediately. '
        'BluePOS server rechecks tenancy, ownership and role restrictions.',
      actionLabel: 'Apply');
    if (!confirm || !mounted) return;
    try {
      await widget.app.api.request('PUT', '/api/memberships/$id/'
        '${branchesOnly ? 'branches' : 'roles'}',
        body: {
          branchesOnly ? 'branches' : 'roles': chosen.toList(),
        });
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> toggleStatus(
    Map<String, dynamic> member, {required bool activate}
  ) async {
    final permission = activate ? 'users.activate' : 'users.deactivate';
    if (!widget.app.hasPermission(permission) ||
        member['is_owner'] == true) return;
    final id = field(member['ulid']);
    if (!validPublicUlid(id)) return;
    if (!await confirmMutation(context,
      title: activate ? 'Activate user?' : 'Deactivate user?',
      warning: 'The server enforces owner safeguards and user/session access.',
      actionLabel: activate ? 'Activate' : 'Deactivate')) return;
    try {
      await widget.app.api.post(
        '/api/memberships/$id/${activate ? 'activate' : 'deactivate'}', {});
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> resetPassword(Map<String, dynamic> member) async {
    if (!widget.app.hasPermission('users.reset_password')) return;
    final id = field(member['ulid']);
    if (!validPublicUlid(id)) return;
    final password = TextEditingController();
    try {
      final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset user password'),
          content: TextField(controller: password, obscureText: true,
            enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Temporary password (8+ characters)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset Password')),
          ],
        ));
      if (ok != true || password.text.length < 8 || !mounted) return;
      await widget.app.api.post('/api/memberships/$id/reset-password',
        {'password': password.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset confirmed.')));
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    } finally {
      password.clear();
      password.dispose();
    }
  }

  Future<void> forceLogout(Map<String, dynamic> member) async {
    if (!widget.app.hasPermission('users.force_logout')) return;
    final id = field(member['ulid']);
    if (!validPublicUlid(id)) return;
    if (!await confirmMutation(context,
      title: 'Force sign-out?',
      warning: 'This revokes the team member\'s active sessions.',
      actionLabel: 'Force Sign-Out')) return;
    try {
      await widget.app.api.post(
        '/api/memberships/$id/force-logout', {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessions revoked.')));
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Users & Team')),
      floatingActionButton: widget.app.hasPermission('users.create')
        ? FloatingActionButton.extended(onPressed: createUser,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add User')) : null,
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Team member accounts'),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (users.isEmpty) const EmptyState(title: 'No team members')
          else for (final user in users) Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.person_outline_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(objectOf(user['user'])['name'],
                        field(user['username'])),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(user['username']),
                      style: TextStyle(fontSize: 11,
                        color: colors.onSurfaceVariant)),
                  ])),
                  Text(user['is_owner'] == true ? 'OWNER'
                    : field(user['status']),
                    style: TextStyle(fontSize: 11, color: colors.primary)),
                ]),
                Text('Roles: ${recordsOf(user['roles'])
                    .map((item) => field(item['name'])).join(', ')}',
                    style: const TextStyle(fontSize: 11)),
                Wrap(spacing: 5, children: [
                  if (widget.app.hasPermission('users.manage_roles') &&
                      user['is_owner'] != true)
                    TextButton(onPressed: () =>
                      changeAssignments(user, branchesOnly: false),
                      child: const Text('Roles')),
                  if (widget.app.hasPermission('users.manage_branches') &&
                      user['is_owner'] != true)
                    TextButton(onPressed: () =>
                      changeAssignments(user, branchesOnly: true),
                      child: const Text('Branches')),
                  if (user['is_owner'] != true &&
                      user['status'] == 'active' &&
                      widget.app.hasPermission('users.deactivate'))
                    TextButton(onPressed: () =>
                      toggleStatus(user, activate: false),
                      child: const Text('Deactivate')),
                  if (user['is_owner'] != true &&
                      user['status'] != 'active' &&
                      widget.app.hasPermission('users.activate'))
                    TextButton(onPressed: () =>
                      toggleStatus(user, activate: true),
                      child: const Text('Activate')),
                  if (widget.app.hasPermission('users.reset_password'))
                    TextButton(onPressed: () => resetPassword(user),
                      child: const Text('Reset Password')),
                  if (widget.app.hasPermission('users.force_logout'))
                    TextButton(onPressed: () => forceLogout(user),
                      child: const Text('Sign Out')),
                ]),
              ]))),
          const SizedBox(height: 80),
        ])),
    );
  }
}
