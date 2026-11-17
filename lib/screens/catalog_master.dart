import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';

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
  bool showFilters = false;
  bool activeOnly = false;
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
    int previewIcon = 0;
    int previewColor = 0;
    final categoryPreviewIcons = <IconData>[
      Icons.shopping_basket_rounded, Icons.sell_rounded,
      Icons.restaurant_rounded, Icons.inventory_2_rounded,
      Icons.grid_view_rounded,
    ];
    final categoryPreviewColors = <Color>[
      const Color(0xFFFF9900), const Color(0xFF5A9DFF),
      const Color(0xFF42C875), const Color(0xFF984AF7),
      const Color(0xFFF5759B), const Color(0xFF60D2EA),
    ];
    final singular = widget.config.title == 'Categories' ? 'Category'
      : widget.config.title == 'Subcategories' ? 'Subcategory'
      : widget.config.title == 'Brands' ? 'Brand'
      : widget.config.title == 'Units' ? 'Unit'
      : widget.config.title;
    final formTitle = isEdit ? 'Edit $singular' : 'Add $singular';
    try {
      final didSave = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => StatefulBuilder(
          builder: (sheetContext, updateSheet) => Scaffold(
            backgroundColor: BpReferenceStyle.of(sheetContext).page,
            appBar: widget.config.apiPath == '/api/categories'
              ? BpReferenceSubpageAppBar(title: formTitle)
              : AppBar(centerTitle: true,
                  title: Text(formTitle, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900))),
            body: SafeArea(child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
              child: SingleChildScrollView(child: Container(
                padding: widget.config.apiPath == '/api/categories'
                  ? const EdgeInsets.all(13) : EdgeInsets.zero,
                decoration: widget.config.apiPath == '/api/categories'
                  ? BpReferenceStyle.of(sheetContext).card(radius: 19)
                  : null,
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.config.apiPath == '/api/categories') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category Icon & Color',
                          style: TextStyle(fontWeight: FontWeight.w900,
                            color: BpReferenceStyle.of(sheetContext).ink,
                            fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Container(
                            width: 66, height: 66,
                            decoration: BoxDecoration(
                              color: categoryPreviewColors[previewColor]
                                .withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(14)),
                            child: Icon(categoryPreviewIcons[previewIcon],
                              size: 35,
                              color: categoryPreviewColors[previewColor])),
                          const SizedBox(width: 10),
                          Expanded(child: Wrap(spacing: 4, runSpacing: 4,
                            children: [
                              for (var i = 0; i < categoryPreviewIcons.length; i++)
                                InkWell(
                                  onTap: () => updateSheet(() => previewIcon = i),
                                  borderRadius: BorderRadius.circular(9),
                                  child: Container(
                                    width: 35, height: 35,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      color: i == previewIcon
                                        ? BpReferenceStyle.of(sheetContext).input
                                        : BpReferenceStyle.of(sheetContext).surface,
                                      border: Border.all(color: i == previewIcon
                                        ? const Color(0xFF087AF8)
                                        : BpReferenceStyle.of(sheetContext).line)),
                                    child: Icon(categoryPreviewIcons[i],
                                      size: 18,
                                      color: BpReferenceStyle.of(sheetContext).ink)),
                                ),
                            ])),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6,
                          children: [
                            for (var i = 0; i < categoryPreviewColors.length; i++)
                              InkWell(
                                onTap: () => updateSheet(() => previewColor = i),
                                child: Container(width: 25, height: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: categoryPreviewColors[i],
                                    border: Border.all(
                                      color: i == previewColor
                                        ? const Color(0xFF1045C8)
                                        : Colors.white, width: 2.5))),
                              ),
                          ]),
                        const SizedBox(height: 6),
                        Text('Icon and color are preview only; '
                          'the current Category API does not save them.',
                          style: TextStyle(fontSize: 10,
                            color: BpReferenceStyle.of(sheetContext).muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 12),
                  Center(child: Icon(
                    widget.config.needsCategory ? Icons.layers_outlined
                      : widget.config.apiPath == '/api/brands'
                        ? Icons.sell_outlined
                        : widget.config.isUnit ? Icons.inventory_2_outlined
                        : Icons.category_outlined,
                    size: 56,
                    color: Theme.of(sheetContext).colorScheme.primary)),
                  const SizedBox(height: 22),
                ],
                if (widget.config.apiPath != '/api/categories')
                  Text(formTitle, style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(
                  key: const ValueKey('catalog-editor-name'),
                  controller: name, maxLength: 160,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '$singular Name *',
                    hintText: 'Enter name')),
                if (widget.config.apiPath == '/api/categories' ||
                    widget.config.needsCategory ||
                    widget.config.apiPath == '/api/brands') ...[
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Code'),
                    child: Text(isEdit
                      ? field(item['code'], 'Automatically generated')
                      : 'Automatically generated',
                      style: TextStyle(color:
                        Theme.of(sheetContext).colorScheme.onSurfaceVariant)),
                  ),
                  Text('The BluePOS server generates this code.',
                    style: TextStyle(fontSize: 11, color:
                      Theme.of(sheetContext).colorScheme.onSurfaceVariant)),
                ],
                if (widget.config.hasDescription) ...[
                  const SizedBox(height: 8),
                  TextField(controller: description, maxLength: 255,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description')),
                ],
                if (widget.config.isUnit) ...[
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('catalog-editor-unit-symbol'),
                    controller: symbol, maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: 'Unit Code / Short Name *')),
                  const SizedBox(height: 6),
                  Text('A base conversion factor is not supported by the current Units API.',
                    style: TextStyle(fontSize: 11, color:
                      Theme.of(sheetContext).colorScheme.onSurfaceVariant)),
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
                const SizedBox(height: 10),
                const Text('Status *',
                  style: TextStyle(fontWeight: FontWeight.w800)),
                SegmentedButton<bool>(
                  key: const ValueKey('catalog-editor-status'),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Active')),
                    ButtonSegment(value: false, label: Text('Inactive')),
                  ],
                  selected: {active},
                  onSelectionChanged: saving ? null :
                    (values) => updateSheet(() => active = values.first),
                ),
                if (formError != null) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(formError!, style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error)),
                ),
                const SizedBox(height: 12),
                if (widget.config.apiPath == '/api/categories')
                  const Text('Category changes are validated and saved '
                    'by BluePOS server.', style: TextStyle(
                      color: Color(0xFF6D7C98), fontSize: 10.5)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('catalog-editor-save'),
                  icon: saving ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)) :
                    const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Saving…' : 'Save $singular'),
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
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: saving ? null :
                    () => Navigator.of(sheetContext).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 12),
              ],
            ))),
          )),
        ),
      )));
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

  // Screen 14 keeps the existing category API, RBAC and edit flow.
  // Reference icons are decorative: no unsupported category icon data is sent.
  Widget _categoryReferenceScreen(
      BuildContext context, List<Map<String, dynamic>> filtered) {
    final style = BpReferenceStyle.of(context);
    const tones = <Color>[
      Color(0xFF00BD66), Color(0xFF158EF7),
      Color(0xFFFF9810), Color(0xFF8D4CF6),
      Color(0xFF26A8F2), Color(0xFF00A77D),
    ];
    const icons = <IconData>[
      Icons.shopping_cart_rounded, Icons.local_drink_rounded,
      Icons.fastfood_rounded, Icons.cleaning_services_rounded,
      Icons.ac_unit_rounded, Icons.category_rounded,
    ];
    return Scaffold(
      backgroundColor: style.page,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Categories', style: TextStyle(
          color: style.ink, fontSize: 18, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: reload, tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: canCreate
        ? SizedBox(width: 94, height: 94,
            child: FloatingActionButton(
              key: const ValueKey('catalog-add'),
              backgroundColor: const Color(0xFF04AA54),
              foregroundColor: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white, width: 2.5)),
              onPressed: () => openEditor(),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 31),
                  Text('Add Category', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
            ))
        : null,
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            key: const ValueKey('catalog-master-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 105),
            children: [
              Row(children: [
                Expanded(child: TextField(
                  key: const ValueKey('catalog-search'),
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: style.search('Search categories...',
                    prefixIcon: const Icon(Icons.search_rounded)))),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: const ValueKey('catalog-status-filter'),
                  tooltip: 'Filter status',
                  onPressed: () => setState(() => showFilters = !showFilters),
                  icon: const Icon(Icons.filter_alt_outlined)),
              ]),
              if (showFilters) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  ChoiceChip(label: const Text('All'),
                    selected: !activeOnly,
                    onSelected: (_) => setState(() => activeOnly = false)),
                  ChoiceChip(label: const Text('Active'),
                    selected: activeOnly,
                    onSelected: (_) => setState(() => activeOnly = true)),
                ]),
              ],
              const SizedBox(height: 13),
              if (loading) pageLoading()
              else if (error != null) FailureState(message: error!, retry: reload)
              else if (filtered.isEmpty)
                EmptyState(
                  title: rows.isEmpty ? 'No categories yet' : 'No matching categories',
                  subtitle: 'Try a different search or status filter.')
              else
                for (var i = 0; i < filtered.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('catalog-row-${field(filtered[i]['ulid'])}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: canEdit
                          ? () => openEditor(item: filtered[i]) : null,
                        child: Container(
                          height: 67,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: style.card(),
                          child: Row(children: [
                            Container(
                              width: 47, height: 47,
                              decoration: BoxDecoration(
                                color: tones[i % tones.length]
                                  .withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(12)),
                              child: Icon(icons[i % icons.length], size: 26,
                                color: tones[i % tones.length])),
                            const SizedBox(width: 12),
                            Container(height: 37, width: 1,
                              color: style.line),
                            const SizedBox(width: 11),
                            Expanded(child: Text(field(filtered[i]['name'], '—'),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: style.ink,
                                fontSize: 15, fontWeight: FontWeight.w900))),
                            if (filtered[i]['is_active'] == false)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.pause_circle_outline,
                                  color: Color(0xFFE07065), size: 18)),
                            if (canEdit) Icon(Icons.chevron_right_rounded,
                              color: style.ink),
                          ]),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: IgnorePointer(child: AuthReferenceWaves(height: 54))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.text.trim().toLowerCase();
    final config = widget.config;
    final filtered = rows.where((row) {
      if (activeOnly && row['is_active'] == false) return false;
      return query.isEmpty || '${field(row['name'])} ${field(row['code'])}'
          .toLowerCase().contains(query);
    }).toList();
    final isSub = config.needsCategory;
    final isBrand = config.apiPath == '/api/brands';
    final icon = isSub ? Icons.layers_outlined
      : isBrand ? Icons.sell_outlined : config.isUnit
      ? Icons.straighten_rounded : Icons.category_outlined;
    final singular = config.title == 'Categories' ? 'Category'
      : config.title == 'Subcategories' ? 'Subcategory'
      : config.title == 'Brands' ? 'Brand' : config.title;
    if (config.apiPath == '/api/categories') {
      return _categoryReferenceScreen(context, filtered);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
        actions: [
          IconButton(onPressed: reload, tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: canCreate ? FloatingActionButton.extended(
        key: const ValueKey('catalog-add'),
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add $singular')) : null,
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('catalog-master-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: Text(config.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900))),
              Icon(icon, color: scheme.primary, size: 26),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextField(
                key: const ValueKey('catalog-search'),
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search ${config.title.toLowerCase()}...'))),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('catalog-status-filter'),
                tooltip: 'Filter status',
                onPressed: () => setState(() => showFilters = !showFilters),
                icon: const Icon(Icons.filter_alt_outlined)),
            ]),
            if (showFilters) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: !activeOnly,
                  onSelected: (_) => setState(() => activeOnly = false)),
                ChoiceChip(
                  label: const Text('Active'),
                  selected: activeOnly,
                  onSelected: (_) => setState(() => activeOnly = true)),
              ]),
            ],
            const SizedBox(height: 13),
            if (!loading && error == null)
              Text('${filtered.length} ${config.title.toLowerCase()}',
                style: TextStyle(fontSize: 12,
                  color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            if (loading) pageLoading()
            else if (error != null)
              FailureState(message: error!, retry: reload)
            else if (filtered.isEmpty)
              EmptyState(
                title: rows.isEmpty ? 'No records yet' : 'No matching records',
                subtitle: 'Try a different search or status filter.')
            else
              ...filtered.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    key: ValueKey('catalog-row-${field(row['ulid'])}'),
                    onTap: canEdit ? () => openEditor(item: row) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                      child: Row(children: [
                        Container(
                          height: 49, width: 49,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(13)),
                          child: Icon(icon, size: 26,
                            color: scheme.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field(row['name'], '—'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                            if (field(row['code']).isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text('Code: ${field(row['code'])}',
                                style: TextStyle(fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                            ],
                            if (config.isUnit && field(row['symbol']).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(field(row['symbol']),
                                style: TextStyle(fontSize: 12,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800)),
                            ],
                            if (isSub) ...[
                              const SizedBox(height: 4),
                              Text('Parent: ${field(objectOf(row['category'])['name'], 'Not available')}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                            ],
                          ],
                        )),
                        const SizedBox(width: 8),
                        if (row['is_active'] == false)
                          Icon(Icons.remove_circle_outline,
                            color: scheme.error, size: 18),
                        if (canEdit)
                          Icon(Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant),
                      ]),
                    ),
                  ),
                ),
              )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
