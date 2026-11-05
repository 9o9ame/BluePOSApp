import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class ProductLedgerScreen extends StatefulWidget {
  const ProductLedgerScreen({super.key, required this.app});
  final AppController app;
  @override
  State<ProductLedgerScreen> createState() => _ProductLedgerScreenState();
}

class _ProductLedgerScreenState extends State<ProductLedgerScreen> {
  Map<String, dynamic>? selected;
  DateTime from = DateTime.now().subtract(const Duration(days: 30));
  DateTime to = DateTime.now();
  Map<String, dynamic> result = {};
  int page = 1;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> movements = [];

  String _date(DateTime d) =>
    d.year.toString().padLeft(4, '0') + '-' +
    d.month.toString().padLeft(2, '0') + '-' +
    d.day.toString().padLeft(2, '0');

  Future<void> chooseProduct() async {
    final fieldController = TextEditingController();
    var found = <Map<String, dynamic>>[];
    var searching = false;
    String? failure;
    Future<void> lookup(void Function(void Function()) setSheet) async {
      setSheet(() { searching = true; failure = null; });
      try {
        final url = Uri(path: '/api/products', queryParameters: {
          'per_page': '30',
          if (fieldController.text.trim().isNotEmpty)
            'q': fieldController.text.trim(),
        }).toString();
        final data = await widget.app.api.get(url);
        setSheet(() => found = recordsOf(data));
      } catch (ex) {
        setSheet(() => failure = ex.toString());
      } finally {
        setSheet(() => searching = false);
      }
    }

    try {
      final chosen = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, showDragHandle: true,
        isScrollControlled: true, useSafeArea: true,
        builder: (sheet) => StatefulBuilder(builder: (sheet, setSheet) =>
          SizedBox(height: MediaQuery.sizeOf(sheet).height * .7,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
              child: Column(children: [
                const Text('Select product', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 12),
                TextField(controller: fieldController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => lookup(setSheet),
                  decoration: InputDecoration(
                    hintText: 'Search product name or SKU',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => lookup(setSheet),
                      icon: const Icon(Icons.arrow_forward_rounded)))),
                if (searching) const LinearProgressIndicator(),
                if (failure != null) Padding(
                  padding: const EdgeInsets.all(12), child: Text(failure!)),
                const SizedBox(height: 12),
                Expanded(child: ListView.builder(
                  itemCount: found.length,
                  itemBuilder: (_, index) {
                    final product = found[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(field(product['name'])),
                      subtitle: Text(field(product['product_number'])),
                      onTap: () => Navigator.pop(sheet, product),
                    );
                  })),
              ]),
            ),
          ),
        )),
      );
      if (chosen != null && mounted && field(chosen['ulid']).length == 26) {
        setState(() => selected = chosen);
        await load();
      }
    } finally {
      fieldController.dispose();
    }
  }

  Future<void> chooseDates() async {
    final dates = await showDateRangePicker(
      context: context, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: from, end: to),
    );
    if (dates == null || !mounted) return;
    setState(() { from = dates.start; to = dates.end; });
    if (selected != null) await load();
  }

  Future<void> load({bool more = false}) async {
    if (selected == null || busy) return;
    setState(() { busy = true; error = null; });
    try {
      final current = more ? page + 1 : 1;
      final url = Uri(path: '/api/reports/products/ledger',
        queryParameters: {
          'product_ulid': field(selected!['ulid']),
          'from_date': _date(from),
          'to_date': _date(to),
          'per_page': '50',
          'page': '$current',
        }).toString();
      final raw = objectOf(await widget.app.api.get(url));
      if (!mounted) return;
      setState(() {
        result = raw;
        page = current;
        movements = more ? [...movements, ...recordsOf(raw)] :
          recordsOf(raw);
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = objectOf(result['meta']);
    final totals = objectOf(meta['totals']);
    final count = int.tryParse(field(meta['total'])) ?? movements.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Ledger'),
        actions: [IconButton(onPressed: load,
          icon: const Icon(Icons.refresh_rounded))]),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Product movement ledger'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: chooseProduct,
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(selected == null ? 'Select product' :
              field(selected!['name'])),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: chooseDates,
            icon: const Icon(Icons.date_range_rounded),
            label: Text(_date(from) + '  —  ' + _date(to)),
          ),
          const SizedBox(height: 14),
          if (selected == null)
            const EmptyState(title: 'Select a product to view movements')
          else if (busy && movements.isEmpty) pageLoading()
          else if (error != null) FailureState(message: error!,
            retry: load)
          else ...[
            Row(children: [
              Expanded(child: BpStatCard(icon: Icons.inventory_2_outlined,
                caption: 'Opening qty', hint: 'Before period',
                value: field(result['opening_quantity'], '—'))),
              const SizedBox(width: 8),
              Expanded(child: BpStatCard(icon: Icons.fact_check_outlined,
                caption: 'Closing qty', hint: 'After period',
                value: field(meta['closing_quantity'], '—'))),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: BpStatCard(icon: Icons.arrow_downward_rounded,
                caption: 'Quantity in', hint: 'Server period total',
                value: field(totals['quantity_in'], '—'))),
              const SizedBox(width: 8),
              Expanded(child: BpStatCard(icon: Icons.arrow_upward_rounded,
                caption: 'Quantity out', hint: 'Server period total',
                value: field(totals['quantity_out'], '—'))),
            ]),
            const SizedBox(height: 16),
            SectionHeading('Movements (' + count.toString() + ')'),
            if (movements.isEmpty) const EmptyState(title: 'No stock movement found')
            else ...movements.map((movement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field(movement['movement_type']),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(field(movement['occurred_at']),
                      style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 9),
                    Row(children: [
                      Expanded(child: Text('In: ' +
                        field(movement['quantity_in'], '0'))),
                      Expanded(child: Text('Out: ' +
                        field(movement['quantity_out'], '0'),
                        textAlign: TextAlign.center)),
                      Expanded(child: Text('Balance: ' +
                        field(movement['running_quantity'], '—'),
                        textAlign: TextAlign.end)),
                    ]),
                  ]))),
            )),
            if (movements.length < count) Padding(
              padding: const EdgeInsets.all(10),
              child: OutlinedButton(
                onPressed: busy ? null : () => load(more: true),
                child: Text(busy ? 'Loading…' : 'Load more')),
            ),
          ],
          const SizedBox(height: 18),
        ]),
      ),
    );
  }
}
