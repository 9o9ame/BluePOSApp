import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';
import 'notifications.dart';

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

/// Compact icon-label-input row used by the approved catalog form references.
class _CatalogReferenceFieldTile extends StatelessWidget {
  const _CatalogReferenceFieldTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(8, 7, 9, 8),
      decoration: style.card(radius: 15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 37, height: 43,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: tint, size: 21),
        ),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w900,
              color: style.ink)),
            const SizedBox(height: 3),
            child,
          ],
        )),
      ]),
    );
  }
}

/// Soft green/neutral status selector from the mobile form references.
class _CatalogReferenceStatus extends StatelessWidget {
  const _CatalogReferenceStatus({
    super.key,
    required this.active,
    required this.enabled,
    required this.onChanged,
  });
  final bool active;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Row(children: [
      for (final value in [true, false]) ...[
        if (!value) const SizedBox(width: 8),
        Expanded(child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged(value) : null,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: active == value
                    ? [const Color(0xFFEAFFF0), const Color(0xFFBCF6D6)]
                    : [style.surface, style.surfaceEnd]),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: active == value
                  ? const Color(0xFF90E7B6) : style.line),
                boxShadow: [BoxShadow(
                  color: style.shadow.withValues(alpha: .45),
                  blurRadius: 5, offset: const Offset(0, 3))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active == value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                    size: 17, color: active == value
                      ? const Color(0xFF08A14B) : style.muted),
                  const SizedBox(width: 6),
                  Text(value ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: 12,
                      fontWeight: active == value
                        ? FontWeight.w900 : FontWeight.w600,
                      color: active == value
                        ? const Color(0xFF103C29) : style.ink)),
                ]),
            ),
          ),
        )),
      ],
    ]);
  }
}

// Icons and tints represent actual returned names, not invented catalog rows.
Color _catalogRowTone(String name, int index) {
  final n = name.trim().toLowerCase();
  if (['piece', 'chips', "lay's"].contains(n)) {
    return const Color(0xFFFFA313);
  }
  if (['carton', 'milk', 'pepsi'].contains(n)) {
    return const Color(0xFF078DF4);
  }
  if (['box', 'soft drinks', 'lu'].contains(n)) {
    return const Color(0xFF9344EC);
  }
  if (['bottle', 'frozen foods'].contains(n)) {
    return const Color(0xFF0FBCE3);
  }
  if (['kilogram', 'cleaning products', 'national'].contains(n)) {
    return const Color(0xFF0ABB60);
  }
  if (['liter', 'biscuits', 'coca cola'].contains(n)) {
    return const Color(0xFFF34A7F);
  }
  const fallback = <Color>[
    Color(0xFF078DF4), Color(0xFFFFA313),
    Color(0xFF9344EC), Color(0xFF0ABB60),
    Color(0xFFF34A7F), Color(0xFF0FBCE3),
  ];
  return fallback[index % fallback.length];
}

IconData _catalogRowIcon(String name, {
  required bool isSub,
  required bool isBrand,
}) {
  switch (name.trim().toLowerCase()) {
    case 'piece': return Icons.inventory_2_rounded;
    case 'carton': return Icons.all_inbox_rounded;
    case 'box': return Icons.inbox_rounded;
    case 'bottle': return Icons.water_drop_rounded;
    case 'kilogram': return Icons.scale_rounded;
    case 'liter': return Icons.local_drink_rounded;
    case 'soft drinks': return Icons.local_drink_rounded;
    case 'chips': return Icons.fastfood_rounded;
    case 'biscuits': return Icons.cookie_rounded;
    case 'milk': return Icons.local_drink_rounded;
    case 'frozen foods': return Icons.ac_unit_rounded;
    case 'cleaning products': return Icons.cleaning_services_rounded;
  }
  if (isSub) return Icons.layers_rounded;
  if (isBrand) return Icons.sell_rounded;
  return Icons.inventory_2_rounded;
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
  final searchFocus = FocusNode();
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
    searchFocus.dispose();
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
    final isSubForm = widget.config.needsCategory;
    final isBrandForm = widget.config.apiPath == '/api/brands';
    final categoryPreviewIcons = isSubForm
      ? <IconData>[
          Icons.fastfood_rounded, Icons.local_drink_rounded,
          Icons.cookie_rounded, Icons.icecream_rounded,
          Icons.set_meal_rounded, Icons.cleaning_services_rounded]
      : isBrandForm
        ? <IconData>[
            Icons.sell_rounded, Icons.shopping_bag_outlined,
            Icons.workspace_premium_outlined,
            Icons.storefront_outlined, Icons.star_outline_rounded]
        : <IconData>[
            Icons.shopping_basket_rounded, Icons.sell_rounded,
            Icons.restaurant_rounded, Icons.inventory_2_rounded,
            Icons.grid_view_rounded];
    final categoryPreviewColors = isSubForm || isBrandForm
      ? <Color>[
          const Color(0xFF9747FF), const Color(0xFF389DFF),
          const Color(0xFF17C8E7), const Color(0xFF4DDF86),
          const Color(0xFFFFD43D), const Color(0xFFFF963B),
          const Color(0xFFF576A4), const Color(0xFFE35A78)]
      : <Color>[
          const Color(0xFFFF9900), const Color(0xFF5A9DFF),
          const Color(0xFF42C875), const Color(0xFF984AF7),
          const Color(0xFFF5759B), const Color(0xFF60D2EA)];
    final singular = widget.config.title == 'Categories' ? 'Category'
      : widget.config.title == 'Subcategories' ? 'Subcategory'
      : widget.config.title == 'Brands' ? 'Brand'
      : widget.config.title == 'Units' ? 'Unit'
      : widget.config.title;
    final formTitle = isEdit ? 'Edit $singular' : 'Add $singular';
    Future<void> submit(BuildContext sheetContext,
        StateSetter updateSheet) async {
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
    }
    try {
      final didSave = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => StatefulBuilder(
          builder: (sheetContext, updateSheet) => Scaffold(
            backgroundColor: BpReferenceStyle.of(sheetContext).page,
            appBar: BpReferenceSubpageAppBar(
              title: formTitle,
              onNotifications: () => Navigator.of(sheetContext).push(
                MaterialPageRoute(builder: (_) =>
                  NotificationsScreen(app: widget.app)))),
            // Keep the decorative footer below the scrollable form,
            // directly above the pinned actions. Never paint behind Status.
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuthReferenceWaves(height: 48),
                SafeArea(top: false,
                  child: Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                decoration: BoxDecoration(
                  color: BpReferenceStyle.of(sheetContext).surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23)),
                  border: Border.all(
                    color: BpReferenceStyle.of(sheetContext).line),
                  boxShadow: const [BoxShadow(
                    color: Color(0x253A74D3), blurRadius: 16,
                    offset: Offset(0, -4))]),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 51),
                      foregroundColor: BpReferenceStyle.of(sheetContext).ink,
                      side: BorderSide(
                        color: BpReferenceStyle.of(sheetContext).line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                    onPressed: saving ? null :
                      () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 9),
                  Expanded(child: FilledButton.icon(
                    key: const ValueKey('catalog-editor-save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006AF5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                    onPressed: saving ? null :
                      () => submit(sheetContext, updateSheet),
                    icon: saving ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving…' : 'Save $singular'),
                  )),
                ]),
              )),
              ],
            ),
            body: Stack(children: [
              const Positioned(top: 0, right: 0,
                child: BpReferenceTopAccent()),
              SafeArea(child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
              child: SingleChildScrollView(child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BpReferenceStyle.of(sheetContext).card(radius: 19),
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
                  const SizedBox(height: 1),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BpReferenceStyle.of(sheetContext).surface,
                      border: Border.all(color:
                        BpReferenceStyle.of(sheetContext).line),
                      borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.config.apiPath == '/api/brands'
                          ? 'Brand Icon & Color' : 'Choose Icon & Color',
                          style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: BpReferenceStyle.of(sheetContext).ink)),
                        if (widget.config.apiPath == '/api/brands')
                          Padding(
                            padding: const EdgeInsets.only(top: 3, bottom: 7),
                            child: Text('Choose an icon and theme color for the brand.',
                              style: TextStyle(fontSize: 10,
                                color: BpReferenceStyle.of(sheetContext).muted))),
                        const SizedBox(height: 7),
                        Row(children: [
                          Container(width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: categoryPreviewColors[previewColor]
                                .withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(15)),
                            child: Icon(categoryPreviewIcons[previewIcon],
                              size: 34,
                              color: categoryPreviewColors[previewColor])),
                          const SizedBox(width: 9),
                          Expanded(child: Wrap(spacing: 4, runSpacing: 4,
                            children: [
                              for (var i = 0; i < categoryPreviewIcons.length; i++)
                                InkWell(
                                  onTap: () => updateSheet(() => previewIcon = i),
                                  child: Container(width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: BpReferenceStyle.of(sheetContext).input,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: i == previewIcon
                                        ? const Color(0xFF097CFF)
                                        : BpReferenceStyle.of(sheetContext).line)),
                                    child: Icon(categoryPreviewIcons[i], size: 18,
                                      color: BpReferenceStyle.of(sheetContext).ink)),
                                ),
                            ])),
                        ]),
                        const SizedBox(height: 7),
                        Wrap(spacing: 9, children: [
                          for (var i = 0; i < categoryPreviewColors.length; i++)
                            InkWell(
                              onTap: () => updateSheet(() => previewColor = i),
                              child: Container(width: 23, height: 23,
                                decoration: BoxDecoration(
                                  color: categoryPreviewColors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: i == previewColor
                                    ? const Color(0xFF114BD4) : Colors.white,
                                    width: 2.5))),
                            ),
                        ]),
                      ]),
                  ),
                  const SizedBox(height: 9),
                ],
                if (widget.config.apiPath == '/api/categories') ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.text_fields_rounded, size: 18,
                      color: Theme.of(sheetContext).colorScheme.primary),
                    const SizedBox(width: 7),
                    Text('Category Name *', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900,
                      color: BpReferenceStyle.of(sheetContext).ink)),
                  ]),
                  const SizedBox(height: 5),
                  TextField(
                    key: const ValueKey('catalog-editor-name'),
                    controller: name, maxLength: 160,
                    textInputAction: TextInputAction.next,
                    decoration: BpReferenceStyle.of(sheetContext).search(
                      'Enter category name...').copyWith(
                        isDense: true, counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9))),
                  if (widget.config.hasDescription) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.description_outlined, size: 18,
                        color: Theme.of(sheetContext).colorScheme.primary),
                      const SizedBox(width: 7),
                      Text('Description', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900,
                        color: BpReferenceStyle.of(sheetContext).ink)),
                    ]),
                    const SizedBox(height: 5),
                    TextField(
                      controller: description,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: BpReferenceStyle.of(sheetContext).search(
                        'Enter category description...').copyWith(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10))),
                  ],
                ] else ...[
                  _CatalogReferenceFieldTile(
                    icon: Icons.sell_outlined,
                    tint: const Color(0xFF168EF1),
                    label: '$singular Name *',
                    child: TextField(
                      key: const ValueKey('catalog-editor-name'),
                      controller: name, maxLength: 160,
                      textInputAction: TextInputAction.next,
                      decoration: BpReferenceStyle.of(sheetContext).search(
                        'Enter ${singular.toLowerCase()} name...').copyWith(
                          isDense: true, counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 8)))),
                  if (widget.config.needsCategory ||
                      widget.config.apiPath == '/api/brands')
                    _CatalogReferenceFieldTile(
                      icon: Icons.qr_code_rounded,
                      tint: const Color(0xFF9250ED),
                      label: '$singular Code',
                      child: InputDecorator(
                        decoration: BpReferenceStyle.of(sheetContext).search(
                          'Generated by server').copyWith(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 8)),
                        child: Text(isEdit
                          ? field(item['code'], 'Generated by server')
                          : 'Generated by server',
                          style: TextStyle(fontSize: 12,
                            color: BpReferenceStyle.of(sheetContext).muted)))),
                if (widget.config.needsCategory)
                  _CatalogReferenceFieldTile(
                    icon: Icons.layers_rounded,
                    tint: const Color(0xFF0DBE64),
                    label: 'Parent Category *',
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: categoryUlid.isEmpty ? null : categoryUlid,
                      decoration: BpReferenceStyle.of(sheetContext).search(
                        'Select parent category').copyWith(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 8)),
                      items: choices.map((choice) => DropdownMenuItem(
                        value: field(choice['ulid']),
                        child: Text(field(choice['name']),
                          overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: saving ? null :
                        (next) => updateSheet(() => categoryUlid = next ?? ''),
                    )),

                  if (widget.config.hasDescription)
                    _CatalogReferenceFieldTile(
                      icon: Icons.description_outlined,
                      tint: const Color(0xFFEFAC12),
                      label: 'Description',
                      child: TextField(
                        controller: description,
                        maxLength: 255, maxLines: 2,
                        decoration: BpReferenceStyle.of(sheetContext).search(
                          'Enter description...').copyWith(
                            isDense: true, counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 9)))),
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
                const SizedBox(height: 8),
                if (widget.config.apiPath == '/api/categories') ...[
                  Text('Status *', style: TextStyle(
                    color: BpReferenceStyle.of(sheetContext).ink,
                    fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  _CatalogReferenceStatus(
                    key: const ValueKey('catalog-editor-status'),
                    active: active, enabled: !saving,
                    onChanged: (value) => updateSheet(() => active = value)),
                ] else
                  _CatalogReferenceFieldTile(
                    icon: Icons.verified_user_outlined,
                    tint: const Color(0xFF15B967),
                    label: 'Status *',
                    child: _CatalogReferenceStatus(
                      key: const ValueKey('catalog-editor-status'),
                      active: active, enabled: !saving,
                      onChanged: (value) => updateSheet(() => active = value))),

                if (formError != null) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(formError!, style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error)),
                ),
                const SizedBox(height: 12),
              ],
            ))),
          )),
        ]),
        ),
      )));
      if (didSave == true && mounted) {
        await reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved successfully.')));
        }
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
      appBar: BpReferenceSubpageAppBar(
        title: 'Categories',
        onSearch: () => searchFocus.requestFocus(),
        onNotifications: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) =>
            NotificationsScreen(app: widget.app))),
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
                  focusNode: searchFocus,
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
    final query = search.text.trim().toLowerCase();
    final config = widget.config;
    final filtered = rows.where((row) {
      if (activeOnly && row['is_active'] == false) return false;
      return query.isEmpty || '${field(row['name'])} ${field(row['code'])}'
          .toLowerCase().contains(query);
    }).toList();
    final isSub = config.needsCategory;
    final isBrand = config.apiPath == '/api/brands';
    final singular = config.title == 'Categories' ? 'Category'
      : config.title == 'Subcategories' ? 'Subcategory'
      : config.title == 'Brands' ? 'Brand' : 'Unit';
    if (config.apiPath == '/api/categories') {
      return _categoryReferenceScreen(context, filtered);
    }
    // Reference screens 16, 18 and 20 reuse real authorized catalog data.
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(
        title: config.title,
        onSearch: () => searchFocus.requestFocus(),
        onNotifications: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) =>
            NotificationsScreen(app: widget.app))),
      ),
      floatingActionButton: canCreate ? SizedBox(
        width: 86, height: 86,
        child: FloatingActionButton(
          key: const ValueKey('catalog-add'),
          backgroundColor: const Color(0xFF05B95B),
          foregroundColor: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2.5)),
          onPressed: () => openEditor(),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 31),
              Text('Add $singular', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5,
                  fontWeight: FontWeight.w900)),
            ]),
        ),
      ) : null,
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            key: const ValueKey('catalog-master-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 105),
            children: [
              Row(children: [
                Expanded(child: TextField(
                  key: const ValueKey('catalog-search'),
                  controller: search,
                  focusNode: searchFocus,
                  onChanged: (_) => setState(() {}),
                  decoration: style.search(
                    'Search ${config.title.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search_rounded))
                    .copyWith(isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9)))),
                const SizedBox(width: 7),
                Container(
                  width: 47, height: 46,
                  decoration: BoxDecoration(
                    color: style.input,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: style.line),
                    boxShadow: [BoxShadow(color: style.shadow,
                      blurRadius: 7, offset: const Offset(0, 3))]),
                  child: IconButton(
                    key: const ValueKey('catalog-status-filter'),
                    tooltip: 'Filter status',
                    onPressed: () => setState(
                      () => showFilters = !showFilters),
                    icon: const Icon(Icons.filter_alt_outlined,
                      color: Color(0xFF0757D9)))),

              ]),
              if (showFilters) ...[
                const SizedBox(height: 7),
                Wrap(spacing: 8, children: [
                  ChoiceChip(label: const Text('All'),
                    selected: !activeOnly,
                    onSelected: (_) => setState(() => activeOnly = false)),
                  ChoiceChip(label: const Text('Active'),
                    selected: activeOnly,
                    onSelected: (_) => setState(() => activeOnly = true)),
                ]),
              ],
              const SizedBox(height: 12),
              if (loading) pageLoading()
              else if (error != null)
                FailureState(message: error!, retry: reload)
              else if (filtered.isEmpty)
                EmptyState(title: rows.isEmpty
                    ? 'No ${config.title.toLowerCase()} yet'
                    : 'No matching ${config.title.toLowerCase()}',
                  subtitle: 'Try a different search or status filter.')
              else
                for (var i = 0; i < filtered.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('catalog-row-${field(filtered[i]['ulid'])}'),
                        borderRadius: BorderRadius.circular(15),
                        onTap: canEdit
                          ? () => openEditor(item: filtered[i]) : null,
                        child: Container(
                          height: isBrand ? 74 : 69,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: style.card(radius: 15),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: _catalogRowTone(
                                  field(filtered[i]['name']), i)
                                  .withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(12)),
                              child: Icon(_catalogRowIcon(
                                field(filtered[i]['name']),
                                isSub: isSub, isBrand: isBrand),
                                size: 26,
                                color: _catalogRowTone(
                                  field(filtered[i]['name']), i))),
                            const SizedBox(width: 9),
                            Container(width: 1, height: 38, color: style.line),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(field(filtered[i]['name'], '—'),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: style.ink)),
                                if (isSub)
                                  Text(field(
                                    objectOf(filtered[i]['category'])['name'],
                                    'Parent category unavailable'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5,
                                      color: style.muted)),
                                if (isBrand &&
                                    field(filtered[i]['code']).isNotEmpty)
                                  Text(field(filtered[i]['code']),
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 10,
                                      color: style.muted)),
                              ]),
                            ),
                            if (config.isUnit &&
                                field(filtered[i]['symbol']).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _catalogRowTone(
                                    field(filtered[i]['name']), i)
                                    .withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(18)),
                                child: Text(field(filtered[i]['symbol']).toUpperCase(),
                                  style: TextStyle(fontSize: 11,
                                    color: style.ink,
                                    fontWeight: FontWeight.w900))),
                            if (filtered[i]['is_active'] == false)
                              Padding(padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.pause_circle_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 17)),
                            if (canEdit && !config.isUnit) Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.chevron_right_rounded,
                                size: 21, color: style.ink)),
                          ]),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: IgnorePointer(child: AuthReferenceWaves(height: 60))),
      ]),
    );
  }
}
