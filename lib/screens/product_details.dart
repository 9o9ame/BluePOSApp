import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/product_thumb.dart';
import 'product_editor.dart';

/// Screen 13: read-only product details from the server-authorized ULID route.
/// Financial and stock fields are displayed only when returned by the API.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key, required this.app, required this.productUlid,
  });

  final AppController app;
  final String productUlid;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? product;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(widget.productUlid)) {
        throw const ApiFailure('INVALID_PRODUCT', 'Invalid product reference.', 422);
      }
      final response = objectOf(
        await widget.app.api.get('/api/products/${widget.productUlid}'));
      final data = objectOf(response['data']);
      if (mounted) setState(() => product = data.isNotEmpty ? data : response);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit() async {
    final current = product;
    if (current == null || !widget.app.hasPermission('products.edit')) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) =>
        ProductEditor(app: widget.app, product: current)));
    if (updated == true && mounted) await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product Detail')),
    body: loading
      ? const Center(child: CircularProgressIndicator())
      : error != null
        ? FailureState(message: error!, retry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ProductDetailsView(
              product: product ?? const {},
              api: widget.app.api,
              currency: widget.app.currency,
              canEdit: widget.app.hasPermission('products.edit'),
              canViewPurchaseRate: widget.app.hasPermission('products.edit'),
              onEdit: edit,
            ),
          ),
  );
}

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    super.key,
    required this.product,
    required this.api,
    required this.currency,
    this.canEdit = false,
    this.canViewPurchaseRate = false,
    this.onEdit,
  });

  final Map<String, dynamic> product;
  final BlueposApi api;
  final String currency;
  final bool canEdit;
  final bool canViewPurchaseRate;
  final VoidCallback? onEdit;

  String _display(dynamic value) {
    final result = field(value);
    return result.isEmpty ? 'Not available' : result;
  }

  dynamic get _retail {
    for (final p in recordsOf(product['prices'])) {
      if (p['price_type'] == 'retail' && p['is_active'] != false) {
        return p['amount'];
      }
    }
    return null;
  }

  Widget _detail(BuildContext context, String title, String value,
      IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: scheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(width: 8),
        Flexible(child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(value, textAlign: TextAlign.end,
            maxLines: 3, overflow: TextOverflow.ellipsis))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stock = objectOf(product['sales_lookup'])['in_stock'];
    final price = _retail;
    final purchase = product['purchase_rate'];
    final reorder = product['reorder_level'];
    final barcode = field(product['primary_barcode']);
    return ListView(
      key: const ValueKey('product-detail-page'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Surface(child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumb(api: api,
              imageUrl: field(product['image_url']), size: 106),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_display(product['name']),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('SKU: ${_display(product['sku'])}',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 7),
                if (product['is_active'] != null)
                  Text(product['is_active'] == true ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: product['is_active'] == true
                        ? scheme.tertiary : scheme.error,
                      fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(stock == null ? 'Stock not shown'
                    : 'Stock: ${field(stock)}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(price == null ? 'Price unavailable'
                    : money(price, currency),
                  style: TextStyle(color: scheme.primary,
                    fontWeight: FontWeight.w900, fontSize: 16)),
              ])),
          ])),
        const SizedBox(height: 13),
        Surface(child: Column(children: [
          _detail(context, 'Category',
            _display(objectOf(product['category'])['name']),
            Icons.category_outlined),
          const Divider(height: 1),
          _detail(context, 'Brand',
            _display(objectOf(product['brand'])['name']),
            Icons.sell_outlined),
          const Divider(height: 1),
          _detail(context, 'Unit',
            _display(objectOf(product['base_unit'])['name']),
            Icons.inventory_2_outlined),
          if (canViewPurchaseRate && purchase != null) ...[
            const Divider(height: 1),
            _detail(context, 'Purchase Price', money(purchase, currency),
              Icons.payments_outlined),
          ],
          const Divider(height: 1),
          _detail(context, 'Sale Price',
            price == null ? 'Price unavailable' : money(price, currency),
            Icons.sell_rounded),
          const Divider(height: 1),
          _detail(context, 'Barcode',
            barcode.isEmpty ? 'Not available' : barcode,
            Icons.qr_code_rounded),
          const Divider(height: 1),
          _detail(context, 'Stock in Hand',
            stock == null ? 'Stock not shown' : field(stock),
            Icons.warehouse_outlined),
          if (product['description'] != null &&
              field(product['description']).isNotEmpty) ...[
            const Divider(height: 1),
            _detail(context, 'Description',
              field(product['description']), Icons.description_outlined),
          ],
        ])),
        const SizedBox(height: 13),
        Surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price & Stock', style: Theme.of(context)
              .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Stock',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                  Text(stock == null ? 'Not available' : field(stock),
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
                ])),
              if (reorder != null) ...[
                const SizedBox(width: 12),
                Container(width: 1, height: 43,
                  color: scheme.outlineVariant),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reorder Level',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                    Text(field(reorder), style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
                  ])),
              ],
            ]),
          ],
        )),
        if (canEdit && onEdit != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('product-detail-edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Product'),
          ),
        ],
        const SizedBox(height: 22),
      ],
    );
  }
}
