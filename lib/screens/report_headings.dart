import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Tenant-scoped report template metadata management. Template HTML is
/// intentionally left intact: mobile metadata edits must never overwrite the
/// existing rich text designed in the frozen web report heading editor.
class ReportHeadingsScreen extends StatefulWidget {
  const ReportHeadingsScreen({super.key, required this.app});
  final AppController app;
  @override
  State<ReportHeadingsScreen> createState() => _ReportHeadingsScreenState();
}

class _ReportHeadingsScreenState extends State<ReportHeadingsScreen> {
  List<Map<String, dynamic>> items = const [];
  bool busy = true;
  String? error;
  final search = TextEditingController();
  int requestSerial = 0;

  bool get canManage => widget.app.hasPermission('settings.manage');

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
    final serial = ++requestSerial;
    setState(() { busy = true; error = null; });
    try {
      final response = await widget.app.api.get('/api/report-headings');
      if (mounted && serial == requestSerial) {
        setState(() => items = recordsOf(response));
      }
    } catch (ex) {
      if (mounted && serial == requestSerial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && serial == requestSerial) setState(() => busy = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    if (!canManage) return;
    final creating = existing == null;
    final code = TextEditingController(text: field(existing?['head_id']));
    final usedFor = TextEditingController(text: field(existing?['used_for']));
    final layout = <String, dynamic>{
      'margin': 'normal',
      'orientation': 'portrait',
      'page_size': 'a4',
      'columns': 1,
      'line_numbers': false,
      'page_color': '#ffffff',
      ...objectOf(existing?['layout_settings']),
    };
    var saving = false;
    String? formError;

    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, update) => Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16,
              MediaQuery.viewInsetsOf(sheet).bottom + 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheet).height * .84),
              child: ListView(shrinkWrap: true, children: [
                Text(creating ? 'New report heading' : 'Edit report heading',
                  style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 7),
                Text('Existing rich template content is preserved.',
                  style: TextStyle(fontSize: 11,
                    color: Theme.of(sheet).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextField(
                  controller: code,
                  maxLength: 40,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Heading ID *',
                    helperText: 'Letters, numbers, underscore, hyphen')),
                const SizedBox(height: 8),
                TextField(
                  controller: usedFor,
                  maxLength: 120,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Used for *')),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: field(layout['margin'], 'normal'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Margins'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'narrow', child: Text('Narrow')),
                    DropdownMenuItem(value: 'wide', child: Text('Wide')),
                  ],
                  onChanged: saving ? null : (v) {
                    if (v != null) update(() => layout['margin'] = v);
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: field(layout['orientation'], 'portrait'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Orientation'),
                  items: const [
                    DropdownMenuItem(value: 'portrait', child: Text('Portrait')),
                    DropdownMenuItem(value: 'landscape', child: Text('Landscape')),
                  ],
                  onChanged: saving ? null : (v) {
                    if (v != null) update(() => layout['orientation'] = v);
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: field(layout['page_size'], 'a4'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Page size'),
                  items: const [
                    DropdownMenuItem(value: 'a4', child: Text('A4')),
                    DropdownMenuItem(value: 'letter', child: Text('Letter')),
                    DropdownMenuItem(value: 'legal', child: Text('Legal')),
                  ],
                  onChanged: saving ? null : (v) {
                    if (v != null) update(() => layout['page_size'] = v);
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<int>(
                  initialValue: (layout['columns'] is int &&
                    (layout['columns'] as int) >= 1 &&
                    (layout['columns'] as int) <= 3)
                    ? layout['columns'] as int : 1,
                  decoration: const InputDecoration(labelText: 'Columns'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3')),
                  ],
                  onChanged: saving ? null : (v) {
                    if (v != null) update(() => layout['columns'] = v);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Line numbers'),
                  value: layout['line_numbers'] == true,
                  onChanged: saving ? null :
                    (v) => update(() => layout['line_numbers'] = v)),
                if (formError != null)
                  Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Text(formError!,
                      style: TextStyle(color: Theme.of(sheet).colorScheme.error))),
                FilledButton.icon(
                  onPressed: saving ? null : () async {
                    final id = code.text.trim();
                    final usage = usedFor.text.trim();
                    if (!RegExp(r'^[A-Za-z0-9_-]{1,40}$').hasMatch(id) ||
                      usage.isEmpty || usage.length > 120) {
                      update(() => formError = 'Enter a valid ID and usage.');
                      return;
                    }
                    update(() { saving = true; formError = null; });
                    try {
                      final payload = <String, dynamic>{
                        'head_id': id,
                        'used_for': usage,
                        'layout_settings': layout,
                      };
                      if (creating) {
                        await widget.app.api.post('/api/report-headings', payload);
                      } else {
                        final ulid = field(existing['ulid']);
                        if (ulid.length != 26) {
                          throw const FormatException('Invalid heading.');
                        }
                        await widget.app.api.patch(
                          '/api/report-headings/$ulid', payload);
                      }
                      if (sheet.mounted) Navigator.pop(sheet, true);
                    } catch (ex) {
                      if (sheet.mounted) update(() => formError = ex.toString());
                    } finally {
                      if (sheet.mounted) update(() => saving = false);
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Saving…' : 'Save heading')),
              ]),
            ),
          ),
        ),
      );
      if (saved == true && mounted) await load();
    } finally {
      code.dispose();
      usedFor.dispose();
    }
  }

  Future<void> remove(Map<String, dynamic> item) async {
    if (!canManage) return;
    final ulid = field(item['ulid']);
    if (ulid.length != 26) return;
    final accepted = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete report heading?'),
        content: Text('Remove ${field(item['head_id'])}? '
          'This does not alter previously posted business records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete')),
        ],
      ));
    if (accepted != true || !mounted) return;
    try {
      await widget.app.api.request('DELETE', '/api/report-headings/$ulid');
      if (mounted) await load();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final q = search.text.trim().toLowerCase();
    final results = items.where((item) =>
      '${field(item['head_id'])} ${field(item['used_for'])}'
        .toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Report Headings'), actions: [
        IconButton(onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh headings'),
      ]),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: () => edit(), icon: const Icon(Icons.add_rounded),
        label: const Text('New Heading')) : null,
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Report templates'),
          TextField(controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search heading ID or usage')),
          const SizedBox(height: 13),
          if (busy) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else if (results.isEmpty) const EmptyState(
            title: 'No headings found',
            subtitle: 'Try another search.')
          else ...results.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.description_outlined,
                      color: colors.primary, size: 23),
                    const SizedBox(width: 9),
                    Expanded(child: Text(field(item['head_id']),
                      style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (canManage) IconButton(
                      tooltip: 'Edit heading',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => edit(item)),
                    if (canManage) IconButton(
                      tooltip: 'Delete heading',
                      icon: Icon(Icons.delete_outline_rounded,
                        color: colors.error),
                      onPressed: () => remove(item)),
                  ]),
                  Text(field(item['used_for']),
                    style: TextStyle(fontSize: 12,
                      color: colors.onSurfaceVariant)),
                  const SizedBox(height: 5),
                  Text(
                    '${field(objectOf(item['layout_settings'])['orientation'], 'portrait')} '
                    '· ${field(objectOf(item['layout_settings'])['page_size'], 'a4')}',
                    style: TextStyle(fontSize: 11,
                      color: colors.onSurfaceVariant)),
                ]),
              ),
          )),
          const SizedBox(height: 72),
        ],
      )),
    );
  }
}
