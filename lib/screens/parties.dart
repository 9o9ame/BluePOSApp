import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Exact party endpoint contract: server owns tenant context and linked accounts.
Map<String, dynamic> partyPayload({
  required String type, required String code, required String name,
  required String accountTypeUlid, required bool isActive,
  String contact = '', String mobile = '', String address = '',
}) {
  if (!const {'customer', 'vendor', 'account'}.contains(type) ||
      code.trim().isEmpty || name.trim().isEmpty ||
      !RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(accountTypeUlid)) {
    throw const FormatException('Invalid party fields');
  }
  return {
    'party_type': type,
    'code': code.trim().toUpperCase(),
    'name': name.trim(),
    'account_type_ulid': accountTypeUlid,
    'address': address.trim(),
    'is_active': isActive,
    if (type != 'account') ...{
      'contact_person': contact.trim(), 'mobile': mobile.trim(),
    },
  };
}

class PartyDirectory extends StatefulWidget {
  const PartyDirectory({super.key, required this.app, required this.type});
  final AppController app;
  final String type;
  @override
  State<PartyDirectory> createState() => _PartyDirectoryState();
}

class _PartyDirectoryState extends State<PartyDirectory> {
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = const [];
  bool loading = true;
  String? error;

  String get permission => switch (widget.type) {
    'vendor' => 'suppliers',
    'account' => 'accounts',
    _ => 'customers',
  };
  String get title => switch (widget.type) {
    'vendor' => 'Suppliers',
    'account' => 'Accounts',
    _ => 'Customers',
  };
  bool can(String action) => widget.app.hasPermission(permission + '.' + action) ||
    widget.app.hasPermission(permission + '.manage');

  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> refresh() async {
    if (!can('view')) {
      setState(() { loading = false; error = 'Access denied.'; });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/parties?type=' + widget.type);
      if (mounted) setState(() => rows = recordsOf(data));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit({Map<String, dynamic>? record}) async {
    final updating = record != null;
    if (!(updating ? can('edit') : can('create'))) return;
    final ulid = field(record?['ulid']);
    if (updating && ulid.length != 26) return;

    List<Map<String, dynamic>> accounts;
    try {
      accounts = recordsOf(await widget.app.api.get('/api/coa/account-types'))
        .where((row) => row['is_active'] != false).toList();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
      return;
    }
    if (!mounted) return;
    final code = TextEditingController(text: field(record?['code']));
    final name = TextEditingController(text: field(record?['name']));
    final contact = TextEditingController(text: field(record?['contact_person']));
    final mobile = TextEditingController(text: field(record?['mobile']));
    final address = TextEditingController(text: field(record?['address']));
    var selected = field(record?['account_type_ulid']);
    if (!accounts.any((row) => field(row['ulid']) == selected)) selected = '';
    var active = record?['is_active'] != false;
    var saving = false;
    String? message;
    try {
      final saved = await showModalBottomSheet<bool>(
        context: context, showDragHandle: true, isScrollControlled: true,
        useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, update) => Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18,
              MediaQuery.viewInsetsOf(sheet).bottom + 22),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text((updating ? 'Edit ' : 'New ') + widget.type,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(controller: code, maxLength: 64,
                  decoration: const InputDecoration(labelText: 'Code *')),
                TextField(controller: name, maxLength: 180,
                  decoration: const InputDecoration(labelText: 'Name *')),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected.isEmpty ? null : selected,
                  decoration: const InputDecoration(labelText: 'Account type *'),
                  items: accounts.map((row) => DropdownMenuItem<String>(
                    value: field(row['ulid']),
                    child: Text(field(row['name']),
                      maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: saving ? null : (value) =>
                    update(() => selected = value ?? ''),
                ),
                if (widget.type != 'account') ...[
                  TextField(controller: contact, maxLength: 180,
                    decoration: const InputDecoration(labelText: 'Contact person')),
                  TextField(controller: mobile, maxLength: 64,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile')),
                ],
                TextField(controller: address, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address')),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero, value: active,
                  title: const Text('Active'),
                  onChanged: saving ? null : (value) =>
                    update(() => active = value)),
                if (message != null) Text(message!, style: TextStyle(
                  color: Theme.of(sheet).colorScheme.error)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Saving…' : updating ? 'Save changes' : 'Create'),
                  onPressed: saving ? null : () async {
                    if (code.text.trim().isEmpty || name.text.trim().isEmpty ||
                        selected.length != 26) {
                      update(() => message = 'Enter code, name and account type.');
                      return;
                    }
                    update(() { saving = true; message = null; });
                    try {
                      final payload = partyPayload(type: widget.type,
                        code: code.text, name: name.text,
                        accountTypeUlid: selected, isActive: active,
                        contact: contact.text, mobile: mobile.text,
                        address: address.text);
                      if (updating) {
                        await widget.app.api.patch('/api/parties/' + ulid, payload);
                      } else {
                        await widget.app.api.post('/api/parties', payload);
                      }
                      if (sheet.mounted) Navigator.pop(sheet, true);
                    } catch (ex) {
                      if (sheet.mounted) update(() => message = ex.toString());
                    } finally {
                      if (sheet.mounted) update(() => saving = false);
                    }
                  }),
              ],
            )),
          )),
      );
      if (saved == true && mounted) {
        await refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')));
      }
    } finally {
      code.dispose(); name.dispose(); contact.dispose();
      mobile.dispose(); address.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.text.trim().toLowerCase();
    final filtered = rows.where((row) => query.isEmpty ||
      (field(row['name']) + ' ' + field(row['code']))
        .toLowerCase().contains(query));
    return Scaffold(
      appBar: AppBar(title: Text(title),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))]),
      floatingActionButton: can('create') ? FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Add ' + widget.type)) : null,
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          SectionHeading(title),
          TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or code')),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (filtered.isEmpty) const EmptyState(title: 'No matching records')
          else ...filtered.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: EdgeInsets.zero, child: ListTile(
              leading: CircleAvatar(backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person_outline, color: scheme.primary)),
              title: Text(field(row['name'], 'Unnamed'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(field(row['code'])),
              trailing: can('edit') ? const Icon(Icons.chevron_right) : null,
              onTap: can('edit') ? () => edit(record: row) : null,
            )),
          )),
          const SizedBox(height: 85),
        ]),
      ),
    );
  }
}
