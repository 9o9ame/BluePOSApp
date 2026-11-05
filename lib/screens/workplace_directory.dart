import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// The warehouse API is explicitly scoped to the server's active branch.
/// Neither list nor write payload contains tenant/branch/warehouse BIGINT IDs.
enum WorkplaceKind { branches, warehouses }

extension WorkplaceDefinition on WorkplaceKind {
  String get title => this == WorkplaceKind.branches ? 'Branches' : 'Warehouses';
  String get singular => this == WorkplaceKind.branches ? 'Branch' : 'Warehouse';
  String get path => this == WorkplaceKind.branches
    ? '/api/branches' : '/api/warehouses';
  String get managePermission => this == WorkplaceKind.branches
    ? 'branches.manage' : 'warehouses.manage';
}

class WorkplaceDirectoryScreen extends StatefulWidget {
  const WorkplaceDirectoryScreen({
    super.key, required this.app, required this.kind,
  });
  final AppController app;
  final WorkplaceKind kind;
  @override
  State<WorkplaceDirectoryScreen> createState() =>
    _WorkplaceDirectoryScreenState();
}

class _WorkplaceDirectoryScreenState
    extends State<WorkplaceDirectoryScreen> {
  final search = TextEditingController();
  List<Map<String, dynamic>> records = const [];
  bool loading = true;
  String? error;
  int requestId = 0;

  bool get canManage => widget.app.hasPermission(widget.kind.managePermission);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final request = ++requestId;
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.app.api.get(widget.kind.path);
      if (mounted && request == requestId) {
        setState(() => records = recordsOf(result));
      }
    } catch (ex) {
      if (mounted && request == requestId) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == requestId) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    if (!canManage) return;
    final creating = existing == null;
    final code = TextEditingController(text: field(existing?['code']));
    final name = TextEditingController(text: field(existing?['name']));
    var status = field(existing?['status'], 'active');
    var isDefault = existing?['is_default'] == true;
    var saving = false;
    String? formError;

    try {
      final saved = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true,
        showDragHandle: true, useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, change) => Padding(
            padding: EdgeInsets.fromLTRB(16, 3, 16,
              MediaQuery.viewInsetsOf(sheet).bottom + 17),
            child: ListView(shrinkWrap: true, children: [
              Text(creating ? 'New ${widget.kind.singular}'
                  : 'Edit ${widget.kind.singular}',
                style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (widget.kind == WorkplaceKind.warehouses)
                Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Active branch: ${widget.app.branchName}',
                    style: TextStyle(fontSize: 12,
                      color: Theme.of(sheet).colorScheme.onSurfaceVariant))),
              TextField(controller: code,
                maxLength: 32, enabled: !saving,
                decoration: const InputDecoration(labelText: 'Code *')),
              const SizedBox(height: 10),
              TextField(controller: name,
                maxLength: 120, enabled: !saving,
                decoration: const InputDecoration(labelText: 'Name *')),
              if (!creating) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: saving ? null : (value) {
                    if (value != null) change(() => status = value);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default location'),
                  value: isDefault,
                  onChanged: saving ? null :
                    (v) => change(() => isDefault = v)),
              ],
              const SizedBox(height: 10),
              if (formError != null)
                Text(formError!, style: TextStyle(
                  color: Theme.of(sheet).colorScheme.error)),
              FilledButton.icon(
                onPressed: saving ? null : () async {
                  if (code.text.trim().isEmpty ||
                      name.text.trim().isEmpty) {
                    change(() => formError = 'Enter code and name.');
                    return;
                  }
                  change(() { saving = true; formError = null; });
                  try {
                    final payload = <String, dynamic>{
                      'code': code.text.trim(),
                      'name': name.text.trim(),
                      if (!creating) ...{
                        'status': status,
                        'is_default': isDefault,
                      },
                    };
                    if (creating) {
                      await widget.app.api.post(widget.kind.path, payload);
                    } else {
                      final ulid = field(existing['ulid']);
                      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')
                          .hasMatch(ulid)) {
                        throw const FormatException('Invalid location.');
                      }
                      await widget.app.api.patch(
                        '${widget.kind.path}/$ulid', payload);
                    }
                    if (sheet.mounted) Navigator.pop(sheet, true);
                  } catch (ex) {
                    if (sheet.mounted) {
                      change(() => formError = ex.toString());
                    }
                  } finally {
                    if (sheet.mounted) {
                      change(() => saving = false);
                    }
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(saving ? 'Saving…' : 'Save ${widget.kind.singular}')),
            ]),
          ),
        ),
      );
      if (saved == true && mounted) await load();
    } finally {
      code.dispose();
      name.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filter = search.text.trim().toLowerCase();
    final available = records.where((record) =>
      '${field(record['code'])} ${field(record['name'])}'
        .toLowerCase().contains(filter)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title),
        actions: [IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: loading ? null : load,
          tooltip: 'Refresh locations')]),
      floatingActionButton: canManage
        ? FloatingActionButton.extended(
            onPressed: () => edit(),
            icon: const Icon(Icons.add_rounded),
            label: Text('Add ${widget.kind.singular}'))
        : null,
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          SectionHeading(widget.kind.title),
          if (widget.kind == WorkplaceKind.warehouses)
            Text('Current branch: ${widget.app.branchName}',
              style: TextStyle(fontSize: 12,
                color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by code or name')),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else if (available.isEmpty) EmptyState(
            title: 'No ${widget.kind.title.toLowerCase()} found',
            subtitle: 'Try another search.')
          else ...available.map((location) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: canManage ? () => edit(location) : null,
              child: Surface(padding: const EdgeInsets.all(13),
                child: Row(children: [
                  Container(width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13)),
                    child: Icon(widget.kind == WorkplaceKind.branches
                      ? Icons.storefront_outlined : Icons.warehouse_outlined,
                      color: scheme.primary)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field(location['name']),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(field(location['code']),
                        style: TextStyle(fontSize: 12,
                          color: scheme.onSurfaceVariant)),
                    ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(field(location['status'], 'active'),
                      style: TextStyle(fontSize: 11,
                        color: location['status'] == 'inactive'
                          ? scheme.error : scheme.primary)),
                    if (location['is_default'] == true)
                      const Text('Default', style: TextStyle(fontSize: 11)),
                  ]),
                  if (canManage) const Icon(Icons.chevron_right_rounded),
                ])),
            ),
          )),
          const SizedBox(height: 75),
        ],
      )),
    );
  }
}
