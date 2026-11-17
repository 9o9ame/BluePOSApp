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

  String _stockLabel(dynamic raw) {
    final value = field(raw);
    if (value.isEmpty) return 'Stock not shown';
    final compact = value.contains('.')
      ? value.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'[.]$'), '')
      : value;
    return 'In Stock: $compact';
  }

  String _displayPrice(String raw) {
    final display = money(raw, currency);
    return currency == 'PKR'
      ? display.replaceFirst('PKR ', 'Rs ')
      : display;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stock = objectOf(product['sales_lookup'])['in_stock'];
    final premium = imageFirst == true;
    return InkWell(
      key: ValueKey('pos-product-${field(product['ulid'])}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Colors.white, Color(0xFFF6F8FF)]),
          border: Border.all(color: Colors.white, width: 1.6),
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [BoxShadow(
            color: Color(0x235C76AF),
            blurRadius: 10, offset: Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: premium ? 91 : 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFE9FFF3), Color(0xFFE6F5FF)]),
                borderRadius: BorderRadius.circular(13)),
              child: ProductThumb(
                api: api,
                imageUrl: field(product['image_url']),
                size: premium ? 79 : 67),
            ),
            const SizedBox(height: 4),
            Text(field(product['name'], 'Product'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF0A1B48),
                fontSize: premium ? 13.2 : 12.8,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(retailPrice == null
                ? 'Price unavailable'
                : _displayPrice(retailPrice!),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: premium ? 17 : 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF081B4C))),
            const Spacer(),
            Row(children: [
              Expanded(child: Text(_stockLabel(stock),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  color: stock == null
                    ? scheme.onSurfaceVariant
                    : const Color(0xFF009344)))),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFBE9),
                  borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.add_rounded,
                  size: 22, color: Color(0xFF02A64F))),
            ]),
          ]),
      ),
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
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid)) {
      showApiError(context, 'Invalid product reference.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        app: widget.app, productUlid: ulid)));
  }

  Widget _categoryChip(String title, IconData icon, bool selected,
      Color tint, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected
            ? const LinearGradient(colors: [
                Color(0xFF08CF77), Color(0xFF008F50)])
            : LinearGradient(colors: [
                tint.withValues(alpha: .13),
                Colors.white]),
          border: Border.all(color: Colors.white, width: 1.3),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(
            color: Color(0x1A6081B5),
            blurRadius: 6, offset: Offset(0, 3))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!selected) ...[
            Icon(icon, color: tint, size: 17),
            const SizedBox(width: 5),
          ],
          Text(title, style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF172549),
            fontSize: 11.5, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    final standalone = widget.catalogHome == true || widget.onAdd == null;
    return Stack(children: [
      RefreshIndicator(onRefresh: load, child: ListView(
        padding: EdgeInsets.fromLTRB(
          widget.inlineCatalog == true ? 7 : 16,
          5, widget.inlineCatalog == true ? 7 : 16, 16), children: [
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
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            fillColor: const Color(0xFFFFFFFF),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE6EBFA)),
              borderRadius: BorderRadius.circular(17)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF00A672)),
              borderRadius: BorderRadius.circular(17)),
            prefixIcon: const Icon(Icons.search_rounded),
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
        const SizedBox(height: 7),
        SizedBox(height: 36, child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(padding: const EdgeInsets.only(right: 7),
              child: _categoryChip('All', Icons.check_rounded,
                categoryUlid == null, const Color(0xFF02B56D), () {
                  setState(() => categoryUlid = null);
                  load();
                })),
            ...categories.map((c) {
              final name = field(c['name']);
              final lower = name.toLowerCase();
              final icon = lower.contains('baby')
                ? Icons.child_friendly_outlined
                : lower.contains('bak')
                  ? Icons.bakery_dining_outlined
                  : lower.contains('bath')
                    ? Icons.bathtub_outlined
                    : Icons.category_outlined;
              final tint = lower.contains('baby')
                ? const Color(0xFFF4A214)
                : lower.contains('bak')
                  ? const Color(0xFF087EDF)
                  : const Color(0xFFE64C92);
              return Padding(padding: const EdgeInsets.only(right: 7),
                child: _categoryChip(name, icon,
                  categoryUlid == c['ulid'], tint, () {
                    setState(() => categoryUlid = field(c['ulid']));
                    load();
                  }));
            }),
          ],
        )),
      ],
      if (widget.inlineCatalog != true) ...[
        const SizedBox(height: 10),
        Row(children: [Text('$total matching products',
          style: TextStyle(fontSize: 12,
            color: scheme.onSurfaceVariant)), const Spacer(),
          if (busy || loadingMore) const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ],
      const SizedBox(height: 11),
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
            mainAxisExtent: (widget.inlineCatalog == true) ? 207 : 194),
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
