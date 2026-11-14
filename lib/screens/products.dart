import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/product_thumb.dart';
import 'scanner.dart';
import 'product_editor.dart';
import 'product_details.dart';

/// Product card for the authorized POS selection catalog.
/// Prices and stock labels are read from the product lookup response only.
class PosCatalogProductCard extends StatelessWidget {
  const PosCatalogProductCard({
    super.key,
    required this.product,
    required this.api,
    required this.currency,
    required this.onTap,
    this.imageFirst = false,
  });

  final Map<String, dynamic> product;
  final BlueposApi api;
  final String currency;
  final VoidCallback? onTap;
  // Hot reload can retain cards instantiated before this optional field existed.
  final bool? imageFirst;

  String? get retailPrice {
    for (final price in recordsOf(product['prices'])) {
      if (price['price_type'] == 'retail' && price['is_active'] != false) {
        return field(price['amount']);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stock = objectOf(product['sales_lookup'])['in_stock'];
    return InkWell(
      key: ValueKey('pos-product-${field(product['ulid'])}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Surface(padding: const EdgeInsets.all(11), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: ProductThumb(
            api: api, imageUrl: field(product['image_url']),
            size: (imageFirst == true) ? 100 : 66)),
          SizedBox(height: (imageFirst == true) ? 11 : 9),
          Text(field(product['name'], 'Product'), maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: (imageFirst == true) ? 13 : 12,
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(retailPrice == null ? 'Price unavailable'
              : money(retailPrice, currency),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: (imageFirst == true) ? 15 : 12,
              fontWeight: FontWeight.w900, color: scheme.primary)),
          const Spacer(),
          Row(children: [
            Expanded(child: Text(stock == null ? 'Stock not shown'
                : 'Stock: ${field(stock)}', maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10))),
            Icon(Icons.add_circle_rounded, size: 21, color: scheme.primary),
          ]),
        ])),
    );
  }
}

/// Newer premium reference 12: the standalone product catalog uses a
/// horizontal image-first row. All visible values originate in the API response.
class CatalogProductRow extends StatelessWidget {
  const CatalogProductRow({
    super.key,
    required this.product,
    required this.api,
    required this.currency,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final BlueposApi api;
  final String currency;
  final VoidCallback onTap;

  dynamic get retailPrice {
    for (final p in recordsOf(product['prices'])) {
      if (p['price_type'] == 'retail' && p['is_active'] != false) {
        return p['amount'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stock = objectOf(product['sales_lookup'])['in_stock'];
    final price = retailPrice;
    return InkWell(
      key: ValueKey('catalog-product-${field(product['ulid'])}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Surface(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        child: Row(children: [
          ProductThumb(api: api, imageUrl: field(product['image_url']), size: 74),
          const SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field(product['name'], 'Product'),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 5),
              Text('SKU: ${field(product['sku'], '—')}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8)),
                child: Text(stock == null ? 'Stock not shown'
                    : 'Stock: ${field(stock)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: scheme.onTertiaryContainer)),
              ),
            ],
          )),
          const SizedBox(width: 8),
          Container(width: 1, height: 63, color: scheme.outlineVariant),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(
            price == null ? 'Price unavailable' : money(price, currency),
            textAlign: TextAlign.end, maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          )),
        ]),
      ),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.app, this.onAdd,
    this.inlineCatalog = false, this.catalogHome = false});
  final AppController app;
  final ValueChanged<Map<String, dynamic>>? onAdd;
  /// Reuse the authorized search/category grid directly inside the POS page.
  // Nullable so pre-existing IndexedStack widgets survive a Flutter hot reload
  // that adds this field: old widget instances may have a null backing slot.
  final bool? inlineCatalog;
  /// Explicit shell Products tab mode; distinct from POS product selection.
  final bool? catalogHome;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> items = [], categories = [];
  bool busy = true, loadingMore = false, scanBusy = false;
  String? error;
  String? categoryUlid;
  bool showCatalogFilters = false;
  int total = 0, version = 0, page = 1;

  @override
  void initState() { super.initState(); loadCategories(); load(); }
  @override
  void dispose() { debounce?.cancel(); search.dispose(); super.dispose(); }

  Future<void> loadCategories() async {
    try {
      final response = await widget.app.api.get('/api/categories');
      if (mounted) setState(() => categories = recordsOf(response)
        .where((c) => c['is_active'] != false).toList());
    } catch (_) { /* Categorization is optional when user lacks its permission. */ }
  }

  Future<void> load({bool more = false}) async {
    if (more && (loadingMore || busy || items.length >= total)) return;
    final requestVersion = more ? version : ++version;
    setState(() { if (more) { loadingMore = true; } else { busy = true; error = null; } });
    try {
      final nextPage = more ? page + 1 : 1;
      final params = <String, String>{
        'per_page': '25', 'page': '$nextPage', 'sales_lookup': '1', 'active_only': '1',
      };
      if (search.text.trim().isNotEmpty) params['q'] = search.text.trim();
      if (categoryUlid != null) params['category_ulid'] = categoryUlid!;
      final response = await widget.app.api.get(Uri(path: '/api/products', queryParameters: params).toString());
      if (!mounted || requestVersion != version) return;
      final next = recordsOf(response);
      setState(() {
        items = more ? [...items, ...next] : next;
        total = int.tryParse(field(objectOf(objectOf(response)['meta'])['total'])) ?? items.length;
        page = nextPage;
      });
    } catch (e) {
      if (mounted && requestVersion == version) setState(() => error = e.toString());
    } finally {
      if (mounted && requestVersion == version) setState(() { busy = false; loadingMore = false; });
    }
  }

  void queryChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), load);
    setState(() {});
  }

  Future<void> scan() async {
    if (scanBusy) return;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (!mounted || barcode == null || barcode.isEmpty) return;
    setState(() => scanBusy = true);
    try {
      final response = await widget.app.api.get(Uri(path: '/api/products/lookup-existing',
        queryParameters: {'barcode': barcode.trim()}).toString());
      final source = objectOf(response);
      final product = source.containsKey('ulid') ? source : objectOf(source['data']);
      if (!mounted) return;
      if (field(product['ulid']).length != 26) {
        await showApiError(context, 'No matching authorized product.'); return;
      }
      if (widget.onAdd != null && widget.catalogHome != true) {
        widget.onAdd!(product);
      } else {
        showDetails(product);
      }
    } catch (e) { if (mounted) await showApiError(context, e); }
    finally { if (mounted) setState(() => scanBusy = false); }
  }

  Future<void> openEditor({Map<String, dynamic>? product}) async {
    if (widget.onAdd != null && widget.catalogHome != true) return;
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => ProductEditor(
        app: widget.app, product: product)));
    if (saved == true && mounted) await load();
  }

  void showDetails(Map<String, dynamic> product) {
    if (widget.onAdd != null && widget.catalogHome != true) return;
    final ulid = field(product['ulid']);
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}
      showApiError(context, 'Invalid product reference.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        app: widget.app, productUlid: ulid)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    final standalone = widget.catalogHome == true || widget.onAdd == null;
    return Stack(children: [
      RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
      if (!(widget.inlineCatalog == true))
        SectionHeading(standalone ? 'Products' : 'Add a product',
          trailing: IconButton(
            tooltip: 'Scan barcode', onPressed: scanBusy ? null : scan,
            icon: Icon(Icons.qr_code_scanner_rounded, color: scheme.primary))),
      if (standalone)
        Row(children: [
          Expanded(child: TextField(
            controller: search, onChanged: queryChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search products...'))),
          const SizedBox(width: 9),
          IconButton.filledTonal(
            key: const ValueKey('catalog-filter'),
            tooltip: 'Filter categories',
            onPressed: () => setState(() =>
              showCatalogFilters = !showCatalogFilters),
            icon: const Icon(Icons.filter_alt_outlined)),
        ])
      else
        TextField(controller: search, onChanged: queryChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: (widget.inlineCatalog == true)
              ? 'Scan barcode or search product...' : 'Search product, SKU or barcode',
            suffixIcon: (widget.inlineCatalog == true)
              ? IconButton(
                  key: const ValueKey('inline-pos-scan'),
                  tooltip: 'Scan barcode', onPressed: scanBusy ? null : scan,
                  icon: const Icon(Icons.qr_code_scanner_rounded))
              : (search.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () { search.clear(); load(); })))),
      if (categories.isNotEmpty && (!standalone || showCatalogFilters)) ...[
        const SizedBox(height: 12),
        SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: const Text('All'), selected: categoryUlid == null,
            onSelected: (_) { setState(() => categoryUlid = null); load(); })),
          ...categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(field(c['name'])),
              selected: categoryUlid == c['ulid'],
              onSelected: (_) { setState(() => categoryUlid = field(c['ulid'])); load(); }))),
        ])),
      ],
      const SizedBox(height: 12),
      Row(children: [Text('$total matching products', style: TextStyle(fontSize: 12,
        color: scheme.onSurfaceVariant)), const Spacer(),
        if (busy || loadingMore) const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      const SizedBox(height: 12),
      if (error != null) FailureState(message: error!, retry: load)
      else if (!busy && items.isEmpty) const EmptyState(title: 'No products found',
        subtitle: 'Try a product name, barcode or another category.')
      else if (widget.onAdd != null && !standalone) LayoutBuilder(builder: (context, constraints) {
        // The approved POS reference uses two image-first product columns.
        final columns = (widget.inlineCatalog == true) ? 2 :
          (constraints.maxWidth < 330 ? 2 : 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9,
            mainAxisExtent: (widget.inlineCatalog == true) ? 244 : 194),
          itemBuilder: (context, index) {
            final p = items[index];
            return PosCatalogProductCard(
              product: p, api: app.api, currency: app.currency,
              imageFirst: (widget.inlineCatalog == true),
              onTap: () => widget.onAdd!(p));
          });
      })
      else ...items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: CatalogProductRow(
          product: p, api: app.api, currency: app.currency,
          onTap: () => showDetails(p)),
      )),
      if (items.length < total && !busy) Padding(padding: const EdgeInsets.all(12),
        child: OutlinedButton(onPressed: loadingMore ? null : () => load(more: true),
          child: Text(loadingMore ? 'Loading…' : 'Load more products'))),
      SizedBox(height: standalone && app.hasPermission('products.create') ? 96 : 16),
    ])),
      if (standalone && app.hasPermission('products.create'))
        Positioned(right: 18, bottom: 18,
          child: FloatingActionButton.extended(
            key: const ValueKey('catalog-add-product'),
            onPressed: () => openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          )),
    ]);
  }
}
).hasMatch(ulid)) {
      showApiError(context, 'Invalid product reference.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        app: widget.app, productUlid: ulid)));
  }

  dynamic _price(Map<String, dynamic> item) {
    for (final p in recordsOf(item['prices'])) {
      if (p['price_type'] == 'retail' && p['is_active'] != false) return p['amount'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    final standalone = widget.catalogHome == true || widget.onAdd == null;
    return Stack(children: [
      RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
      if (!(widget.inlineCatalog == true))
        SectionHeading(standalone ? 'Products' : 'Add a product',
          trailing: IconButton(
            tooltip: 'Scan barcode', onPressed: scanBusy ? null : scan,
            icon: Icon(Icons.qr_code_scanner_rounded, color: scheme.primary))),
      if (standalone)
        Row(children: [
          Expanded(child: TextField(
            controller: search, onChanged: queryChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search products...'))),
          const SizedBox(width: 9),
          IconButton.filledTonal(
            key: const ValueKey('catalog-filter'),
            tooltip: 'Filter categories',
            onPressed: () => setState(() =>
              showCatalogFilters = !showCatalogFilters),
            icon: const Icon(Icons.filter_alt_outlined)),
        ])
      else
        TextField(controller: search, onChanged: queryChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: (widget.inlineCatalog == true)
              ? 'Scan barcode or search product...' : 'Search product, SKU or barcode',
            suffixIcon: (widget.inlineCatalog == true)
              ? IconButton(
                  key: const ValueKey('inline-pos-scan'),
                  tooltip: 'Scan barcode', onPressed: scanBusy ? null : scan,
                  icon: const Icon(Icons.qr_code_scanner_rounded))
              : (search.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () { search.clear(); load(); })))),
      if (categories.isNotEmpty && (!standalone || showCatalogFilters)) ...[
        const SizedBox(height: 12),
        SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: const Text('All'), selected: categoryUlid == null,
            onSelected: (_) { setState(() => categoryUlid = null); load(); })),
          ...categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(field(c['name'])),
              selected: categoryUlid == c['ulid'],
              onSelected: (_) { setState(() => categoryUlid = field(c['ulid'])); load(); }))),
        ])),
      ],
      const SizedBox(height: 12),
      Row(children: [Text('$total matching products', style: TextStyle(fontSize: 12,
        color: scheme.onSurfaceVariant)), const Spacer(),
        if (busy || loadingMore) const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      const SizedBox(height: 12),
      if (error != null) FailureState(message: error!, retry: load)
      else if (!busy && items.isEmpty) const EmptyState(title: 'No products found',
        subtitle: 'Try a product name, barcode or another category.')
      else if (widget.onAdd != null && !standalone) LayoutBuilder(builder: (context, constraints) {
        // The approved POS reference uses two image-first product columns.
        final columns = (widget.inlineCatalog == true) ? 2 :
          (constraints.maxWidth < 330 ? 2 : 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9,
            mainAxisExtent: (widget.inlineCatalog == true) ? 244 : 194),
          itemBuilder: (context, index) {
            final p = items[index];
            return PosCatalogProductCard(
              product: p, api: app.api, currency: app.currency,
              imageFirst: (widget.inlineCatalog == true),
              onTap: () => widget.onAdd!(p));
          });
      })
      else ...items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: CatalogProductRow(
          product: p, api: app.api, currency: app.currency,
          onTap: () => showDetails(p)),
      )),
      if (items.length < total && !busy) Padding(padding: const EdgeInsets.all(12),
        child: OutlinedButton(onPressed: loadingMore ? null : () => load(more: true),
          child: Text(loadingMore ? 'Loading…' : 'Load more products'))),
      SizedBox(height: standalone && app.hasPermission('products.create') ? 96 : 16),
    ])),
      if (standalone && app.hasPermission('products.create'))
        Positioned(right: 18, bottom: 18,
          child: FloatingActionButton.extended(
            key: const ValueKey('catalog-add-product'),
            onPressed: () => openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          )),
    ]);
  }
}
