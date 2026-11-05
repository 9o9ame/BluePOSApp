import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class StockStatusReport extends StatefulWidget {
  const StockStatusReport({super.key, required this.app});
  final AppController app;
  @override
  State<StockStatusReport> createState() => _StockStatusReportState();
}

class _StockStatusReportState extends State<StockStatusReport> {
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = const [];
  Map<String, dynamic> meta = const {};
  bool loading = true, more = false, lowStock = false, withBalance = false;
  String? error;
  int page = 1, sequence = 0;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load({bool nextPage = false}) async {
    if (nextPage && (more || loading ||
        rows.length >= (int.tryParse(field(meta['total'])) ?? rows.length))) {
      return;
    }
    final serial = ++sequence;
    setState(() {
      if (nextPage) more = true;
      else { loading = true; error = null; page = 1; }
    });
    try {
      final currentPage = nextPage ? page + 1 : 1;
      final uri = Uri(path: '/api/reports/products/stock-status',
        queryParameters: {
          'page': '$currentPage',
          'per_page': '30',
          if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
          if (lowStock) 'low_stock': '1',
          if (withBalance) 'with_balance': '1',
        });
      final response = objectOf(await widget.app.api.get(uri.toString()));
      if (!mounted || serial != sequence) return;
      setState(() {
        rows = nextPage ? [...rows, ...recordsOf(response)] : recordsOf(response);
        meta = objectOf(response['meta']);
        page = currentPage;
      });
    } catch (ex) {
      if (mounted && serial == sequence) setState(() => error = ex.toString());
    } finally {
      if (mounted && serial == sequence) setState(() {
        loading = false; more = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    final total = int.tryParse(field(meta['total'])) ?? rows.length;
    final totals = objectOf(meta['totals']);
    final warehouse = objectOf(meta['warehouse']);
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Status'),
        actions: [IconButton(onPressed: load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Warehouse stock report'),
          Text(field(warehouse['name'], app.warehouseName),
            style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(controller: search, textInputAction: TextInputAction.search,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search product, SKU or barcode',
              suffixIcon: IconButton(onPressed: () {
                search.clear(); load();
              }, icon: const Icon(Icons.search_rounded)))),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            FilterChip(label: const Text('With balance'),
              selected: withBalance, onSelected: (value) {
                setState(() => withBalance = value); load();
              }),
            FilterChip(label: const Text('Low stock'),
              selected: lowStock, onSelected: (value) {
                setState(() => lowStock = value); load();
              }),
          ]),
          const SizedBox(height: 13),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            Row(children: [
              Expanded(child: BpStatCard(
                icon: Icons.inventory_2_outlined,
                caption: 'Products', value: '$total',
                hint: 'Server filtered count')),
              const SizedBox(width: 9),
              Expanded(child: BpStatCard(
                icon: Icons.scale_outlined,
                caption: 'Stock quantity',
                value: field(totals['quantity'], '—'),
                hint: 'Server total • selected warehouse')),
            ]),
            if (totals['stock_value'] != null) ...[
              const SizedBox(height: 9),
              BpStatCard(icon: Icons.account_balance_wallet_outlined,
                caption: 'Stock value',
                value: money(totals['stock_value'], app.currency),
                hint: 'Server-authorized valuation'),
            ],
            const SizedBox(height: 17),
            const SectionHeading('Products'),
            if (rows.isEmpty) const EmptyState(title: 'No stock records')
            else ...rows.map((item) {
              final product = objectOf(item['product']);
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Surface(padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(width: 43, height: 43,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.inventory_2_outlined,
                        color: scheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field(product['name'], 'Product'),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 12)),
                        Text(field(product['product_number']),
                          style: TextStyle(fontSize: 10,
                            color: scheme.onSurfaceVariant)),
                      ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('In stock', style: TextStyle(fontSize: 10)),
                      Text(field(item['quantity'], '—'),
                        style: const TextStyle(fontWeight: FontWeight.w900,
                          fontSize: 12)),
                    ]),
                  ]),
                ),
              );
            }),
            if (rows.length < total) Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(onPressed: more ? null :
                () => load(nextPage: true),
                child: Text(more ? 'Loading…' : 'Load more')),
            ),
          ],
          const SizedBox(height: 18),
        ],
      )),
    );
  }
}
