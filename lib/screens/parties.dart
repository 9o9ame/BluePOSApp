import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'customer_detail.dart';

/// Exact party endpoint contract: server owns tenant context and linked accounts.
Map<String, dynamic> partyPayload({
  required String type, required String code, required String name,
  required String accountTypeUlid, required bool isActive,
  String contact = '', String mobile = '', String address = '',
  String area = '',
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
    'area': area.trim(),
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
  bool activeOnly = false;
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
    final area = TextEditingController(text: field(record?['area']));
    var selected = field(record?['account_type_ulid']);
    if (!accounts.any((row) => field(row['ulid']) == selected)) selected = '';
    var active = record?['is_active'] != false;
    var saving = false;
    String? message;
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => StatefulBuilder(
          builder: (sheet, update) => Scaffold(
            appBar: AppBar(title: Text(updating ? 'Edit ${widget.type}' :
              'Add ${widget.type}')),
            body: SafeArea(child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16,
                MediaQuery.viewInsetsOf(sheet).bottom + 22),
              child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(child: Icon(Icons.person_add_alt_1_rounded,
                  size: 54, color: Theme.of(sheet).colorScheme.primary)),
                const SizedBox(height: 14),
                Text(updating ? 'Edit ${widget.type}' : 'Add ${widget.type}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(controller: code, maxLength: 64,
                  key: const ValueKey('party-editor-code'),
                  decoration: const InputDecoration(labelText: 'Code *')),
                Text('The customer code is required by the BluePOS API.',
                  style: TextStyle(fontSize: 11,
                    color: Theme.of(sheet).colorScheme.onSurfaceVariant)),
                TextField(controller: name, maxLength: 180,
                  key: const ValueKey('party-editor-name'),
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
                if (widget.type == 'customer')
                  TextField(controller: area, maxLength: 120,
                    key: const ValueKey('party-editor-area'),
                    decoration: const InputDecoration(
                      labelText: 'City / Area')),
                TextField(controller: address, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address')),
                const Text('Status *',
                  style: TextStyle(fontWeight: FontWeight.w800)),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Active')),
                    ButtonSegment(value: false, label: Text('Inactive')),
                  ],
                  selected: {active},
                  onSelectionChanged: saving ? null :
                    (values) => update(() => active = values.first)),
                if (message != null) Text(message!, style: TextStyle(
                  color: Theme.of(sheet).colorScheme.error)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('party-editor-save'),
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
                        address: address.text, area: area.text);
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
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(sheet, false),
                  child: const Text('Cancel')),
                const SizedBox(height: 12),
              ],
            )),
          )),
        ))));
      if (saved == true && mounted) {
        await refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')));
      }
    } finally {
      code.dispose(); name.dispose(); contact.dispose();
      mobile.dispose(); address.dispose(); area.dispose();
    }
  }

  Future<void> openCustomerDetails(Map<String, dynamic> record) async {
    if (widget.type != 'customer' || !can('view')) return;
    final ulid = field(record['ulid']);
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid)) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
      CustomerDetailScreen(app: widget.app, customerUlid: ulid,
        onEdit: can('edit') ? () {
          Navigator.of(context).pop();
          edit(record: record);
        } : null)));
    if (mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCustomer = widget.type == 'customer';
    final query = search.text.trim().toLowerCase();
    final filtered = rows.where((row) =>
      (!activeOnly || row['is_active'] != false) &&
      (query.isEmpty ||
        ('${field(row['name'])} ${field(row['code'])} ${field(row['mobile'])}')
          .toLowerCase().contains(query))).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title),
        actions: [IconButton(onPressed: refresh, tooltip: 'Refresh',
          icon: const Icon(Icons.refresh))]),
      floatingActionButton: can('create') ? FloatingActionButton.extended(
        key: const ValueKey('party-add'),
        onPressed: () => edit(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(isCustomer ? 'Add Customer' : 'Add $title')) : null,
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        key: const ValueKey('party-directory-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16), children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(
              key: const ValueKey('party-search'),
              controller: search, onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search ${title.toLowerCase()}...'))),
            if (isCustomer) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Active customers filter',
                key: const ValueKey('party-filter'),
                onPressed: () => setState(() => activeOnly = !activeOnly),
                icon: Icon(activeOnly ? Icons.filter_alt
                  : Icons.filter_alt_outlined)),
            ],
          ]),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (filtered.isEmpty)
            const EmptyState(title: 'No matching records')
          else ...filtered.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: EdgeInsets.zero,
              child: InkWell(
                key: ValueKey('party-row-${field(row['ulid'])}'),
                onTap: isCustomer ? () => openCustomerDetails(row)
                  : can('edit') ? () => edit(record: row) : null,
                child: Padding(padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(height: 49, width: 49,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.storefront_outlined,
                        color: scheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(field(row['name'], 'Unnamed'),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(field(row['code']), style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                        if (isCustomer && field(row['area']).isNotEmpty)
                          Text(field(row['area']), maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant,
                              fontSize: 11)),
                        if (isCustomer && field(row['mobile']).isNotEmpty)
                          Text(field(row['mobile']), maxLines: 1,
                            style: TextStyle(color: scheme.onSurfaceVariant,
                              fontSize: 11)),
                      ])),
                    if (isCustomer && row['credit_limit_amount'] != null)
                      Text('Limit: ${field(row['credit_limit_amount'])}',
                        style: TextStyle(fontSize: 11,
                          color: scheme.primary, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              )),
          )),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }
}
