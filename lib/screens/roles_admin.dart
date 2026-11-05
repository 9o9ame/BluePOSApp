import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

class RolesAdminScreen extends StatefulWidget {
  const RolesAdminScreen({super.key, required this.app});
  final AppController app;

  @override
  State<RolesAdminScreen> createState() => _RolesAdminScreenState();
}

class _RolesAdminScreenState extends State<RolesAdminScreen> {
  List<Map<String, dynamic>> roles = const [], permissionCatalog = const [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final items = await widget.app.api.get('/api/roles');
      final perms = await widget.app.api.get('/api/permissions');
      if (mounted) setState(() {
        roles = recordsOf(items);
        permissionCatalog = recordsOf(perms);
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    final creating = existing == null;
    if (!widget.app.hasPermission(
        creating ? 'roles.create' : 'roles.edit')) return;
    final name = TextEditingController(text: field(existing?['name']));
    final code = TextEditingController(text: field(existing?['code']));
    final description = TextEditingController(text: field(existing?['description']));
    var branchAccess = field(existing?['branch_access'], 'selected_branches');
    var active = existing?['is_active'] != false;
    var busy = false, uncertain = false;
    String? formError;
    try {
      final saved = await showModalBottomSheet<bool>(context: context,
        showDragHandle: true, useSafeArea: true, isScrollControlled: true,
        builder: (sheet) => StatefulBuilder(builder: (sheet, update) =>
          Padding(padding: EdgeInsets.fromLTRB(16, 7, 16,
            MediaQuery.viewInsetsOf(sheet).bottom + 16),
            child: ListView(shrinkWrap: true, children: [
              Text(creating ? 'New role' : 'Edit role',
                style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: name, maxLength: 100, enabled: !busy,
                decoration: const InputDecoration(labelText: 'Role name *')),
              if (creating) TextField(controller: code, maxLength: 64,
                decoration: const InputDecoration(labelText: 'Role code *')),
              TextField(controller: description, maxLength: 255,
                maxLines: 2, decoration: const InputDecoration(
                  labelText: 'Description')),
              DropdownButtonFormField<String>(
                initialValue: branchAccess,
                decoration: const InputDecoration(labelText: 'Branch access'),
                items: const [
                  DropdownMenuItem(value: 'all_branches',
                    child: Text('All authorized branches')),
                  DropdownMenuItem(value: 'selected_branches',
                    child: Text('Selected branches')),
                ],
                onChanged: (v) {
                  if (v != null) update(() => branchAccess = v);
                },
              ),
              if (!creating) SwitchListTile.adaptive(
                title: const Text('Active role'), value: active,
                onChanged: (v) => update(() => active = v)),
              if (formError != null) Text(formError!,
                style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
              const SizedBox(height: 11),
              FilledButton.icon(
                onPressed: busy || uncertain ? null : () async {
                  if (name.text.trim().isEmpty ||
                      (creating && !RegExp(r'^[a-zA-Z0-9_-]{1,64}$')
                        .hasMatch(code.text.trim()))) {
                    update(() => formError = 'Enter a valid role name and code.');
                    return;
                  }
                  update(() => busy = true);
                  try {
                    final data = <String, dynamic>{
                      'name': name.text.trim(),
                      'description': description.text.trim(),
                      'branch_access': branchAccess,
                      if (creating) 'code': code.text.trim(),
                      if (!creating) 'is_active': active,
                    };
                    if (creating) {
                      uncertain = true;
                      await widget.app.api.post('/api/roles', data);
                    } else {
                      final id = field(existing['ulid']);
                      if (!validPublicUlid(id)) {
                        throw const FormatException('Invalid role.');
                      }
                      await widget.app.api.patch('/api/roles/$id', data);
                    }
                    if (sheet.mounted) Navigator.pop(sheet, true);
                  } on ApiFailure catch (ex) {
                    if (sheet.mounted) update(() {
                      if (ex.status == 403 || ex.status == 422) uncertain = false;
                      formError = uncertain
                        ? 'Creation uncertain. Check Roles list before retrying.'
                        : ex.message;
                    });
                  } catch (_) {
                    if (sheet.mounted) update(() =>
                      formError = 'Save uncertain. Refresh roles before another attempt.');
                  } finally {
                    if (sheet.mounted) update(() => busy = false);
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Role')),
            ]),
          ),
        ));
      if (saved == true && mounted) await refresh();
    } finally {
      name.dispose(); code.dispose(); description.dispose();
    }
  }

  Future<void> managePermissions(Map<String, dynamic> role) async {
    if (!widget.app.hasPermission('roles.manage_permissions') ||
        role['is_system'] == true) return;
    final id = field(role['ulid']);
    if (!validPublicUlid(id)) return;
    final availableKeys = permissionCatalog
        .map((p) => field(p['key'])).where((k) => k.isNotEmpty).toSet();
    final chosen = recordsOf(role['permissions'])
      .map((p) => field(p['key'])).where(availableKeys.contains).toSet();
    String search = '';
    bool saving = false;
    String? errorText;
    final saved = await showModalBottomSheet<bool>(
      context: context, showDragHandle: true, useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) {
          final filtered = permissionCatalog.where((p) =>
            '${field(p['key'])} ${field(p['name'])} ${field(p['module'])}'
              .toLowerCase().contains(search.toLowerCase())).toList();
          return Padding(padding: EdgeInsets.fromLTRB(16, 9, 16,
            MediaQuery.viewInsetsOf(sheet).bottom + 12),
            child: SizedBox(height: MediaQuery.sizeOf(sheet).height * .78,
              child: Column(children: [
                Text('Permissions · ${field(role['name'])}',
                  style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextField(onChanged: (v) => update(() => search = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Find a permission')),
                Text('${chosen.length} permissions selected'),
                Expanded(child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final permission = filtered[index];
                    final key = field(permission['key']);
                    return CheckboxListTile(
                      dense: true, value: chosen.contains(key),
                      title: Text(field(permission['name'], key)),
                      subtitle: Text('${field(permission['module'])} · $key',
                        style: const TextStyle(fontSize: 10)),
                      onChanged: saving ? null : (v) => update(() {
                        if (v == true) chosen.add(key);
                        else chosen.remove(key);
                      }),
                    );
                  })),
                if (errorText != null) Text(errorText!,
                  style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
                FilledButton.icon(
                  onPressed: saving ? null : () async {
                    final confirm = await confirmMutation(sheet,
                      title: 'Update role permissions?',
                      warning: 'This changes access for users assigned '
                        'to this role. The server will enforce all permissions.',
                      actionLabel: 'Apply Permissions');
                    if (!confirm || !sheet.mounted) return;
                    update(() => saving = true);
                    try {
                      await widget.app.api.request('PUT',
                        '/api/roles/$id/permissions',
                        body: {'permissions': chosen.toList()..sort()});
                      if (sheet.mounted) Navigator.pop(sheet, true);
                    } catch (ex) {
                      if (sheet.mounted) update(() => errorText = ex.toString());
                    } finally {
                      if (sheet.mounted) update(() => saving = false);
                    }
                  },
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Save Permissions')),
              ]),
            ),
          );
        },
      ),
    );
    if (saved == true && mounted) await refresh();
  }

  Future<void> delete(Map<String, dynamic> role) async {
    if (!widget.app.hasPermission('roles.delete') ||
        role['is_system'] == true) return;
    final id = field(role['ulid']);
    if (!validPublicUlid(id)) return;
    if (!await confirmMutation(context,
      title: 'Delete role?',
      warning: 'Only deletable roles may be removed. '
        'The BluePOS server checks existing assignments.',
      actionLabel: 'Delete Role')) return;
    try {
      await widget.app.api.request('DELETE', '/api/roles/$id');
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      floatingActionButton: widget.app.hasPermission('roles.create')
        ? FloatingActionButton.extended(
          onPressed: () => edit(), icon: const Icon(Icons.add_rounded),
          label: const Text('New Role')) : null,
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Tenant access roles'),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (roles.isEmpty) const EmptyState(title: 'No roles')
          else for (final role in roles) Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.admin_panel_settings_outlined,
                    color: colors.primary),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(role['name']),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(field(role['code']),
                      style: TextStyle(color: colors.onSurfaceVariant,
                        fontSize: 11)),
                    ])),
                  if (role['is_system'] == true)
                    const Text('System role', style: TextStyle(fontSize: 11))
                  else if (role['is_active'] == false)
                    const Text('Inactive', style: TextStyle(fontSize: 11)),
                ]),
                Text(field(role['description'])),
                Wrap(spacing: 5, children: [
                  if (widget.app.hasPermission('roles.edit') &&
                      role['is_system'] != true)
                    TextButton.icon(onPressed: () => edit(role),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit')),
                  if (widget.app.hasPermission('roles.manage_permissions') &&
                      role['is_system'] != true)
                    TextButton.icon(onPressed: () => managePermissions(role),
                      icon: const Icon(Icons.shield_outlined, size: 16),
                      label: const Text('Permissions')),
                  if (widget.app.hasPermission('roles.delete') &&
                      role['is_system'] != true)
                    TextButton.icon(onPressed: () => delete(role),
                      icon: Icon(Icons.delete_outline_rounded,
                        color: colors.error, size: 16),
                      label: const Text('Delete')),
                ]),
              ]))),
          const SizedBox(height: 70),
        ])),
    );
  }
}
