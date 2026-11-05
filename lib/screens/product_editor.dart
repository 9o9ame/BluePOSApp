import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';

Map<String, dynamic> basicProductPayload({
  required String name, required String sku, required String baseUnitUlid,
  required bool taxable, required bool batch, required bool expiry,
  String categoryUlid = '', String brandUlid = '',
  String barcode = '', String retailPrice = '',
  bool creating = true,
}) {
  if (name.trim().isEmpty ||
      !RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(baseUnitUlid)) {
    throw const FormatException('Name and valid base unit are required.');
  }
  if (retailPrice.isNotEmpty &&
      !RegExp(r'^(?:0|[1-9]\d*)(?:\.\d{1,4})?$').hasMatch(retailPrice)) {
    throw const FormatException('Invalid retail price.');
  }
  return {
    'name': name.trim(),
    'sku': sku.trim().isEmpty ? null : sku.trim(),
    'base_unit_ulid': baseUnitUlid,
    if (categoryUlid.length == 26) 'category_ulid': categoryUlid,
    if (brandUlid.length == 26) 'brand_ulid': brandUlid,
    'is_taxable': taxable,
    'track_batch': batch,
    'track_expiry': expiry,
    if (creating && barcode.trim().isNotEmpty) 'barcodes': [{
      'barcode': barcode.trim(),
      'unit_ulid': baseUnitUlid,
      'conversion_factor': '1.00000000',
      'is_primary': true,
    }],
    if (creating && retailPrice.isNotEmpty) 'prices': [{
      'price_type': 'retail',
      'amount': retailPrice,
    }],
  };
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.app, this.product});
  final AppController app;
  final Map<String, dynamic>? product;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  late final name = TextEditingController(text: field(widget.product?['name']));
  late final sku = TextEditingController(text: field(widget.product?['sku']));
  final barcode = TextEditingController();
  final retail = TextEditingController();
  bool loading = true, saving = false;
  bool taxable = false, trackBatch = false, trackExpiry = false;
  String? error;
  List<Map<String, dynamic>> units = [], categories = [], brands = [];
  String unitUlid = '', categoryUlid = '', brandUlid = '';

  @override
  void initState() {
    super.initState();
    taxable = widget.product?['is_taxable'] == true;
    trackBatch = widget.product?['track_batch'] == true;
    trackExpiry = widget.product?['track_expiry'] == true;
    unitUlid = field(objectOf(widget.product?['base_unit'])['ulid']);
    categoryUlid = field(objectOf(widget.product?['category'])['ulid']);
    brandUlid = field(objectOf(widget.product?['brand'])['ulid']);
    fetchOptions();
  }

  @override
  void dispose() { name.dispose(); sku.dispose(); barcode.dispose(); retail.dispose(); super.dispose(); }

  Future<void> fetchOptions() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.app.api.get('/api/units');
      if (!mounted) return;
      setState(() {
        units = recordsOf(result).where((row) => row['is_active'] != false).toList();
      });
      if (units.isNotEmpty && unitUlid.isEmpty) {
        unitUlid = field(units.first['ulid']);
      }
      try {
        final result = await widget.app.api.get('/api/categories');
        if (mounted) setState(() =>
          categories = recordsOf(result).where((row) => row['is_active'] != false).toList());
      } catch (_) { /* Optional reference list requires separate permission. */ }
      try {
        final result = await widget.app.api.get('/api/brands');
        if (mounted) setState(() =>
          brands = recordsOf(result).where((row) => row['is_active'] != false).toList());
      } catch (_) { /* Optional reference list requires separate permission. */ }
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget choice(String label, List<Map<String, dynamic>> options,
      String selected, ValueChanged<String> onChange, {bool required = false}) {
    final chosen = options.any((row) => field(row['ulid']) == selected) ?
      selected : '';
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: chosen.isEmpty ? null : chosen,
        decoration: InputDecoration(labelText: label + (required ? ' *' : '')),
        items: [
          if (!required) const DropdownMenuItem(value: '', child: Text('None')),
          ...options.map((row) => DropdownMenuItem(
            value: field(row['ulid']),
            child: Text(field(row['name']),
              maxLines: 1, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: saving ? null : (value) => onChange(value ?? ''),
      ),
    );
  }

  Future<void> save() async {
    if (saving) return;
    final modifying = widget.product != null;
    if (name.text.trim().isEmpty || unitUlid.length != 26) {
      setState(() => error = 'Enter a product name and base unit.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      final payload = basicProductPayload(
        name: name.text, sku: sku.text, baseUnitUlid: unitUlid,
        categoryUlid: categoryUlid, brandUlid: brandUlid,
        taxable: taxable, batch: trackBatch, expiry: trackExpiry,
        barcode: barcode.text, retailPrice: retail.text.trim(),
        creating: !modifying,
      );
      if (modifying) {
        final ulid = field(widget.product?['ulid']);
        if (ulid.length != 26) throw const FormatException('Invalid product.');
        await widget.app.api.patch('/api/products/' + ulid, payload);
      } else {
        await widget.app.api.post('/api/products', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.product == null;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(creating ? 'Add Product' : 'Edit Product')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(creating ? 'New catalog item' : 'Product details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        if (loading) const LinearProgressIndicator(),
        TextField(controller: name, maxLength: 180,
          decoration: const InputDecoration(labelText: 'Product name *')),
        TextField(controller: sku, maxLength: 64,
          decoration: const InputDecoration(labelText: 'SKU / code')),
        choice('Base unit', units, unitUlid,
          (value) => setState(() => unitUlid = value), required: true),
        choice('Category', categories, categoryUlid,
          (value) => setState(() => categoryUlid = value)),
        choice('Brand', brands, brandUlid,
          (value) => setState(() => brandUlid = value)),
        if (creating) ...[
          const SizedBox(height: 10),
          TextField(controller: barcode, maxLength: 64,
            decoration: const InputDecoration(labelText: 'Primary barcode')),
          const SizedBox(height: 8),
          TextField(controller: retail,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Initial retail price',
              prefixText: widget.app.currency + ' ')),
        ],
        const SizedBox(height: 8),
        SwitchListTile.adaptive(value: taxable,
          contentPadding: EdgeInsets.zero,
          title: const Text('Taxable'),
          onChanged: saving ? null :
            (value) => setState(() => taxable = value)),
        SwitchListTile.adaptive(value: trackBatch,
          contentPadding: EdgeInsets.zero,
          title: const Text('Track batch'),
          onChanged: saving ? null :
            (value) => setState(() => trackBatch = value)),
        SwitchListTile.adaptive(value: trackExpiry,
          contentPadding: EdgeInsets.zero,
          title: const Text('Track expiry'),
          onChanged: saving ? null :
            (value) => setState(() => trackExpiry = value)),
        const SizedBox(height: 10),
        if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Text(error!, style: TextStyle(color: scheme.error))),
        FilledButton.icon(onPressed: saving || loading ? null : save,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(saving ? 'Saving…' :
            creating ? 'Create Product' : 'Save Product')),
        const SizedBox(height: 16),
      ]),
    );
  }
}
