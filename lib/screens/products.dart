import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.app, this.onAdd});
  final AppController app;
  final ValueChanged<Map<String, dynamic>>? onAdd;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> items = [];
  bool busy = true;
  String? error;
  int total = 0;
  int version = 0;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { debounce?.cancel(); search.dispose(); super.dispose(); }

  Future<void> load() async {
    final requestVersion = ++version;
    setState(() { busy = true; error = null; });
    try {
      final params = <String, String>{'per_page':'25', 'sales_lookup':'1'};
      if (search.text.trim().isNotEmpty) params['q'] = search.text.trim();
      final path = Uri(path:'/api/products', queryParameters:params).toString();
      final result = await widget.app.api.get(path);
      if (!mounted || requestVersion != version) return;
      setState(() {
        items = recordsOf(result);
        total = int.tryParse(field(objectOf(objectOf(result)['meta'])['total'])) ?? items.length;
      });
    } catch (e) {
      if (!mounted || requestVersion != version) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted && requestVersion == version) setState(() => busy = false);
    }
  }

  void queryChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 320), load);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeading('Products catalog'),
        TextField(controller: search, onChanged: queryChanged,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search),
            hintText: 'Search name, SKU or barcode',
            suffixIcon: search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close),
              onPressed: () { search.clear(); load(); }))),
        const SizedBox(height: 12),
        Row(children: [
          Text('$total matching products', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const Spacer(),
          if (busy) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        const SizedBox(height: 12),
        if (error != null) FailureState(message: error!, retry: load)
        else if (!busy && items.isEmpty) const EmptyState(title:'No products found',
          subtitle:'Try a different product name or barcode.', icon:Icons.inventory_2_outlined),
        ...items.map((p) {
          final prices = recordsOf(p['prices']);
          final retail = prices.where((x) => x['price_type'] == 'retail' && x['is_active'] != false);
          final cost = retail.isNotEmpty ? retail.first['amount'] : null;
          final stock = objectOf(p['sales_lookup'])['in_stock'];
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(
            child: Row(children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(
                color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.inventory_2_rounded, color: scheme.onPrimaryContainer)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(field(p['name'], 'Unnamed product'), maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('No. ${field(p['product_number'], '—')}', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                if (stock != null) Text('Stock: $stock', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(cost == null ? 'Price unavailable' : money(cost),
                  style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
              ])),
              if (widget.onAdd != null) IconButton.filledTonal(
                tooltip:'Add to sale', onPressed: () => widget.onAdd!(p), icon: const Icon(Icons.add)),
            ]),
          ));
        }),
      ]),
    );
  }
}
