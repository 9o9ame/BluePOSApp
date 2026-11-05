import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'products.dart';
import 'sale.dart' show CartLine;
import 'scanner.dart';

/// Quotations reuse the POS sale-line payload and the server's preparation
/// rules. No inventory movements, taxes or total amounts are calculated as
/// authoritative values by the phone.
class QuotationDirectoryScreen extends StatefulWidget {
  const QuotationDirectoryScreen({super.key, required this.app});
  final AppController app;
  @override
  State<QuotationDirectoryScreen> createState() =>
    _QuotationDirectoryScreenState();
}

class _QuotationDirectoryScreenState extends State<QuotationDirectoryScreen> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> rows = const [];
  bool busy = true, moreBusy = false;
  String? error;
  int page = 1, total = 0, serial = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (more && (busy || moreBusy || rows.length >= total)) return;
    final request = more ? serial : ++serial;
    setState(() {
      if (more) moreBusy = true;
      else { busy = true; error = null; }
    });
    try {
      final targetPage = more ? page + 1 : 1;
      final params = <String, String>{
        'per_page': '25', 'page': '$targetPage',
        if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
      };
      final result = objectOf(await widget.app.api.get(Uri(
        path: '/api/sales/quotations', queryParameters: params).toString()));
      if (!mounted || request != serial) return;
      final next = recordsOf(result);
      setState(() {
        rows = more ? [...rows, ...next] : next;
        page = targetPage;
        total = int.tryParse(field(objectOf(result['meta'])['total']))
          ?? rows.length;
      });
    } catch (ex) {
      if (mounted && request == serial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == serial) {
        setState(() { busy = false; moreBusy = false; });
      }
    }
  }

  Future<void> create() async {
    final result = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) =>
        QuotationComposeScreen(app: widget.app)));
    if (mounted && result == true) await load();
  }

  Future<void> open(Map<String, dynamic> row) async {
    final ulid = field(row['ulid']);
    if (ulid.length != 26) return;
    try {
      final response = objectOf(await widget.app.api.get(
        '/api/sales/quotations/$ulid'));
      final item = response.containsKey('ulid')
        ? response : objectOf(response['data']);
      if (!mounted) return;
      await showModalBottomSheet<void>(context: context,
        isScrollControlled: true, showDragHandle: true,
        useSafeArea: true, builder: (ctx) =>
          FractionallySizedBox(heightFactor: .82,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              SectionHeading(field(item['document_number'], 'Quotation')),
              Text(field(item['quotation_date'])),
              const SizedBox(height: 10),
              Text('Customer: ${field(objectOf(item['customer'])['name'], 'Walk-in')}'),
              Text('Price mode: ${field(item['price_type'])}'),
              if (field(item['notes']).isNotEmpty)
                Text('Notes: ${field(item['notes'])}'),
              const SectionHeading('Quoted items'),
              for (final line in recordsOf(item['items'])) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Surface(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(objectOf(line['product'])['name']),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('Quantity ${field(line['quantity'])}'
                      ' ${field(objectOf(line['unit'])['symbol'])}'),
                    Text('Line total ${money(line['line_total'], widget.app.currency)}'),
                  ]))),
              const SizedBox(height: 7),
              Text('Total: ${money(item['grand_total'], widget.app.currency)}',
                style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w900)),
            ])));
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Quotations'),
        actions: [IconButton(onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      floatingActionButton: widget.app.hasPermission('sales.create')
        ? FloatingActionButton.extended(
            onPressed: create, icon: const Icon(Icons.add_rounded),
            label: const Text('New Quotation'))
        : null,
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Quotations & estimates'),
          TextField(controller: search,
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 300), load);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Quotation number or customer')),
          const SizedBox(height: 12),
          if (busy) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else if (rows.isEmpty) const EmptyState(
            title: 'No quotations found',
            subtitle: 'Create a new quotation or adjust search.')
          else ...rows.map((quote) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(onTap: () => open(quote),
              child: Surface(padding: const EdgeInsets.all(13),
                child: Row(children: [
                  Icon(Icons.request_quote_outlined,
                    color: colors.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field(quote['document_number'], 'Quotation'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(field(objectOf(quote['customer'])['name'], 'Walk-in'),
                        style: TextStyle(fontSize: 11,
                          color: colors.onSurfaceVariant)),
                      Text(field(quote['quotation_date']),
                        style: TextStyle(fontSize: 11,
                          color: colors.onSurfaceVariant)),
                    ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(money(quote['grand_total'], widget.app.currency),
                      style: const TextStyle(fontWeight: FontWeight.w800,
                        fontSize: 12)),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ])),
            ),
          )),
          if (rows.length < total && !busy)
            OutlinedButton(onPressed: moreBusy ? null : () => load(more: true),
              child: Text(moreBusy ? 'Loading…' : 'Load more')),
          const SizedBox(height: 85),
        ],
      )),
    );
  }
}

class QuotationComposeScreen extends StatefulWidget {
  const QuotationComposeScreen({super.key, required this.app});
  final AppController app;
  @override
  State<QuotationComposeScreen> createState() =>
    _QuotationComposeScreenState();
}

class _QuotationComposeScreenState extends State<QuotationComposeScreen> {
  final lines = <CartLine>[];
  final notes = TextEditingController();
  final pendingStore = const QuotationAttemptStore();
  String priceMode = 'default';
  Map<String, dynamic>? selectedCustomer;
  bool saving = false, attempted = false;
  String? error, attemptKey;
  Map<String, dynamic>? attemptPayload;

  @override
  void initState() {
    super.initState();
    restore();
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> restore() async {
    final data = await pendingStore.read(
      userUlid: widget.app.currentUserUlid,
      tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
      branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
    );
    if (data == null || !mounted) return;
    setState(() {
      attempted = true;
      attemptKey = field(data['key']);
      attemptPayload = objectOf(data['payload']);
      error = 'Unconfirmed quotation save. Retry the same request safely.';
    });
  }

  void addProduct(Map<String, dynamic> product, {String? barcode}) {
    if (attempted) return;
    final ulid = field(product['ulid']);
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid)) return;
    setState(() {
      final existing = lines.where((line) =>
        line.ulid == ulid && line.barcode == barcode).toList();
      if (existing.isNotEmpty) {
        final original = Decimal.tryParse(existing.first.qty) ?? Decimal.one;
        existing.first.qty = (original + Decimal.one).toString();
      } else {
        lines.add(CartLine(product, barcode: barcode));
      }
    });
  }

  Future<void> selectProduct() async {
    if (attempted) return;
    await showModalBottomSheet<void>(context: context,
      isScrollControlled: true, useSafeArea: true, showDragHandle: true,
      builder: (ctx) => FractionallySizedBox(heightFactor: .91,
        child: ProductsScreen(app: widget.app, onAdd: (product) {
          addProduct(product);
          Navigator.pop(ctx);
        })));
  }

  Future<void> scan() async {
    if (attempted) return;
    final barcode = await Navigator.push<String>(context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    try {
      final raw = objectOf(await widget.app.api.get(Uri(
        path: '/api/products/lookup-existing',
        queryParameters: {'barcode': barcode.trim()},
      ).toString()));
      final product = raw.containsKey('ulid')
        ? raw : objectOf(raw['data']);
      if (!mounted) return;
      if (field(product['ulid']).length != 26) {
        await showApiError(context, 'No matching product.');
      } else {
        addProduct(product, barcode: barcode.trim());
      }
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> pickCustomer() async {
    if (attempted) return;
    try {
      final response = await widget.app.api.get('/api/parties?type=customer');
      final accounts = recordsOf(response);
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, showDragHandle: true, useSafeArea: true,
        isScrollControlled: true,
        builder: (sheet) => FractionallySizedBox(
          heightFactor: .7,
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(12),
              child: Text('Choose customer')),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Walk-in customer'),
              onTap: () => Navigator.pop(sheet, <String, dynamic>{})),
            Expanded(child: ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (ctx, index) {
                final customer = accounts[index];
                return ListTile(
                  title: Text(field(customer['name'])),
                  subtitle: Text(field(customer['code'])),
                  onTap: () => Navigator.pop(sheet, customer));
              })),
          ]),
        ));
      if (mounted && selected != null) {
        setState(() =>
          selectedCustomer = selected.isEmpty ? null : selected);
      }
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> edit(CartLine line) async {
    if (attempted) return;
    final quantity = TextEditingController(text: line.qty);
    final discount = TextEditingController(text: line.discount);
    try {
      final ok = await showDialog<bool>(context: context,
        builder: (dialog) => AlertDialog(
          title: Text(line.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${line.unitLabel})')),
            const SizedBox(height: 10),
            TextField(controller: discount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Discount %')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final q = quantity.text.trim();
              final d = discount.text.trim();
              final allowDecimals = objectOf(line.product['base_unit'])
                ['allows_decimal'] != false;
              if (!RegExp(r'^\d+(?:\.\d{1,6})?$').hasMatch(q) ||
                !RegExp(r'^\d+(?:\.\d{1,8})?$').hasMatch(d) ||
                (Decimal.tryParse(q) ?? Decimal.zero) <= Decimal.zero ||
                (Decimal.tryParse(d) ?? Decimal.zero) > Decimal.fromInt(100) ||
                (!allowDecimals && q.contains('.'))) {
                ScaffoldMessenger.of(dialog).showSnackBar(const SnackBar(
                  content: Text('Enter a valid quantity and discount.')));
                return;
              }
              Navigator.pop(dialog, true);
            }, child: const Text('Update')),
          ],
        ));
      if (ok == true && mounted) {
        setState(() {
          line.qty = quantity.text.trim();
          line.discount = discount.text.trim();
        });
      }
    } finally {
      quantity.dispose();
      discount.dispose();
    }
  }

  Decimal get estimatedItemsNet {
    var estimate = Decimal.zero;
    for (final line in lines) estimate += line.estimate(priceMode);
    return estimate;
  }

  Future<void> save() async {
    if (saving || (!attempted && lines.isEmpty)) return;
    if (!attempted) {
      if (lines.any((line) => line.priceFor(priceMode) == '0')) {
        await showApiError(context,
          'An item has no price for this pricing mode.');
        return;
      }
      attemptPayload = {
        'price_type': priceMode,
        'items': lines.map((line) => line.payload()).toList(),
        if (selectedCustomer != null)
          'customer_ulid': field(selectedCustomer!['ulid']),
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      };
      attemptKey = AppController.newIdempotencyKey();
      attempted = true;
      try {
        await pendingStore.write(
          userUlid: widget.app.currentUserUlid,
          tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
          branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
          attemptKey: attemptKey!, payload: attemptPayload!,
        );
      } catch (ex) {
        attempted = false;
        attemptKey = null;
        attemptPayload = null;
        if (mounted) await showApiError(context,
          'Unable to securely store the quotation request.');
        return;
      }
    }
    setState(() { saving = true; error = null; });
    try {
      final response = objectOf(await widget.app.api.post(
        '/api/sales/quotations', attemptPayload!,
        idempotencyKey: attemptKey,
      ));
      final quotation = response.containsKey('ulid')
        ? response : objectOf(response['data']);
      if (field(quotation['ulid']).length != 26 ||
          field(quotation['document_number']).isEmpty) {
        throw const ApiFailure('INVALID_QUOTATION_RESPONSE',
          'The server has not confirmed the quotation. Retry safely.', 502);
      }
      await pendingStore.clear();
      if (!mounted) return;
      await showDialog<void>(context: context,
        barrierDismissible: false,
        builder: (dialog) => AlertDialog(
          title: const Text('Quotation saved'),
          content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(field(quotation['document_number'])),
            const SizedBox(height: 8),
            Text('Total: ${money(quotation['grand_total'], widget.app.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          actions: [FilledButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Done'))]));
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      // Validation/auth rejections are definitive; all other failures retain
      // the exact pending request and key for idempotent retry.
      if (ex.status == 422 || ex.status == 403) {
        await pendingStore.clear();
        attempted = false;
        attemptPayload = null;
        attemptKey = null;
      }
      if (mounted) setState(() => error = ex.message);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New Quotation')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeading('Quotation / Estimate'),
        if (attempted)
          Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Unconfirmed quotation request',
              style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('The request is securely saved. Retry using the same idempotency key. Do not create another quotation.'),
          ]))
        else ...[
          SegmentedButton<String>(segments: const [
            ButtonSegment(value: 'default', label: Text('Default')),
            ButtonSegment(value: 'retail', label: Text('Retail')),
            ButtonSegment(value: 'wholesale', label: Text('Wholesale')),
          ], selected: {priceMode},
            onSelectionChanged: (value) =>
              setState(() => priceMode = value.first)),
          const SizedBox(height: 13),
          Surface(child: ListTile(
            leading: Icon(Icons.person_outline_rounded, color: colors.primary),
            title: Text(field(selectedCustomer?['name'], 'Walk-in customer')),
            subtitle: const Text('Tap to choose a customer'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: pickCustomer)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: selectProduct,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add product'))),
            const SizedBox(width: 8),
            IconButton(onPressed: scan,
              icon: Icon(Icons.qr_code_scanner_rounded,
                color: colors.primary), tooltip: 'Scan barcode'),
          ]),
          const SizedBox(height: 11),
          SectionHeading('Items (${lines.length})'),
          if (lines.isEmpty) const EmptyState(
            title: 'No items added',
            subtitle: 'Select or scan a product to start.')
          else ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${line.qty} ${line.unitLabel}'
                      ' · ${money(line.estimate(priceMode), widget.app.currency)}',
                      style: TextStyle(fontSize: 11,
                        color: colors.onSurfaceVariant)),
                  ])),
                IconButton(onPressed: () => edit(line),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit line'),
                IconButton(onPressed: () =>
                    setState(() => lines.remove(line)),
                  icon: Icon(Icons.close_rounded, color: colors.error),
                  tooltip: 'Remove line'),
              ])),
          )),
          const SizedBox(height: 11),
          Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estimated item net: ${money(estimatedItemsNet, widget.app.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('Final quotation amounts, discounts and taxes are calculated by BluePOS server.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          ])),
          const SizedBox(height: 11),
          TextField(controller: notes, maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
        if (error != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(error!, style: TextStyle(color: colors.error))),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: saving || (!attempted && lines.isEmpty) ? null : save,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(saving ? 'Saving…' :
            attempted ? 'Retry saved quotation' : 'Save Quotation')),
        const SizedBox(height: 30),
      ]),
    );
  }
}
