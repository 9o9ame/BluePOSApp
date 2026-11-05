import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Master-data forms backed by the actual BluePOS Catalog FormRequests.
/// No money, stock or accounting values are accepted from the device here.
class CatalogMasterConfig {
  const CatalogMasterConfig({
    required this.title,
    required this.apiPath,
    required this.permissionBase,
    this.needsCategory = false,
    this.isUnit = false,
    this.hasDescription = true,
  });

  final String title;
  final String apiPath;
  final String permissionBase;
  final bool needsCategory;
  final bool isUnit;
  final bool hasDescription;

  static const categories = CatalogMasterConfig(
    title: 'Categories', apiPath: '/api/categories',
    permissionBase: 'categories');
  static const subcategories = CatalogMasterConfig(
    title: 'Subcategories', apiPath: '/api/subcategories',
    permissionBase: 'categories', needsCategory: true);
  static const brands = CatalogMasterConfig(
    title: 'Brands', apiPath: '/api/brands',
    permissionBase: 'brands');
  static const units = CatalogMasterConfig(
    title: 'Units', apiPath: '/api/units',
    permissionBase: 'units', isUnit: true, hasDescription: false);
}

Map<String, dynamic> catalogMasterPayload(
  CatalogMasterConfig config, {
  required String name,
  required bool isActive,
  String description = '',
  String? categoryUlid,
  String symbol = '',
  bool allowsDecimal = false,
}) {
  final payload = <String, dynamic>{
    'name': name.trim(),
    'is_active': isActive,
  };
  if (config.hasDescription) payload['description'] = description.trim();
  if (config.needsCategory && categoryUlid != null && categoryUlid.length == 26) {
    payload['category_ulid'] = categoryUlid;
  }
  if (config.isUnit) {
    payload['symbol'] = symbol.trim();
    payload['allows_decimal'] = allowsDecimal;
  }
  return payload;
}

class CatalogMasterScreen extends StatefulWidget {
  const CatalogMasterScreen({
    super.key, required this.app, required this.config,
  });
  final AppController app;
  final CatalogMasterConfig config;

  @override
  State<CatalogMasterScreen> createState() => _CatalogMasterScreenState();
}

class _CatalogMasterScreenState extends State<CatalogMasterScreen> {
  final search = TextEditingController();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = const [];

  bool _permission(String action) =>
      widget.app.hasPermission('${widget.config.permissionBase}.$action') ||
      widget.app.hasPermission('${widget.config.permissionBase}.manage');

  bool get canView => _permission('view');
  bool get canCreate => _permission('create');
  bool get canEdit => _permission('edit');

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    if (!canView) {
      setState(() {
        loading = false;
        error = 'You do not have permission to view this module.';
        rows = const [];
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.app.api.get(widget.config.apiPath);
      if (!mounted) return;
      setState(() => rows = recordsOf(result));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    if (isEdit && !canEdit || !isEdit && !canCreate) return;
    final ulid = field(item?['ulid']);
    if (isEdit && ulid.length != 26) {
      await showApiError(context, 'This record is missing a valid ULID.');
      return;
    }

    var choices = <Map<String, dynamic>>[];
    if (widget.config.needsCategory) {
      try {
        choices = recordsOf(await widget.app.api.get('/api/categories'));
      } catch (ex) {
        if (mounted) await showApiError(context, ex);
        return;
      }
      if (!mounted) return;
    }

    final name = TextEditingController(text: field(item?['name']));
    final description = TextEditingController(text: field(item?['description']));
    final symbol = TextEditingController(text: field(item?['symbol']));
    var active = item?['is_active'] != false;
    var allowsDecimal = item?['allows_decimal'] == true;
    final category = objectOf(item?['category']);
    var categoryUlid = field(item?['category_ulid'],
      field(category['ulid']));
    if (!choices.any((choice) => field(choice['ulid']) == categoryUlid)) {
      categoryUlid = '';
    }
    var saving = false;
    String? formError;
    try {
      final didSave = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, updateSheet) => Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isEdit ? 'Edit ${widget.config.title}' :
                  'Add ${widget.config.title}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: name, maxLength: 160,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name *')),
                if (widget.config.hasDescription) ...[
                  const SizedBox(height: 8),
                  TextField(controller: description, maxLength: 255,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description')),
                ],
                if (widget.config.isUnit) ...[
                  const SizedBox(height: 8),
                  TextField(controller: symbol, maxLength: 16,
                    decoration: const InputDecoration(labelText: 'Symbol *')),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow decimal quantities'),
                    value: allowsDecimal,
                    onChanged: saving ? null :
                      (value) => updateSheet(() => allowsDecimal = value)),
                ],
                if (widget.config.needsCategory) ...[
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: categoryUlid.isEmpty ? null : categoryUlid,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: choices.map((choice) => DropdownMenuItem(
                      value: field(choice['ulid']),
                      child: Text(field(choice['name']),
                        overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: saving ? null :
                      (next) => updateSheet(() => categoryUlid = next ?? ''),
                  ),
                ],
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: saving ? null :
                    (value) => updateSheet(() => active = value)),
                if (formError != null) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(formError!, style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error)),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  icon: saving ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)) :
                    const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Saving…' :
                    (isEdit ? 'Save changes' : 'Create')),
                  onPressed: saving ? null : () async {
                    final label = name.text.trim();
                    if (label.isEmpty || widget.config.isUnit &&
                        symbol.text.trim().isEmpty ||
                        widget.config.needsCategory && categoryUlid.length != 26) {
                      updateSheet(() => formError = 'Complete all required fields.');
                      return;
                    }
                    updateSheet(() {
                      saving = true;
                      formError = null;
                    });
                    try {
                      final payload = catalogMasterPayload(widget.config,
                        name: label, description: description.text,
                        symbol: symbol.text,
                        isActive: active, allowsDecimal: allowsDecimal,
                        categoryUlid: categoryUlid);
                      if (isEdit) {
                        await widget.app.api.patch('${widget.config.apiPath}/$ulid', payload);
                      } else {
                        await widget.app.api.post(widget.config.apiPath, payload);
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                    } catch (ex) {
                      if (sheetContext.mounted) {
                        updateSheet(() => formError = ex.toString());
                      }
                    } finally {
                      if (sheetContext.mounted) updateSheet(() => saving = false);
                    }
                  },
                ),
              ],
            )),
          ),
        ),
      );
      if (didSave == true && mounted) {
        await reload();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')));
      }
    } finally {
      name.dispose();
      description.dispose();
      symbol.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.text.trim().toLowerCase();
    final filtered = rows.where((row) =>
      query.isEmpty || '${field(row['name'])} ${field(row['code'])}'
        .toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.title), actions: [
        IconButton(onPressed: reload, tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded)),
      ]),
      floatingActionButton: canCreate ? FloatingActionButton.extended(
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add')) : null,
      body: RefreshIndicator(onRefresh: reload,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SectionHeading(widget.config.title),
          TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search by name or code')),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: reload)
          else if (filtered.isEmpty) EmptyState(
            title: rows.isEmpty ? 'No records yet' : 'No matching records',
            subtitle: 'Use a different search term.')
          else ...filtered.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(widget.config.isUnit
                    ? Icons.straighten_rounded
                    : widget.config.needsCategory
                      ? Icons.layers_outlined : Icons.folder_open_outlined,
                    color: scheme.primary)),
                title: Text(field(row['name'], '—'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text([
                  field(row['code']),
                  if (widget.config.isUnit) field(row['symbol']),
                  if (widget.config.needsCategory)
                    field(objectOf(row['category'])['name']),
                ].where((part) => part.isNotEmpty).join('  •  ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(row['is_active'] == false
                    ? Icons.remove_circle_outline : Icons.check_circle_outline,
                    size: 18, color: row['is_active'] == false
                      ? scheme.error : scheme.primary),
                  if (canEdit) const Icon(Icons.chevron_right_rounded),
                ]),
                onTap: canEdit ? () => openEditor(item: row) : null,
              )),
          )),
          const SizedBox(height: 90),
        ])),
    );
  }
}
